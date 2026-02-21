import pandas as pd
import numpy as np


## Fixing balance discrepancies by calculating amount from balance differences.

df = pd.read_csv("data_clean/transactions_raw_combined.csv", sep=";")

# Convertir a número
for col in ["debitos", "creditos", "balance"]:
    df[col] = pd.to_numeric(df[col], errors="coerce")

# Crear índice por archivo que preserve el orden original
df["row_in_file"] = df.groupby("source_file").cumcount()

# Ordenar SOLO por ese índice dentro de cada archivo
df = df.sort_values(["source_file", "row_in_file"])

# Ahora sí calcular delta
df["prev_balance"] = df.groupby("source_file")["balance"].shift(1)
df["amount_signed"] = df["balance"] - df["prev_balance"]
df["amount"] = df["amount_signed"]


pd.set_option("display.max_columns", None)
pd.set_option("display.width", 200)
pd.set_option("display.max_colwidth", 80)

df["abs_amt"] = df["amount"].abs()

top = df.sort_values("abs_amt", ascending=False).head(15)[
    ["fecha", "descripcion", "amount", "balance", "prev_balance", "source_file"]
]
print(top.to_string(index=False))

print(df[["fecha","debitos","creditos","balance"]].head(10))