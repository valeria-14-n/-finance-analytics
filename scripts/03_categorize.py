from pathlib import Path
import pandas as pd

IN_PATH = Path("data_clean/transactions_clean.csv")
RULES_PATH = Path("docs/category_rules.csv")
OUT_PATH = Path("data_clean/transactions_categorized.csv")

CSV_SEP = ";"  


def main():
    if not IN_PATH.exists():
        raise SystemExit(f"No existe {IN_PATH}. Corre 02_transform_clean.py primero.")
    if not RULES_PATH.exists():
        raise SystemExit(f"No existe {RULES_PATH}. Crea docs/mappings/category_rules.csv")

    df = pd.read_csv(IN_PATH, encoding="utf-8", sep=CSV_SEP)
    
    # If you opened it in Excel CR, it might have become ';'.
    # We'll auto-detect using python engine + sep=None.
    rules = pd.read_csv(RULES_PATH, encoding="utf-8", sep=None, engine="python")

    required = {"priority", "pattern", "category"}
    missing = required - set(rules.columns)
    if missing:
        raise ValueError(f"category_rules.csv le faltan columnas: {missing}. Tiene: {list(rules.columns)}")

    rules = rules.copy()
    rules["priority"] = pd.to_numeric(rules["priority"], errors="coerce").fillna(999).astype(int)
    rules["pattern"] = rules["pattern"].astype(str)
    rules["category"] = rules["category"].astype(str)

    rules = rules.sort_values(["priority"]).reset_index(drop=True)

    # Apply rule engine: first match wins
    df["category"] = pd.NA

    haystack = (df["merchant_raw"].fillna("") + " " + df["merchant"].fillna("")).astype(str)

    for _, r in rules.iterrows():
        patt = r["pattern"]
        cat = r["category"]
        mask = haystack.str.contains(patt, case=False, na=False, regex=True)
        df.loc[mask & df["category"].isna(), "category"] = cat

    # fallback (in case rule 999 missing)
    df["category"] = df["category"].fillna("Other")
    
    # --- Safety alignment between type and category ---
    df.loc[df["type"].eq("transfer"), "category"] = "Transfers"
    df.loc[df["category"].str.lower().eq("transfers"), "type"] = "transfer"

    # Keep consistency: transfers category -> type transfer (optional but recommended)
    df.loc[df["category"].str.upper().eq("TRANSFERS"), "type"] = "transfer"
    # Force alignment: if it's a transfer movement, category should be Transfers
    df.loc[df["type"].eq("transfer"), "category"] = "Transfers"
    df.loc[df["category"].str.lower().eq("transfers"), "type"] = "transfer"

    df.to_csv(OUT_PATH, index=False, encoding="utf-8", sep=CSV_SEP)

    print(f"Listo: {OUT_PATH} ({len(df)} filas)")
    print("Category counts:\n", df["category"].value_counts())
    print("Type counts:\n", df["type"].value_counts())
    print("\nTop OTHER merchants:\n",
        df[df["category"] == "Other"]["merchant"]
        .value_counts()
        .head(20))


if __name__ == "__main__":
    main()

