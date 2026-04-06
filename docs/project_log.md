# Finance Analytics — Project Log

**Project:** Personal Finance Ops  
**Owner:** Valeria Barboza  
**Start Date:** 2026-02-16  
**Current Phase:** Phase 3 — SQL Pipeline Stabilization  
**Status:** In Progress  

---

#  PHASE 1 — Foundation & Data Understanding  
**Status:**  Completed  

## Objective
Transform raw bank Excel statements into a structured, analyzable dataset.

## Scope
- Last 3 months (Nov 2025 – Jan 2026)
- 1 primary account
- Standardized transaction structure
- Clean dataset ready for SQL ingestion

## Decisions
- Raw files NOT uploaded to GitHub
- Raw data stored locally in `/data_raw/`
- Multi-phase roadmap:
  - v1 → Single account
  - v2 → Multi-account
  - v3 → Multi-currency

## Data Structure Identified
Columns in raw statements:
- Reference Number
- Date (format: NOV/05 style)
- Concept / Description
- Debits
- Credits
- Balance

## Risks Identified
- Date field lacks year
- Multi-currency accounts (CRC + USD)
- Internal transfers between own accounts
- Text-based categorization required
- Locale numeric format (comma vs dot)

## Deliverable
`/data_clean/transactions_raw_combined.csv`

---

#  PHASE 2 — Cleaning & Categorization (Python ETL)  
**Status:**  Completed  

## Objective
Normalize and categorize transactions for SQL modeling.

## Pipeline

XLS → combine → clean → categorize → export clean CSV

## Output Files

### `/data_clean/transactions_raw_combined.csv`
    fecha;referencia;codigo;descripcion;debitos;creditos;balance;source_file
### `/data_clean/transactions_clean.csv`
    transaction_id;date;description;merchant_raw;merchant;amount;type;currency;account;reference;code;source_file
### `/data_clean/transactions_categorized.csv`
    transaction_id;date;description;merchant_raw;merchant;amount;type;currency;account;reference;code;source_file;category

## Major Bug Encountered
Inflated transaction values after SQL ingestion.

### Root Cause
- Incorrect amount derivation from balance
- Mixed numeric locale parsing (comma vs dot)
- Sign inference error

### Fix Implemented
- Created `etl_02_amount_from_balance.py`
- Adjusted parsing logic in `etl_combine_xls.py`
- Revalidated numeric consistency
- Confirmed SQL model integrity

## Lessons Learned
- Always validate numeric parsing before aggregation
- Balance-based calculations require strict locale control
- Bugs can originate in ETL even if SQL model is correct

---

# 📌 PHASE 3 — SQL Modeling & Data Warehouse  
**Status:** 🚧 In Progress  

## Objective
Implement star schema and enforce relational integrity.

## Architecture Overview

    CSV
    → stg_transactions_raw
    → vw_stg_typed
    → dimension tables
    → fact_transactions


---

## Staging Layer

### `stg_transactions_raw`
Raw CSV import.

### `vw_stg_typed`
Trimmed, casted, type-safe view.

---

## Fact Table — `transactions`

- transaction_id (PK)
- date_key (FK)
- category_id (FK)
- merchant_id (FK)
- payment_method_id (FK)
- amount
- type (income / expense / transfer)
- currency
- account
- source_file
- created_at

---

## Dimension Tables

- `dim_category`
- `dim_merchant`
- `dim_payment_method`
- `dim_date`

---

## Current Technical Challenges

- Foreign key conflicts
- Unique index constraints
- Data trimming inconsistencies
- Referential integrity validation

---

## Pending Work

### 1-Data Quality Checks
- % nulls per column
- Merchants without assigned category
- Outlier detection (extreme amounts by category)

### 2- Core Metrics
- Monthly spend + MoM variation
- Top spending categories
- Run rate projection (gasto acumulado / días transcurridos)

---

#  CURRENT STATUS (2026-02-23)

- ETL stabilized
- Numeric parsing fixed
- SQL schema functional
- Preparing for analytics layer

---

# 🔜 NEXT STEP

Choose:

- A) Fully harden SQL constraints and validations  
- B) Move into analytics queries (Step D)


