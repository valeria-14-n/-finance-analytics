USE finance_ops;
-- ============================================================
-- ALERTAS DE PRESUPUESTO
-- ============================================================


CREATE OR REPLACE VIEW vw_budget_suggestion AS

WITH monthly_spend AS (
    SELECT 
        c.category_id,
        c.category_name,
        d.year,
        d.month,
        ROUND(SUM(ABS(t.amount)), 2) AS gasto_mensual
    FROM transactions t
    JOIN dim_category c 
        ON t.category_id = c.category_id
    JOIN dim_date d 
        ON t.transaction_date = d.full_date
    WHERE t.type = 'expense'
      AND c.is_active = 1
      AND t.amount < 0
      -- últimos 12 meses
      AND d.full_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY c.category_id, c.category_name, d.year, d.month
),

filtered AS (
    SELECT *
    FROM monthly_spend
),

aggregated AS (
    SELECT 
        category_id,
        category_name,
        COUNT(*) AS meses_con_datos,
        ROUND(SUM(gasto_mensual), 2) AS gasto_total_historico,
        ROUND(AVG(gasto_mensual), 2) AS gasto_promedio_mensual,
        ROUND(MAX(gasto_mensual), 2) AS gasto_maximo_mensual
    FROM filtered
    GROUP BY category_id, category_name
    HAVING COUNT(*) >= 2
)

SELECT 
    category_id,
    category_name,
    meses_con_datos,
    gasto_total_historico,
    gasto_promedio_mensual,
    gasto_maximo_mensual,

    ROUND(gasto_promedio_mensual * 12, 2) AS presupuesto_anual_base,
    ROUND(gasto_promedio_mensual * 12 * 1.12, 2) AS presupuesto_12pct,
    ROUND(gasto_promedio_mensual * 12 * 1.15, 2) AS presupuesto_15pct,
    ROUND(gasto_promedio_mensual * 12 * 1.20, 2) AS presupuesto_20pct,

    CASE 
        WHEN meses_con_datos >= 6 THEN 'Historial bueno'
        ELSE 'Historial moderado'
    END AS calidad_historico

FROM aggregated
ORDER BY gasto_promedio_mensual DESC;


DELETE FROM dim_budget_annual WHERE year = 2026;

INSERT INTO dim_budget_annual (category_id, year, annual_budget)
SELECT 
    category_id,
    2026,
    presupuesto_12pct
FROM vw_budget_suggestion
ON DUPLICATE KEY UPDATE 
    annual_budget = VALUES(annual_budget);


CREATE OR REPLACE VIEW vw_budget_burn AS

WITH actual AS (
    SELECT 
        c.category_id,
        c.category_name,
        d.year,
        SUM(ABS(t.amount)) AS gasto_ytd,
        MAX(d.full_date) AS ultima_fecha
    FROM transactions t
    JOIN dim_category c 
        ON t.category_id = c.category_id
    JOIN dim_date d 
        ON t.transaction_date = d.full_date
    WHERE t.type = 'expense'
      AND c.is_active = 1
      AND t.amount < 0
      AND d.year = 2026
    GROUP BY c.category_id, c.category_name, d.year
)

SELECT 
    a.category_name,
    a.year,
    b.annual_budget,

    ROUND(b.annual_budget / 12, 2) AS presupuesto_mensual,
    ROUND(a.gasto_ytd, 2) AS gasto_ytd,

    ROUND(
        (a.gasto_ytd / NULLIF(b.annual_budget, 0)) * 100, 
    2) AS burn_pct,

    CASE 
        WHEN (a.gasto_ytd / NULLIF(b.annual_budget, 0)) >= 0.9 THEN 'Muy Alto'
        WHEN (a.gasto_ytd / NULLIF(b.annual_budget, 0)) >= 0.7 THEN 'Alto'
        WHEN (a.gasto_ytd / NULLIF(b.annual_budget, 0)) >= 0.4 THEN 'Normal'
        ELSE 'Bajo'
    END AS burn_status,

    -- proyección anual basada en ritmo actual
    ROUND(
        a.gasto_ytd * (365.0 / DAYOFYEAR(a.ultima_fecha)), 
    2) AS run_rate_anual

FROM actual a
INNER JOIN dim_budget_annual b 
    ON a.category_id = b.category_id 
   AND a.year = b.year

ORDER BY burn_pct DESC;

SELECT 
    c.category_name,
    b.year,
    b.annual_budget,
    ROUND(b.annual_budget / 12, 2) AS mensual
FROM dim_budget_annual b
JOIN dim_category c 
    ON b.category_id = c.category_id
WHERE b.annual_budget IS NOT NULL  
ORDER BY b.annual_budget DESC;



--- ALERTAS DE DESVIACIÓN (2 SIGMAS)

CREATE OR REPLACE VIEW vw_alertas_2sigma AS
WITH monthly AS (
    SELECT 
        c.category_name,
        d.year,
        d.month,
        ROUND(-SUM(t.amount), 2) AS gasto_mes,
        COUNT(*) AS num_transacciones
    FROM transactions t
    JOIN dim_category c ON t.category_id = c.category_id
    JOIN dim_date d ON t.transaction_date = d.full_date
    WHERE t.type = 'expense'
      AND c.is_active = 1
      AND t.amount < 0
    GROUP BY c.category_name, d.year, d.month
),

stats_historicos AS (
    SELECT 
        category_name,
        ROUND(AVG(gasto_mes), 2) AS promedio_historico,
        ROUND(STDDEV_POP(gasto_mes), 2) AS desviacion_std,
        COUNT(*) AS meses_historicos
    FROM monthly
    GROUP BY category_name
    HAVING COUNT(*) >= 2
)

SELECT 
    m.category_name,
    m.year,
    m.month,
    m.gasto_mes,
    s.promedio_historico,
    s.desviacion_std,
    ROUND(s.promedio_historico + 2 * s.desviacion_std, 2) AS umbral_2sigma,
    m.num_transacciones,
    s.meses_historicos,
    CASE 
        WHEN m.gasto_mes > (s.promedio_historico + 2 * s.desviacion_std) THEN ' ALERTA FUERTE'
        WHEN m.gasto_mes > (s.promedio_historico + 1 * s.desviacion_std) THEN ' Alerta Moderada'
        ELSE ' Normal'
    END AS alerta_status,
    ROUND((m.gasto_mes - s.promedio_historico) / NULLIF(s.desviacion_std, 0), 2) AS sigmas
FROM monthly m
JOIN stats_historicos s ON m.category_name = s.category_name
WHERE m.year = 2026
ORDER BY m.gasto_mes DESC;

SELECT * FROM vw_alertas_2sigma;

SELECT *
FROM vw_budget_suggestion
WHERE category_name = 'Entretenimiento';


SELECT 
    d.year,
    d.month,
    ROUND(-SUM(t.amount), 2) AS gasto_mensual
FROM transactions t
JOIN dim_category c ON t.category_id = c.category_id
JOIN dim_date d ON t.transaction_date = d.full_date
WHERE c.category_name = 'Entretenimiento'
  AND t.type = 'expense'
GROUP BY d.year, d.month
ORDER BY d.year, d.month;
