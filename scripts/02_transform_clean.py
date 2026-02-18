from pathlib import Path
import pandas as pd
import re

RAW_PATH = Path("data_clean/transactions_raw_combined.csv")
OUT_PATH = Path("data_clean/transactions_clean.csv")

TRANSFER_RULES_PATH = Path("docs/transfer_identifiers.txt")

ACCOUNT = "main_crc"
CURRENCY = "CRC"
CSV_SEP = ";"


def load_transfer_identifiers(path: Path) -> list[str]:
    if not path.exists():
        return []
    lines = path.read_text(encoding="utf-8").splitlines()
    return [ln.strip() for ln in lines if ln.strip() and not ln.strip().startswith("#")]


def basic_merchant_clean(s: str) -> str:
    s = str(s).upper().strip()
    s = re.sub(r"\s+", " ", s)
    s = s.replace("\\", " ").replace("/", " ").replace("#", " ")
    s = re.sub(r"\b\d{3,}\b", "", s)  # remove long reference numbers
    s = re.sub(r"\s+", " ", s).strip()
    return s


def main():
    if not RAW_PATH.exists():
        raise SystemExit(f"No existe {RAW_PATH}. Corre primero el script de consolidación.")

    df = pd.read_csv(RAW_PATH, encoding="utf-8", sep=CSV_SEP)

    expected = {"fecha", "referencia", "codigo", "descripcion", "debitos", "creditos", "source_file"}
    missing = expected - set(df.columns)
    if missing:
        raise ValueError(f"Faltan columnas en raw_combined: {missing}. Encontradas: {list(df.columns)}")

    # Parse date
    df["fecha"] = pd.to_datetime(df["fecha"], errors="coerce")
    df = df.dropna(subset=["fecha"])
    df["date_iso"] = df["fecha"].dt.strftime("%Y-%m-%d")

    # Numbers
    for col in ["debitos", "creditos"]:
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0)

    # Text
    df["descripcion"] = df["descripcion"].astype(str).str.strip()

    # Signed amount (credit positive, debit negative)
    df["amount"] = df["creditos"] - df["debitos"]

    # Merchant
    df["merchant_raw"] = df["descripcion"]
    df["merchant"] = df["merchant_raw"].apply(basic_merchant_clean)

    # Dedup (date + merchant + amount)
    df = df.drop_duplicates(subset=["date_iso", "merchant", "amount"], keep="first")

    # Base type
    df["type"] = df["amount"].apply(lambda x: "income" if x > 0 else ("expense" if x < 0 else "transfer"))

    # Transfer detection rules (your own account moves)
    identifiers = load_transfer_identifiers(TRANSFER_RULES_PATH)
    if identifiers:
        patt = "|".join([re.escape(x) for x in identifiers])
        mask_transfer = (
            (df["codigo"].astype(str).str.upper().isin(["TF", "TS"]))
            & (df["descripcion"].str.contains(patt, case=False, na=False))
        )
        df.loc[mask_transfer, "type"] = "transfer"

    # Fixed fields
    df["currency"] = CURRENCY
    df["account"] = ACCOUNT

    # Stable transaction_id
    df["transaction_id"] = (
        df["date_iso"].str.replace("-", "")
        + "_"
        + df["referencia"].astype(str).str.strip()
        + "_"
        + df["amount"].round(2).astype(str)
        + "_"
        + df["source_file"].astype(str)
    )

    out = df.rename(
        columns={
            "date_iso": "date",
            "descripcion": "description",
            "referencia": "reference",
            "codigo": "code",
        }
    )[
        [
            "transaction_id",
            "date",
            "description",
            "merchant_raw",
            "merchant",
            "amount",
            "type",
            "currency",
            "account",
            "reference",
            "code",
            "source_file",
        ]
    ].copy()

    out = out.sort_values(["date", "transaction_id"]).reset_index(drop=True)
    out.to_csv(OUT_PATH, index=False, encoding="utf-8", sep=CSV_SEP)

    print(f"Listo: {OUT_PATH} ({len(out)} filas)")
    print("Type counts:\n", out["type"].value_counts())


if __name__ == "__main__":
    main()
