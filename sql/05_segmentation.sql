-- ============================================================
-- 05_segmentation.sql · Segmentación de gastos
-- ============================================================

USE finance_ops;

-- S3.1 Gasto por método de pago
SELECT
    pm.payment_method_name,
    COUNT(t.transaction_id)                            AS total_transactions,
    ROUND(SUM(ABS(t.amount)), 2)                       AS total_spent,
    ROUND(
        SUM(ABS(t.amount)) / SUM(SUM(ABS(t.amount))) OVER () * 100
    , 2)                                               AS pct_of_total
FROM transactions t
JOIN dim_payment_method pm ON t.payment_method_id = pm.payment_method_id
WHERE t.type = 'expense'
GROUP BY pm.payment_method_id, pm.payment_method_name
ORDER BY total_spent DESC;


-- S3.2 Gasto por día de semana
SELECT
    d.day_name,
    WEEKDAY(t.transaction_date)          AS day_num,
    d.is_weekend,
    COUNT(t.transaction_id)              AS total_transactions,
    ROUND(SUM(ABS(t.amount)), 2)         AS total_spent,
    ROUND(AVG(ABS(t.amount)), 2)         AS avg_per_transaction
FROM transactions t
JOIN dim_date d ON d.full_date = t.transaction_date
WHERE t.type = 'expense'
GROUP BY d.day_name, WEEKDAY(t.transaction_date), d.is_weekend
ORDER BY day_num;


-- S3.3 Top merchants + % acumulado (Pareto 80/20)
WITH merchant_totals AS (
    SELECT
        m.merchant_name,
        ROUND(SUM(ABS(t.amount)), 2)     AS total_spent,
        COUNT(t.transaction_id)          AS total_transactions
    FROM transactions t
    JOIN dim_merchant m ON t.merchant_id = m.merchant_id
    WHERE t.type = 'expense'
    GROUP BY m.merchant_id, m.merchant_name
),
ranked AS (
    SELECT
        merchant_name,
        total_spent,
        total_transactions,
        ROUND(
            total_spent / SUM(total_spent) OVER () * 100
        , 2)                             AS pct_of_total,
        ROUND(
            SUM(total_spent) OVER (
                ORDER BY total_spent DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) / SUM(total_spent) OVER () * 100
        , 2)                             AS cumulative_pct
    FROM merchant_totals
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_spent DESC)  AS ranking,
    merchant_name,
    total_spent,
    total_transactions,
    pct_of_total,
    cumulative_pct
FROM ranked
ORDER BY total_spent DESC
LIMIT 20;

