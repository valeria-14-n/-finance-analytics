import re
from pathlib import Path
import pandas as pd

IN_PATH = Path("data_clean/transactions_clean.csv")
OUT_PATH = Path("data_clean/transactions_categorized.csv")
RULES_PATH = Path("docs/category_rules.csv")
SEP_IN = ";"


def load_rules(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise SystemExit(f"No existe {path}. Crea docs/category_rules.csv primero.")

    rules = pd.read_csv(path, encoding="utf-8")
    required = {"priority", "pattern", "category"}
    missing = required - set(rules.columns)
    if missing:
        raise ValueError(f"Faltan columnas en category_rules.csv: {missing}")

    rules["priority"] = pd.to_numeric(rules["priority"], errors="coerce")
    rules = rules.dropna(subset=["priority", "pattern", "category"])
    rules = rules.sort_values("priority").reset_index(drop=True)
    return rules


def categorize_description(desc: str, rules: pd.DataFrame) -> str:
    d = "" if pd.isna(desc) else str(desc).strip().lower()
    for _, row in rules.iterrows():
        pattern = str(row["pattern"])
        if re.search(pattern, d, flags=re.IGNORECASE):
            return str(row["category"])
    return "Other"


def main():
    if not IN_PATH.exists():
        raise SystemExit(f"No existe {IN_PATH}. Corre 02_transform_clean.py primero.")

    df = pd.read_csv(IN_PATH, sep=SEP_IN, encoding="utf-8")

    rules = load_rules(RULES_PATH)

    df["category"] = None
    df.loc[df["type"] == "transfer", "category"] = "Transfers"


    mask = df["category"].isna()
    df.loc[mask, "category"] = df.loc[mask, "description"].apply(
        lambda x: categorize_description(x, rules)
    )

    df["merchant"] = df["description"].astype(str).str.strip().str.split().str[0].str.upper()
    
    cols = list(df.columns)
    preferred = [
        "transaction_id", "date", "description", "merchant",
        "amount", "type", "category",
        "currency", "account", "reference", "code", "source_file"
    ]
    final_cols = [c for c in preferred if c in cols] + [c for c in cols if c not in preferred]
    df = df[final_cols]
    df["category"] = df["category"].astype(str).str.strip()

    df.to_csv(OUT_PATH, index=False, encoding="utf-8", sep=";")

    print(f" Listo: {OUT_PATH} ({len(df)} filas)")
    print("Top categories:\n", df["category"].value_counts().head(10))
    print("\nTop OTHER descriptions:\n")
    print(
    df[df["category"] == "Other"]["description"]
    .value_counts()
    .head(20)
)


if __name__ == "__main__":
    main()


