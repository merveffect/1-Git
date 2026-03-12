{{ config(store_failures = true) }}

WITH g1_totals AS (
    SELECT
        ROUND(SUM(cost), 4)        AS cost,
        SUM(clicks)                AS clicks,
        SUM(impressions)           AS impressions
    FROM {{ ref('g1_mktp') }}
),

j1_totals AS (
    SELECT
        ROUND(SUM(cost), 4)        AS cost,
        SUM(clicks)                AS clicks,
        SUM(impressions)           AS impressions
    FROM {{ ref('j1_mktp') }}
)

SELECT
    g.cost          AS g1_mktp_cost,
    j.cost          AS j1_mktp_cost,
    g.clicks        AS g1_mktp_clicks,
    j.clicks        AS j1_mktp_clicks,
    g.impressions   AS g1_mktp_impressions,
    j.impressions   AS j1_mktp_impressions
FROM g1_totals g
CROSS JOIN j1_totals j
WHERE
    g.cost != j.cost
    OR g.clicks != j.clicks
    OR g.impressions != j.impressions
