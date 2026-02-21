-- D2.1 Monthly spend + MoM change
WITH monthly AS (
  SELECT
    DATE_FORMAT(transaction_date, '%Y-%m-01') AS month_start,
    ROUND(SUM(ABS(amount)), 2) AS spend
  FROM transactions
  WHERE type = 'expense'
  GROUP BY DATE_FORMAT(transaction_date, '%Y-%m-01')
)
SELECT
  month_start,
  spend,
  LAG(spend) OVER (ORDER BY month_start) AS prev_month_spend,
  ROUND(spend - LAG(spend) OVER (ORDER BY month_start), 2) AS mom_abs_change,
  ROUND(
    100 * (spend - LAG(spend) OVER (ORDER BY month_start))
    / NULLIF(LAG(spend) OVER (ORDER BY month_start), 0),
  2) AS mom_pct_change
FROM monthly
ORDER BY month_start;


-- D2.2 Top categories by total spend
SELECT
  c.category_name,
  COUNT(*) AS tx_count,
  ROUND(SUM(ABS(t.amount)), 2) AS total_spend
FROM transactions t
JOIN dim_category c ON c.category_id = t.category_id
WHERE t.type = 'expense'
GROUP BY c.category_name
ORDER BY total_spend DESC
LIMIT 10;

-- D2.3 Run rate for the latest month in the dataset
WITH bounds AS (
  SELECT
    DATE_FORMAT(MAX(transaction_date), '%Y-%m-01') AS month_start,
    LAST_DAY(MAX(transaction_date)) AS month_end,
    MAX(transaction_date) AS last_tx_date
  FROM transactions
),
mtd AS (
  SELECT
    b.month_start,
    b.month_end,
    b.last_tx_date,
    DATEDIFF(b.last_tx_date, b.month_start) + 1 AS days_elapsed,
    DAY(b.month_end) AS days_in_month,
    ROUND(SUM(ABS(t.amount)), 2) AS spend_mtd
  FROM bounds b
  JOIN transactions t
    ON t.transaction_date >= b.month_start
   AND t.transaction_date <= b.last_tx_date
   AND t.type = 'expense'
  GROUP BY b.month_start, b.month_end, b.last_tx_date
)
SELECT
  month_start,
  last_tx_date,
  days_elapsed,
  days_in_month,
  spend_mtd,
  ROUND(spend_mtd / NULLIF(days_elapsed, 0), 2) AS spend_per_day,
  ROUND((spend_mtd / NULLIF(days_elapsed, 0)) * days_in_month, 2) AS projected_month_spend
FROM mtd;


-- Audit: biggest January expenses 
SELECT
  t.transaction_date,
  c.category_name,
  m.merchant_name,
  t.amount,
  t.notes,
  t.source_file
FROM transactions t
LEFT JOIN dim_category c ON c.category_id = t.category_id
LEFT JOIN dim_merchant m ON m.merchant_id = t.merchant_id
WHERE t.type = 'expense'
  AND t.transaction_date >= '2026-01-01'
  AND t.transaction_date <  '2026-02-01'
ORDER BY ABS(t.amount) DESC
LIMIT 30;

-- Check suspicious expenses: very large amounts
SELECT
  t.transaction_date,
  c.category_name,
  m.merchant_name,
  t.amount,
  t.notes
FROM transactions t
LEFT JOIN dim_category c ON c.category_id = t.category_id
LEFT JOIN dim_merchant m ON m.merchant_id = t.merchant_id
WHERE t.type = 'expense'
ORDER BY ABS(t.amount) DESC
LIMIT 20;