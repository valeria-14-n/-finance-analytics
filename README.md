# 💸 Finance Ops Analytics

> Turning 3 months of personal bank data into a production-grade analytics pipeline — built the way a company would.

---

## 📌 Overview

Most people look at their bank statement once a month and forget about it. This project treats **personal finances as an operational dataset** — with proper data modeling, SQL analytics, and a Power BI dashboard built to answer real business questions:

- Where is the money actually going?
- What changed vs. last month?
- Which categories are out of control?
- What will I spend by end of month?

**Stack:** Python · MySQL · Power BI  
**Data:** 3 months of personal bank exports (Nov 2025 – Jan 2026) · 210 transactions · ₡CRC

---

## 🗂️ Project Structure

```
finance-analytics/
│
├── data_raw/               # Original bank exports (.xls) — not committed
├── data_clean/             # Processed CSVs ready for loading
│
├── scripts/
│   ├── 01_etl_combine_xls.py       # Merge monthly exports into one file
│   ├── 02_transform_clean.py       # Normalize dates, amounts, merchants
│   ├── 03_categorize.py            # Rule-based category assignment
│   └── etl_02_amount_from_balance.py
│
├── sql/
│   ├── 01_create_tables.sql        # Star schema: transactions + 4 dimensions
│   ├── 02_load.sql                 # ETL: staging → dimensions → fact table
│   ├── 03_data_quality.sql         # Null checks, outliers, 3-sigma flagging
│   ├── 04_core_metrics.sql         # MoM change, run rate, percentiles
│   ├── 05_segmentation.sql         # By payment method, day of week, merchant
│   └── 06_alerts.sql               # 2σ alerts, budget burn (in progress)
│
├── docs/
│   ├── category_rules.csv          # Merchant → category mapping
│   ├── transfer_identifiers.txt    # Rules to detect transfers vs. expenses
│   └── project_log.md              # Decision log
│
├── powerbi/                        # Dashboard (.pbix) — coming soon
└── README.md
```

---

## 🧱 Data Model

Star schema designed for Power BI compatibility:

```
                    ┌─────────────────┐
                    │   dim_date      │
                    │  date_id (PK)   │
                    │  full_date      │
                    │  day_name       │
                    │  is_weekend     │
                    └────────┬────────┘
                             │
┌──────────────┐    ┌────────▼────────────┐    ┌──────────────────────┐
│ dim_category │    │    transactions      │    │   dim_merchant       │
│ category_id  │◄───│  transaction_id (PK) │───►│   merchant_id        │
│ category_name│    │  transaction_date    │    │   merchant_name      │
│ category_group    │  amount              │    │   merchant_norm      │
└──────────────┘    │  type (inc/exp/trf)  │    └──────────────────────┘
                    │  category_id (FK)    │
                    │  merchant_id (FK)    │    ┌──────────────────────┐
                    │  payment_method_id──►│───►│ dim_payment_method   │
                    │  source_row_hash     │    │  payment_method_id   │
                    └─────────────────────┘    │  payment_method_name │
                                               └──────────────────────┘
```

**Key design decisions:**
- `source_row_hash` (SHA-256) prevents duplicate loads across monthly files
- `merchant_norm` normalizes raw bank descriptions for consistent grouping
- `dim_date` pre-calculates `is_weekend`, `quarter`, `week_of_year` for Power BI performance
- Transfers excluded from expense analysis via `type` filter

---

## 🔬 SQL Analytics

### Data Quality (`03_data_quality.sql`)
- % of nulls per key column
- Top merchants missing category assignment
- Outlier detection using **3-sigma rule** per category
- Variability analysis (avg, stddev, max) by category

### Core Metrics (`04_core_metrics.sql`)
- Monthly spend + **MoM % change** using `LAG()`
- Top categories by total spend
- **Run rate**: daily spend pace → projected month-end total
- **Percentiles** (p50, p75, p90) per category using `PERCENT_RANK()`

### Segmentation (`05_segmentation.sql`)
- Spend by payment method with % of total (`SUM() OVER()`)
- Spend by day of week with weekend flag
- **Pareto analysis**: top merchants with cumulative % (`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`)

### Alerts (`06_alerts.sql`) — in progress
- Categories exceeding historical average + 2σ
- Budget burn rate per category

---

## 📊 Key Insights

From 3 months of data (Nov 2025 – Jan 2026), 210 transactions, ₡963,214 CRC in total expenses:

**💳 Payment method**
90.8% of spend goes through card (`Tarjeta`). The remaining ~9% via bank transfers and SINPE could be underrepresented if not all accounts are included.

**📅 Day of week**
Saturday + Sunday account for **39.7% of total spend** in just 2 of 7 days. Thursday has the highest average ticket (₡11,386), driven by large one-off purchases.

**🏪 Merchant concentration**
The top 20 merchants represent **60% of total spend**. Three single-transaction merchants — E-TICKET E-COMMERCE (₡91,200), Vertigo Lincoln Plaza (₡44,500), and NOVA EC (₡27,400) — alone account for **17% of total spend**, showing how one-time events distort monthly averages.

**🛒 Recurring vs. sporadic**
Super Mega Más y Más appears 11 times but ranks 6th in total spend — controlled recurring grocery spend. Librería Internacional ranks 2nd with only 4 transactions — high-value but infrequent.

---

## ⚙️ How to Run

**1. Set up the database**
```sql
-- Run in order:
mysql -u root -p < sql/01_create_tables.sql
```

**2. Process raw data**
```bash
python scripts/01_etl_combine_xls.py
python scripts/02_transform_clean.py
python scripts/03_categorize.py
```

**3. Load into MySQL**
```sql
-- Import data_clean/transactions_categorized.csv into stg_transactions_raw
-- Then run:
mysql -u root -p finance_ops < sql/02_load.sql
```

**4. Run analytics**
```sql
mysql -u root -p finance_ops < sql/03_data_quality.sql
mysql -u root -p finance_ops < sql/04_core_metrics.sql
mysql -u root -p finance_ops < sql/05_segmentation.sql
```

---

## 🚧 In Progress

- [ ] `06_alerts.sql` — 2σ category alerts + budget burn
- [ ] Power BI dashboard (5 pages: Overview, Categories, Merchants, Calendar, Data Quality)
- [ ] February 2026 data load
- [ ] README: add dashboard screenshots

---

## 👩‍💻 About

Built by **Valeria** as a first end-to-end data analytics project.  
The goal: apply the same rigor used in business analytics to personal finance data — proper modeling, reproducible ETL, and insights that actually drive decisions.

📬 [github.com/valeria-14-n](https://github.com/valeria-14-n)