SELECT COUNT(*) AS total_rows
FROM transactions;

SELECT
  COUNT(*) AS total_rows,

  ROUND(100 * SUM(transaction_date IS NULL) / COUNT(*), 2) AS pct_null_transaction_date,
  ROUND(100 * SUM(amount IS NULL) / COUNT(*), 2)          AS pct_null_amount,
  ROUND(100 * SUM(type IS NULL) / COUNT(*), 2)            AS pct_null_type,

  ROUND(100 * SUM(category_id IS NULL) / COUNT(*), 2)     AS pct_null_category_id,
  ROUND(100 * SUM(merchant_id IS NULL) / COUNT(*), 2)     AS pct_null_merchant_id,
  ROUND(100 * SUM(payment_method_id IS NULL) / COUNT(*), 2) AS pct_null_payment_method_id,

  ROUND(100 * SUM(notes IS NULL OR TRIM(notes) = '') / COUNT(*), 2)       AS pct_null_or_blank_notes,
  ROUND(100 * SUM(source_file IS NULL OR TRIM(source_file) = '') / COUNT(*), 2) AS pct_null_or_blank_source_file,
  ROUND(100 * SUM(source_row_hash IS NULL OR TRIM(source_row_hash) = '') / COUNT(*), 2) AS pct_null_or_blank_source_row_hash
FROM transactions;

SELECT
  SUM(t.category_id IS NOT NULL AND c.category_id IS NULL)       AS broken_category_fk,
  SUM(t.merchant_id IS NOT NULL AND m.merchant_id IS NULL)       AS broken_merchant_fk,
  SUM(t.payment_method_id IS NOT NULL AND p.payment_method_id IS NULL) AS broken_payment_method_fk
FROM transactions t
LEFT JOIN dim_category c ON t.category_id = c.category_id
LEFT JOIN dim_merchant m ON t.merchant_id = m.merchant_id
LEFT JOIN dim_payment_method p ON t.payment_method_id = p.payment_method_id;

