from pathlib import Path
import pandas as pd

RAW_DIR = Path("data_raw")
OUT_DIR = Path("data_clean")
OUT_DIR.mkdir(parents=True, exist_ok=True)

REQUIRED = ["fecha", "referencia", "codigo", "descripcion", "debitos", "creditos"]


def _norm_text(x) -> str:
    s = "" if pd.isna(x) else str(x)
    s = s.strip().replace("\n", " ").replace("\r", " ")
    s = (
        pd.Series([s])
        .str.normalize("NFKD")
        .str.encode("ascii", errors="ignore")
        .str.decode("utf-8")
        .iloc[0]
    )
    s = " ".join(s.split()).lower()
    return s


def _find_header_row(df_raw: pd.DataFrame) -> int:
    """
    Find the row index that contains the table headers.
    We look for a row that has 'fecha' AND something like 'descrip'
    AND also hints of debits/credits/balance.
    """
    df_str = df_raw.copy()

    for i in range(min(len(df_str), 80)):  
        row = [_norm_text(v) for v in df_str.iloc[i].tolist()]
        joined = " | ".join(row)

        has_fecha = "fecha" in joined
        has_desc = "descrip" in joined  
        has_money_cols = ("debit" in joined or "debito" in joined or "debitos" in joined) and (
            "credit" in joined or "credito" in joined or "creditos" in joined
        )

        if has_fecha and has_desc and has_money_cols:
            return i

    preview = df_raw.head(25).to_string(index=False, header=False)
    raise ValueError(
        "No pude detectar la fila de encabezados de la tabla.\n"
        "Preview (primeras 25 filas):\n\n" + preview
    )


def _parse_num(s: pd.Series) -> pd.Series:
    if pd.api.types.is_numeric_dtype(s):
        return s.fillna(0)

    x = (
        s.astype(str)
        .str.strip()
        .str.replace("\u00a0", "", regex=False)  # NBSP
        .str.replace(" ", "", regex=False)       # spaces
    )

    def smart_parse(v: str) -> float:
        if v == "" or v.lower() == "nan":
            return 0.0

        has_comma = "," in v
        has_dot = "." in v

        # Case 1: both separators exist -> rightmost one is decimal
        if has_comma and has_dot:
            last_comma = v.rfind(",")
            last_dot = v.rfind(".")
            if last_comma > last_dot:
                # comma is decimal, dots are thousands
                v2 = v.replace(".", "").replace(",", ".")
            else:
                # dot is decimal, commas are thousands
                v2 = v.replace(",", "")
            return float(v2)

        # Case 2: only comma -> comma is decimal
        if has_comma and not has_dot:
            return float(v.replace(".", "").replace(",", "."))

        # Case 3: only dot -> dot is decimal (do NOT remove it)
        if has_dot and not has_comma:
            return float(v.replace(",", ""))

        # Case 4: no separators
        return float(v)

    return pd.to_numeric(x.map(smart_parse), errors="coerce").fillna(0)


def _standardize_columns(cols) -> list[str]:
    """
    Normalize headers like 'Balance*'/'Balance' and accents.
    Returns canonical lowercase names without accents.
    """
    out = []
    for c in cols:
        c2 = _norm_text(c)
        # unify balance
        if c2 in ("balance", "balance*"):
            c2 = "balance"
        out.append(c2)
    return out


def read_bank_table(fp: Path) -> pd.DataFrame:
    df_raw = pd.read_excel(fp, header=None)

    header_row = _find_header_row(df_raw)

    headers = df_raw.iloc[header_row].tolist()
    headers = _standardize_columns(headers)

    df = df_raw.iloc[header_row + 1 :].copy()
    df.columns = headers
    df = df.dropna(how="all")

    # Keep only expected cols (balance optional)
    # Some exports include extra empty/unnamed columns; we ignore them.
    missing = [c for c in REQUIRED if c not in df.columns]
    if missing:
        raise ValueError(
            f"[{fp.name}] Faltan columnas: {missing}. "
            f"Columnas detectadas: {list(df.columns)}"
        )

    keep = REQUIRED + (["balance"] if "balance" in df.columns else [])
    df = df[keep].copy()

    # Drop 'Saldo Inicial' row
    df["descripcion"] = df["descripcion"].astype(str).str.strip()
    df = df[df["descripcion"].str.lower() != "saldo inicial"]

    # Types
    df["fecha"] = pd.to_datetime(df["fecha"], dayfirst=True, errors="coerce")
    df = df.dropna(subset=["fecha"])

    df["debitos"] = _parse_num(df["debitos"])
    df["creditos"] = _parse_num(df["creditos"])
    if "balance" in df.columns:
        df["balance"] = _parse_num(df["balance"])

    # Add provenance
    df["source_file"] = fp.name

    return df


def main():
    files = sorted(list(RAW_DIR.glob("*.xls")) + list(RAW_DIR.glob("*.xlsx")))
    if not files:
        raise SystemExit("No se encontraron archivos .xls/.xlsx en data_raw/")

    frames = []
    for fp in files:
        frames.append(read_bank_table(fp))

    combined = pd.concat(frames, ignore_index=True)

    out_path = OUT_DIR / "transactions_raw_combined.csv"
    combined.to_csv(out_path, index=False, encoding="utf-8", sep=";")

    print(f"Listo: {out_path} ({len(combined)} filas)")
    print("Columnas:", list(combined.columns))


if __name__ == "__main__":
    main()
