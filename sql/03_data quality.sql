-- ============================================================
-- 03_data_quality.sql · Validaciones de calidad
-- ============================================================

USE finance_ops;

-- D1.1 % de nulls por columna clave
SELECT
  COUNT(*)                                              AS total_rows,
  ROUND(SUM(category_id IS NULL)    / COUNT(*) * 100, 1) AS pct_null_category,
  ROUND(SUM(merchant_id IS NULL)    / COUNT(*) * 100, 1) AS pct_null_merchant,
  ROUND(SUM(payment_method_id IS NULL) / COUNT(*) * 100, 1) AS pct_null_payment_method,
  ROUND(SUM(notes IS NULL)          / COUNT(*) * 100, 1) AS pct_null_notes
FROM transactions;

-- D1.2 Top merchants sin category_id asignado
SELECT
  COALESCE(m.merchant_name, '(NO MERCHANT)')  AS merchant,
  COUNT(*)                                     AS tx_count,
  ROUND(SUM(ABS(t.amount)), 2)                 AS total_abs_amount
FROM transactions t
LEFT JOIN dim_merchant m ON m.merchant_id = t.merchant_id
WHERE t.type = 'expense'
  AND t.category_id IS NULL
GROUP BY COALESCE(m.merchant_name, '(NO MERCHANT)')
ORDER BY total_abs_amount DESC
LIMIT 20;

-- D1.3A Top 5 montos extremos por categoría
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
SELECT category_name, merchant_name, transaction_date, amount
FROM ranked
WHERE rn <= 5
ORDER BY category_name, rn;

-- D1.3B Outliers por regla 3-sigma dentro de cada categoría
WITH stats AS (
  SELECT
    c.category_id,
    c.category_name,
    AVG(ABS(t.amount))        AS avg_abs_amt,
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
ORDER BY z_score DESC
LIMIT 50;

-- D1.4 Variabilidad por categoría (para detectar categorías inestables)
SELECT
  c.category_name,
  COUNT(*)                            AS n,
  ROUND(AVG(ABS(t.amount)), 2)        AS avg_abs_amt,
  ROUND(STDDEV_SAMP(ABS(t.amount)), 2) AS sd_abs_amt,
  ROUND(MAX(ABS(t.amount)), 2)        AS max_abs_amt
FROM transactions t
JOIN dim_category c ON c.category_id = t.category_id
WHERE t.type = 'expense'
GROUP BY c.category_name
ORDER BY sd_abs_amt DESC;