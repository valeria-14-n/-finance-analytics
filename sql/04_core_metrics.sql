-- ============================================================
-- 04_core_metrics.sql · Métricas principales
-- ============================================================

USE finance_ops;

-- D2.1 Gasto mensual + variación MoM
WITH monthly AS (
  SELECT
    DATE_FORMAT(transaction_date, '%Y-%m-01')  AS month_start,
    ROUND(SUM(ABS(amount)), 2)                 AS spend
  FROM transactions
  WHERE type = 'expense'
  GROUP BY DATE_FORMAT(transaction_date, '%Y-%m-01')
)
SELECT
  month_start,
  spend,
  LAG(spend) OVER (ORDER BY month_start)      AS prev_month_spend,
  ROUND(spend - LAG(spend) OVER (ORDER BY month_start), 2) AS mom_abs_change,
  ROUND(
    100 * (spend - LAG(spend) OVER (ORDER BY month_start))
    / NULLIF(LAG(spend) OVER (ORDER BY month_start), 0)
  , 2)                                         AS mom_pct_change
FROM monthly
ORDER BY month_start;

-- D2.2 Top categorías por gasto total
SELECT
  c.category_name,
  COUNT(*)                            AS tx_count,
  ROUND(SUM(ABS(t.amount)), 2)        AS total_spend
FROM transactions t
JOIN dim_category c ON c.category_id = t.category_id
WHERE t.type = 'expense'
GROUP BY c.category_name
ORDER BY total_spend DESC
LIMIT 10;

-- D2.3 Run rate: proyección de gasto al fin del mes actual
WITH bounds AS (
  SELECT
    DATE_FORMAT(MAX(transaction_date), '%Y-%m-01')  AS month_start,
    LAST_DAY(MAX(transaction_date))                 AS month_end,
    MAX(transaction_date)                           AS last_tx_date
  FROM transactions
),
mtd AS (
  SELECT
    b.month_start,
    b.month_end,
    b.last_tx_date,
    DATEDIFF(b.last_tx_date, b.month_start) + 1    AS days_elapsed,
    DAY(b.month_end)                               AS days_in_month,
    ROUND(SUM(ABS(t.amount)), 2)                   AS spend_mtd
  FROM bounds b
  JOIN transactions t
    ON t.transaction_date BETWEEN b.month_start AND b.last_tx_date
   AND t.type = 'expense'
  GROUP BY b.month_start, b.month_end, b.last_tx_date
)
SELECT
  month_start,
  last_tx_date,
  days_elapsed,
  days_in_month,
  spend_mtd,
  ROUND(spend_mtd / NULLIF(days_elapsed, 0), 2)                    AS spend_per_day,
  ROUND((spend_mtd / NULLIF(days_elapsed, 0)) * days_in_month, 2)  AS projected_month_spend
FROM mtd;

-- D2.4 Percentiles por categoría (p50, p75, p90)
SELECT
  c.category_name,
  COUNT(*)                                                AS n,
  ROUND(AVG(ABS(t.amount)), 2)                            AS avg_spend,
  ROUND(MAX(CASE WHEN pct <= 0.50 THEN ABS(t.amount) END), 2) AS p50,
  ROUND(MAX(CASE WHEN pct <= 0.75 THEN ABS(t.amount) END), 2) AS p75,
  ROUND(MAX(CASE WHEN pct <= 0.90 THEN ABS(t.amount) END), 2) AS p90
FROM (
  SELECT
    t.*,
    PERCENT_RANK() OVER (
      PARTITION BY t.category_id
      ORDER BY ABS(t.amount)
    ) AS pct
  FROM transactions t
  WHERE t.type = 'expense'
) t
JOIN dim_category c ON c.category_id = t.category_id
GROUP BY c.category_name
ORDER BY avg_spend DESC;