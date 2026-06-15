{{ config(store_failures = true) }}

{% set start_date = "DATE '2025-01-01'" %}

WITH j7_max_date AS (
    SELECT MAX(date) AS max_date
    FROM {{ ref('j7') }}
),

j7_totals AS (
    SELECT SUM(Sessions) AS j7_sessions
    FROM {{ ref('j7') }}
    WHERE date BETWEEN {{ start_date }}
                          AND (SELECT max_date FROM j7_max_date)
),

ga4_totals AS (
    SELECT SUM(Sessions___GA4_event_based__Google_Analytics) AS ga4_sessions
    FROM {{ source('ga4_ria_researcher_report', 'googleanalytics') }}
    WHERE date BETWEEN {{ start_date }}
                          AND (SELECT max_date FROM j7_max_date)
)

SELECT
    j.j7_sessions,
    g.ga4_sessions,
    (SELECT max_date FROM j7_max_date) AS validated_until
FROM j7_totals j
CROSS JOIN ga4_totals g
WHERE COALESCE(j.j7_sessions, 0) != COALESCE(g.ga4_sessions, 0)
