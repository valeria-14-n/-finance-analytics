-- D1.2 Top merchants with NULL category_id
SELECT
  COALESCE(m.merchant_name, '(NO MERCHANT)') AS merchant,
  COUNT(*) AS tx_count,
  ROUND(SUM(ABS(t.amount)), 2) AS total_abs_amount
FROM transactions t
LEFT JOIN dim_merchant m ON m.merchant_id = t.merchant_id
WHERE t.type = 'expense'
  AND t.category_id IS NULL
GROUP BY COALESCE(m.merchant_name, '(NO MERCHANT)')
ORDER BY total_abs_amount DESC, tx_count DESC
LIMIT 20;

-- D1.3A Extreme amounts per category (Top 5 per category)
WITH ranked AS (
  SELECT
    c.category_name,
    m.merchant_name,
    t.transaction_date,
    t.amount,
    ROW_NUMBER() OVER (
      PARTITION BY c.category_name
      ORDER BY ABS(t.amount) DESC
    ) AS rn
  FROM transactions t
  LEFT JOIN dim_category c ON c.category_id = t.category_id
  LEFT JOIN dim_merchant m ON m.merchant_id = t.merchant_id
  WHERE t.type = 'expense'
)
SELECT
  category_name,
  merchant_name,
  transaction_date,
  amount
FROM ranked
WHERE rn <= 5
ORDER BY category_name, rn;

-- D1.3B Outliers using 3-sigma rule within each category (expenses)
WITH stats AS (
  SELECT
    c.category_id,
    c.category_name,
    AVG(ABS(t.amount)) AS avg_abs_amt,
    STDDEV_SAMP(ABS(t.amount)) AS sd_abs_amt
  FROM transactions t
  JOIN dim_category c ON c.category_id = t.category_id
  WHERE t.type = 'expense'
  GROUP BY c.category_id, c.category_name
),
flagged AS (
  SELECT
    s.category_name,
    m.merchant_name,
    t.transaction_date,
    t.amount,
    s.avg_abs_amt,
    s.sd_abs_amt,
    (ABS(t.amount) - s.avg_abs_amt) / NULLIF(s.sd_abs_amt, 0) AS z_score
  FROM transactions t
  JOIN stats s ON s.category_id = t.category_id
  LEFT JOIN dim_merchant m ON m.merchant_id = t.merchant_id
  WHERE t.type = 'expense'
)
SELECT *
FROM flagged
WHERE z_score >= 2
ORDER BY z_score DESC, ABS(amount) DESC
LIMIT 50;

-- Check variability per category
SELECT
  c.category_name,
  COUNT(*) AS n,
  ROUND(AVG(ABS(t.amount)),2) AS avg_abs_amt,
  ROUND(STDDEV_SAMP(ABS(t.amount)),2) AS sd_abs_amt,
  ROUND(MAX(ABS(t.amount)),2) AS max_abs_amt
FROM transactions t
JOIN dim_category c ON c.category_id = t.category_id
WHERE t.type = 'expense'
GROUP BY c.category_name
ORDER BY sd_abs_amt DESC;