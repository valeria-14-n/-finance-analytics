CREATE TABLE IF NOT EXISTS stg_transactions_raw (
  transaction_id_raw VARCHAR(120),
  `date` VARCHAR(30),
  description VARCHAR(255),
  merchant_raw VARCHAR(255),
  merchant VARCHAR(120),
  amount VARCHAR(40),
  type VARCHAR(20),
  currency VARCHAR(10),
  account VARCHAR(60),
  reference VARCHAR(80),
  code VARCHAR(40),
  source_file VARCHAR(120),
  category VARCHAR(60)
);

CREATE OR REPLACE VIEW vw_stg_typed AS
SELECT
  NULLIF(TRIM(transaction_id_raw), '') AS transaction_id_raw,
  STR_TO_DATE(TRIM(`date`), '%Y-%m-%d') AS transaction_date,
  TRIM(description) AS description,
  TRIM(merchant) AS merchant,
  CAST(TRIM(amount) AS DECIMAL(12,2)) AS amount,
  LOWER(TRIM(type)) AS type,
  TRIM(source_file) AS source_file,
  TRIM(category) AS category
FROM stg_transactions_raw;


/*Poblar dimensiones*/

USE finance_ops;

INSERT IGNORE INTO dim_category (category_name)
SELECT DISTINCT category
FROM vw_stg_typed
WHERE category IS NOT NULL AND category <> '';

INSERT IGNORE INTO dim_merchant (merchant_name, merchant_norm)
SELECT DISTINCT merchant, LOWER(TRIM(merchant))
FROM vw_stg_typed
WHERE merchant IS NOT NULL AND merchant <> '';

SELECT COUNT(*) AS categories FROM dim_category;
SELECT COUNT(*) AS merchants FROM dim_merchant;






INSERT IGNORE INTO transactions (
  transaction_date, amount, type,
  category_id, merchant_id, payment_method_id,
  notes, source_file, source_row_hash
)
SELECT
  s.transaction_date,
  s.amount,
  CASE WHEN s.type IN ('income','expense','transfer') THEN s.type ELSE 'expense' END,
  c.category_id,
  m.merchant_id,
  NULL,
  LEFT(s.description, 255) AS notes,
  s.source_file,
  SHA2(CONCAT_WS('|', s.transaction_id_raw, s.transaction_date, s.amount, s.type, s.source_file, s.category), 256) AS source_row_hash
FROM vw_stg_typed s
LEFT JOIN dim_category c ON c.category_name = s.category
LEFT JOIN dim_merchant m ON m.merchant_norm = LOWER(TRIM(s.merchant));




SELECT COUNT(*) AS fact_rows FROM transactions;

SELECT
  SUM(category_id IS NULL) AS null_category_id,
  SUM(merchant_id IS NULL) AS null_merchant_id
FROM transactions;