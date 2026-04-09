# 💸 Finance Ops Analytics

> Turning 3 months of personal bank data into a production-grade analytics pipeline.
---

## 📌 Overview

Most people check their bank app once a month and move on. This project treats **personal finances as an operational dataset**. I handled the entire lifecycle: from **cleaning raw, messy bank exports from scratch** to building a SQL warehouse and a Power BI dashboard.

I designed the system to be **format-agnostic**, ensuring compatibility across different bank sources and file structures, while implementing advanced segmentation to answer:

- **Where is the money actually going?** (Pareto 80/20 Analysis)
- **What are my core metrics?** (MoM Change, Burn Rate, Run Rate)
- **When should I be alerted?** (2nd Sigma outlier detection)

**Stack:** Python (ETL) · MySQL (Warehouse) · Power BI (Viz)  
**Data:** 3 months of bank exports (Nov 2025 – Jan 2026) · 210 transactions · ₡CRC

---

## 🗂️ Project Structure

```text
finance-analytics/
│
├── scripts/
│   ├── 01_etl_combine_xls.py       # Merging and normalizing multi-source exports
│   ├── 02_transform_clean.py       # From-scratch cleaning (dates, signs, amounts)
│   └── 03_categorize.py            # Custom rule-based categorization engine
│
├── sql/
│   ├── 01_create_tables.sql        # Star Schema (Fact + 4 Dimensions)
│   ├── 04_core_metrics.sql         # KPIs: MoM change, averages, and percentiles
│   └── 06_alerts.sql               # Budget burn & volatility alerts
│
├── powerbi/
│   └── Finance_Ops_Dashboard.pbix  # The final production report
└── README.md


## Data Engineering & Power BI

I built this pipeline to handle data variability. Since bank exports often change formats, the Python ETL acts as a normalization layer before the SQL load.

### Data Processing & Segmentation
* **Raw to Refined:** Handled messy strings, inconsistent date formats, and sign-reversal logic (expenses vs. income) to create a clean, unified dataset.
* **Automated Categorization:** Built a logic-based engine to segment 200+ merchants into consistent business categories, reducing manual tagging to 0%.

### Data Modeling & DAX
* **Measure Organization:** Scalable model using **Display Folders** for 80+ measures: `01 | Spend Analysis`, `02 | Budget & Burn`, and `03 | Merchant Concentration`.
* **Core Metrics & Alerts:**
    * `Burn Target & Alerts`: Visual indicators for when a category exceeds its 2nd Sigma historical average.
    * `Top 5 Concentration %`: Dynamic calculation of vendor weight using `TOPN`.
    * `Expense Variability`: Standard deviation logic to identify unpredictable spending patterns.

---

## SQL Analytics Highlights

### Data Quality & Outliers
Before visualizing, I ran SQL-based audits to ensure data integrity:
* **3-Sigma Rule:** Automated detection of outliers to prevent skewed averages in the final report.
* **Format Compatibility:** Developed a staging layer in MySQL to allow seamless imports from different bank sources without breaking the Star Schema.
* **Core KPIs:** Used Window Functions (`LAG`, `OVER`) to calculate Month-over-Month growth and cumulative spending.

---

## Key Insights

* **Merchant Concentration:** The top 5 merchants represent 26% of my total spend. Highlighting that cost optimization starts with big vendors, not micro-transactions.
* **Segmentation Reality:** Separated "Event-based" spend (e.g., `E-TICKET` with 1 transaction) from "Lifestyle" spend (e.g., `SINPE` with 19 transactions).
* **Temporal Patterns:** Identified that nearly 40% of total spend is concentrated on weekends, triggering a need for better Friday-Sunday budget alerts.

---

## How to Run

1.  Run the Python scripts in `/scripts` to clean and categorize the raw bank files.
2.  Initialize the MySQL warehouse using `sql/01_create_tables.sql`.
3.  Execute the load procedure and run the `core_metrics` scripts.
4.  Open the `.pbix` file in Power BI Desktop and refresh the data source to your Localhost.

---

## About

Built by **Valeria** as a comprehensive data engineering and analytics project. The goal was to solve the "messy data" problem and apply professional rigor—reproducible ETL, star schema modeling, and actionable KPI alerts.

[github.com/valeria-14-n](https://github.com/valeria-14-n)
