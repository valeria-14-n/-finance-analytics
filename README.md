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

##  Advanced Analytics & Insights

The following insights were derived using a combination of **DAX statistical modeling** and **exploratory data analysis**:

### 1. Merchant Concentration (Pareto Principle)
* **Insight:** The top 5 merchants (e.g., E-Ticket, Sinpe, Servicentr) represent **26% of total burn**. 
* **Business Action:** Applied the 80/20 rule to demonstrate that financial optimization starts with high-leverage vendor management rather than micro-transaction tracking.

### 2. Variance & Volatility Analysis (Scatter Plot)
* **Insight:** Categories like *Entertainment* and *Other* show moderate total spend but **extremely high variability** (2nd Sigma outliers).
* **Business Action:** Implemented a "Volatility Buffer" in the budget model to account for unpredictable spikes, ensuring the Run Rate projections remain stable despite non-recurring events.

### 3. Temporal Spending Patterns
* **Insight:** Approximately **40% of total expenditure** is concentrated between Friday and Sunday.
* **Business Action:** Developed a "Weekend Leakage" detection logic to trigger proactive alerts, shifting the focus from reactive reporting to predictive budget management.

### 4. Data Health & Integrity Monitoring
* **Insight:** Achieved a **100% Data Health Score** with zero unmapped transactions across 3 different bank source formats.
* **Business Action:** Built a dedicated Data Quality page to monitor Null percentages and mapping consistency, reflecting a "Data Integrity First" mindset essential for enterprise-scale environments.

---

--- ##  Data Modeling Standards

* **Star Schema Architecture:** Separated facts (transactions) from dimensions (merchants, categories, calendar, payment methods) to ensure model scalability.
* **Advanced DAX:** Developed complex measures including:
    * `Burn Target %`: Dynamic gauging of budget consumption.
    * `3-Month Rolling Average`: To smooth out seasonal spending trends.
    * `Outlier Flagging`: Using Standard Deviation ($2\sigma$) logic to isolate anomalous records.

## How to Run

1.  Run the Python scripts in `/scripts` to clean and categorize the raw bank files.
2.  Initialize the MySQL warehouse using `sql/01_create_tables.sql`.
3.  Execute the load procedure and run the `core_metrics` scripts.
4.  Open the `.pbix` file in Power BI Desktop and refresh the data source to your Localhost.

---

## About

Built by **Valeria** as a comprehensive data engineering and analytics project. The goal was to solve the "messy data" problem and apply professional rigor—reproducible ETL, star schema modeling, and actionable KPI alerts.

[github.com/valeria-14-n](https://github.com/valeria-14-n)
