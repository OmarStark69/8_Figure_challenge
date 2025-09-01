-- get dates 
WITH date_ranges AS (
    SELECT
        '2025-06-27'::date - INTERVAL '30 days' AS current_period_start,
        '2025-06-27'::date AS current_period_end,
        '2025-06-27'::date - INTERVAL '61 days' AS previous_period_start,
        '2025-06-27'::date - INTERVAL '31 days' AS previous_period_end
),

-- KPIs for current period
current_period_kpis AS (
    SELECT
        'Last 30 Days' AS period,
        SUM(spend) AS total_spend,
        SUM(conversions) AS total_conversions,
        SUM(spend) / NULLIF(SUM(conversions), 0) AS cac,
        (SUM(conversions) * 100) / NULLIF(SUM(spend), 0) AS roas
    FROM
        public.spends_report, date_ranges
    WHERE
        "date" >= date_ranges.current_period_start AND "date" <= date_ranges.current_period_end
),

-- KPIs for previous period
previous_period_kpis AS (
    SELECT
        'Previous 30 Days' AS period,
        SUM(spend) AS total_spend,
        SUM(conversions) AS total_conversions,
        SUM(spend) / NULLIF(SUM(conversions), 0) AS cac,
        (SUM(conversions) * 100) / NULLIF(SUM(spend), 0) AS roas
    FROM
        public.spends_report, date_ranges
    WHERE
        "date" >= date_ranges.previous_period_start AND "date" <= date_ranges.previous_period_end
)

-- Calculate KPI
SELECT
    'CAC' AS metric,
    current.cac AS last_30_days,
    previous.cac AS previous_30_days,
    COALESCE((current.cac - previous.cac) / NULLIF(previous.cac, 0) * 100, 0) AS delta_percent
FROM
    current_period_kpis current, previous_period_kpis previous

UNION ALL

SELECT
    'ROAS' AS metric,
    current.roas AS last_30_days,
    previous.roas AS previous_30_days,
    COALESCE((current.roas - previous.roas) / NULLIF(previous.roas, 0) * 100, 0) AS delta_percent
FROM
    current_period_kpis current, previous_period_kpis previous;
