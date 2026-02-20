CREATE DATABASE IF NOT EXISTS finance_ops;
USE finance_ops;

CREATE TABLE IF NOT EXISTS dim_category (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(60) NOT NULL UNIQUE,
  category_group VARCHAR(60),
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dim_payment_method (
  payment_method_id INT AUTO_INCREMENT PRIMARY KEY,
  payment_method_name VARCHAR(60) NOT NULL UNIQUE,
  method_type VARCHAR(30),
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dim_merchant (
  merchant_id INT AUTO_INCREMENT PRIMARY KEY,
  merchant_name VARCHAR(120) NOT NULL,
  merchant_norm VARCHAR(120) NOT NULL,
  merchant_type VARCHAR(60),
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_merchant_norm (merchant_norm)
);

CREATE TABLE IF NOT EXISTS dim_date (
  date_id INT PRIMARY KEY,
  full_date DATE NOT NULL UNIQUE,
  year SMALLINT NOT NULL,
  quarter TINYINT NOT NULL,
  month TINYINT NOT NULL,
  month_name VARCHAR(15) NOT NULL,
  day TINYINT NOT NULL,
  day_name VARCHAR(15) NOT NULL,
  week_of_year TINYINT NOT NULL,
  is_weekend TINYINT(1) NOT NULL
);

CREATE TABLE IF NOT EXISTS transactions (
  transaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  transaction_date DATE NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  type ENUM('income','expense','transfer') NOT NULL,
  category_id INT,
  merchant_id INT,
  payment_method_id INT,
  notes VARCHAR(255),
  source_file VARCHAR(120),
  source_row_hash CHAR(64),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
  FOREIGN KEY (merchant_id) REFERENCES dim_merchant(merchant_id),
  FOREIGN KEY (payment_method_id) REFERENCES dim_payment_method(payment_method_id),

  INDEX ix_tx_date (transaction_date),
  INDEX ix_tx_type (type)
);


