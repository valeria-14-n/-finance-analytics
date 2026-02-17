# Finance Analytics Project Log
Project: Personal Finance Ops
Owner: Valeria Barboza
Start Date: 2026-02-16
Status: In Progress

---

## 2026-02-16 — Project Initialization

### Objective
Build a structured financial analytics system using personal bank statements to answer business-style questions about income, expenses, and cash flow trends.

### Scope (Phase 1)
- Use last 3 months of bank statements
- Work with 1 primary account
- Standardize transaction structure
- Build clean dataset
- Prepare for SQL analysis

### Decisions Made
- Raw data will NOT be uploaded to GitHub
- All raw files stored locally under `/data_raw/`
- Project will follow multi-phase evolution:
    - v1: Single account
    - v2: Multi-account
    - v3: Multi-currency

### Data Sources
- Bank statements exported in Excel (.xls)
- Months: November 2025, December 2025, January 2026

### Identified Data Structure
Columns observed in statements:
- Reference Number
- Date (format: NOV/05 style)
- Concept / Description
- Debits
- Credits

### Risks Identified
- Date format lacks year
- Multi-currency accounts (USD and CRC)
- Transfers between own accounts
- Text-based categorization required

### Next Step
- Select primary account for v1
- Inspect column consistency across 3 months
- Design target clean table schema
