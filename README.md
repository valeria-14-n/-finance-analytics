#  Finance Ops Analytics

> Turning 3 months of personal bank data into a production-grade analytics pipeline.

---

##  Overview

Most people check their bank app once a month and move on. This project treats **personal finances as an operational dataset**. I built a full data model, SQL warehouse, and Power BI dashboard to answer real-world financial questions:

- **Where is the money actually going?** (Pareto 80/20 Analysis)
- **How much does my spending fluctuate?** (Volatility & Variance)
- **Which merchants are eating up my budget?** (Concentration)
- **Am I on track or overspending?** (Run Rate Projection)

**Stack:** Python (ETL) · MySQL (Warehouse) · Power BI (Viz)  
**Data:** 3 months of bank exports (Nov 2025 – Jan 2026) · 210 transactions · ₡CRC

---

##  Project Structure

```text
finance-analytics/
│
├── scripts/
│   ├── 01_etl_combine_xls.py       # Merging monthly bank .xls exports
│   ├── 02_transform_clean.py       # Cleaning dates, amounts, and signs
│   └── 03_categorize.py            # Rule-based category assignment
│
├── sql/
│   ├── 01_create_tables.sql        # Star Schema (Fact + 4 Dimensions)
│   ├── 02_load.sql                 # ETL from Staging to Final tables
│   └── 04_core_metrics.sql         # MoM change, averages, and variance
│
├── powerbi/
│   ├── Finance_Ops_Dashboard.pbix  # The final report
│   └── dax_measures.txt            # Backup of DAX formulas
└── README.md


##  Power BI Implementation

This is where the data actually starts telling a story. I didn't just make "pretty charts"; I structured the report for actual financial auditing.

### Data Modeling & DAX
* **Measure Organization:** To keep the model scalable, I used **Display Folders** to group the 80+ measures into logical buckets: `01 | Spend Analysis`, `02 | Budget & Burn`, and `03 | Merchant Concentration`.
* **Key DAX Logic:**
    * `Top 5 Concentration %`: Dynamically calculates the weight of the top 5 vendors against total spend using `TOPN` and `ALLSELECTED`.
    * `Cumulative % Spend`: A running total calculation to drive the Pareto curve.
    * `Expense Variability`: Standard deviation logic to separate fixed costs from volatile spending.

### Visual Insights
* **Spending Dynamics:** A Scatter Chart crossing *Average Spend vs Volatility*. It helps identify if a category is a constant "small leak" or a giant one-off spike.
* **Merchant Analytics:** A Pareto chart to find the "fat" in the budget. I used *Conditional Columns* in Power Query to normalize messy bank descriptions (e.g., cleaning `AUTO MERCADO 1234` into a clean `Auto Mercado` label).
* **Burn Tracking:** Real-time comparison of actual spend vs. monthly budget targets.

---

##  SQL Analytics Highlights

### Data Quality & Outliers
Before visualizing anything, I ran SQL scripts to ensure the data was trustworthy:
* **3-Sigma Rule:** Identified transactions that were statistical outliers within their specific category to avoid skewed averages.
* **Schema Integrity:** Enforced a **Star Schema** to ensure high performance when filtering by Date, Category, or Merchant in Power BI.

### Core Metrics
* **Run Rate:** Calculated the pace of spending to project the year-end total (`Projected Annual Run Rate`).
* **MoM Change:** Compared growth or shrinkage in spending month-over-month using window functions (`LAG`).

---

##  Key Insights

* **Merchant Concentration:** The top 5 merchants represent **26% of my total spend**. Cost optimization should start here rather than on low-impact "micro-expenses."
* **One-offs vs. Recurring:** High-spend merchants like `E-TICKET` showed only **1 transaction**, while `SINPE` showed **19**. This clearly separates "event-based" spending from "lifestyle" recurring costs.
* **Temporal Patterns:** Nearly **40% of all spending** happens on Saturday and Sunday, highlighting where most discretionary spending occurs.

---

##  How to Run

1.  Run the Python scripts in `/scripts` to clean and categorize the raw bank files.
2.  Create the database and tables using `sql/01_create_tables.sql`.
3.  Load the cleaned CSV into MySQL using the `sql/02_load.sql` procedure.
4.  Open the `.pbix` file in Power BI Desktop and refresh the data source to your Localhost.

---

## About

Built by **Valeria** as an end-to-end data analytics project. The goal was to move beyond basic budgeting and apply professional analyst rigor: data modeling, reproducible ETL pipelines, and advanced DAX.

📬 [github.com/valeria-14-n](https://github.com/valeria-14-n)
