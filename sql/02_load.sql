-- ============================================================
-- 02_load.sql · ETL: staging → dimensiones → transactions
-- ============================================================

USE finance_ops;

--  tabla staging
CREATE TABLE IF NOT EXISTS stg_transactions_raw (
  transaction_id_raw VARCHAR(120),
  `date`             VARCHAR(30),
  description        VARCHAR(255),
  merchant_raw       VARCHAR(255),
  merchant           VARCHAR(120),
  amount             VARCHAR(40),
  type               VARCHAR(20),
  currency           VARCHAR(10),
  account            VARCHAR(60),
  reference          VARCHAR(80),
  code               VARCHAR(40),
  source_file        VARCHAR(120),
  category           VARCHAR(60)
);

--  vista con tipos correctos
CREATE OR REPLACE VIEW vw_stg_typed AS
SELECT
  NULLIF(TRIM(transaction_id_raw), '')        AS transaction_id_raw,
  STR_TO_DATE(TRIM(`date`), '%Y-%m-%d')       AS transaction_date,
  TRIM(description)                           AS description,
  TRIM(merchant)                              AS merchant,
  CAST(TRIM(amount) AS DECIMAL(12,2))         AS amount,
  LOWER(TRIM(type))                           AS type,
  TRIM(source_file)                           AS source_file,
  TRIM(category)                              AS category,
  TRIM(code)                                  AS code
FROM stg_transactions_raw;

--  poblar dimensiones
INSERT IGNORE INTO dim_category (category_name)
SELECT DISTINCT category
FROM vw_stg_typed
WHERE category IS NOT NULL AND category <> '';

INSERT IGNORE INTO dim_merchant (merchant_name, merchant_norm)
SELECT DISTINCT merchant, LOWER(TRIM(merchant))
FROM vw_stg_typed
WHERE merchant IS NOT NULL AND merchant <> '';

INSERT IGNORE INTO dim_payment_method (payment_method_name, method_type)
VALUES
  ('Tarjeta',        'card'),
  ('Transferencia',  'transfer'),
  ('SINPE Saliente', 'sinpe'),
  ('Otro',           'other');

-- poblar dim_date con fechas de transactions
INSERT IGNORE INTO dim_date (
    date_id, full_date, year, quarter, month,
    month_name, day, day_name, week_of_year, is_weekend
)
SELECT
    CAST(DATE_FORMAT(d.dt, '%Y%m%d') AS UNSIGNED)  AS date_id,
    d.dt                                            AS full_date,
    YEAR(d.dt)                                      AS year,
    QUARTER(d.dt)                                   AS quarter,
    MONTH(d.dt)                                     AS month,
    MONTHNAME(d.dt)                                 AS month_name,
    DAY(d.dt)                                       AS day,
    DAYNAME(d.dt)                                   AS day_name,
    WEEK(d.dt, 3)                                   AS week_of_year,
    IF(WEEKDAY(d.dt) >= 5, 1, 0)                   AS is_weekend
FROM (
    SELECT DISTINCT transaction_date AS dt
    FROM transactions
) d;




-- cargar transactions
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
  pm.payment_method_id,
  LEFT(s.description, 255),
  s.source_file,
  SHA2(CONCAT_WS('|',
    s.transaction_id_raw, s.transaction_date,
    s.amount, s.type, s.source_file, s.category
  ), 256)
FROM vw_stg_typed s
LEFT JOIN dim_category       c  ON c.category_name      = s.category
LEFT JOIN dim_merchant        m  ON m.merchant_norm       = LOWER(TRIM(s.merchant))
LEFT JOIN dim_payment_method  pm ON pm.payment_method_name = CASE s.code
    WHEN 'CP' THEN 'Tarjeta'
    WHEN 'TF' THEN 'Transferencia'
    WHEN 'TS' THEN 'SINPE Saliente'
    ELSE 'Otro'
  END;



-- poblar dim_budget 


  CREATE TABLE IF NOT EXISTS dim_budget (
    budget_id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    year SMALLINT NOT NULL,
    month TINYINT NOT NULL,
    budget_amount DECIMAL(12,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    UNIQUE KEY uq_budget_cat_month (category_id, year, month)
);
