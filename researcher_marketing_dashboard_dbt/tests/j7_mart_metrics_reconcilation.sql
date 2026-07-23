{{ config(store_failures = true) }}

{% set start_date = "DATE '2025-01-01'" %}

WITH base_totals AS (
    SELECT
        SUM(Sessions)                AS sessions,
        ROUND(SUM(cost), 4)          AS cost
    FROM {{ ref('j7') }}
    WHERE date >= {{ start_date }}
),

mart_totals AS (

    -- AWA
    SELECT
        'j7_AWA'                     AS mart_name,
        SUM(sessions)                AS sessions,
        ROUND(SUM(cost), 4)          AS cost
    FROM {{ ref('j7_AWA') }}
    WHERE date >= {{ start_date }}

    UNION ALL

    -- BAE
    SELECT
        'j7_BAE',
        SUM(Sessions),
        ROUND(SUM(cost), 4)
    FROM {{ ref('j7_BAE') }}
    WHERE date >= {{ start_date }}

    UNION ALL

    -- Nurture
    SELECT
        'j7_Nurture',
        SUM(Sessions),
        ROUND(SUM(cost), 4)
    FROM {{ ref('j7_Nurture') }}
    WHERE date >= {{ start_date }}

    UNION ALL

    -- SRF
    SELECT
        'j7_SRF',
        SUM(Sessions),
        ROUND(SUM(cost), 4)
    FROM {{ ref('j7_SRF') }}
    WHERE date >= {{ start_date }}
)

SELECT
    m.mart_name,
    b.sessions AS j7_sessions,
    m.sessions AS mart_sessions,
    b.cost     AS j7_cost,
    m.cost     AS mart_cost
FROM mart_totals m
CROSS JOIN base_totals b
WHERE
    COALESCE(m.sessions, 0) != COALESCE(b.sessions, 0)
    OR
    COALESCE(m.cost, 0) != COALESCE(b.cost, 0)
