{{ config(
    materialized = 'table',
    schema = 'Institutional_analysisGA4_EU',
    tags = ['monthly_run', 'dashboard']
) }}

WITH source_data AS (
    SELECT *
    FROM {{ ref('int_tablethree_2025') }}
    
    WHERE
        event_date BETWEEN DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH)
        AND LAST_DAY(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
        AND bpid IS NOT NULL
        AND bpid NOT IN ('(not set)', '')
        AND REGEXP_CONTAINS(bpid, r'^\d{10}$')
)

SELECT
    bpid,
    user_pseudo_id,
    DATE_TRUNC(event_date, MONTH) AS event_month,
    ga_session_id,
    search_term,
    Institution,
    country,
    session_engaged,
    medium,

    CASE
        WHEN regexp_contains(content_type, '(?i)^(article|journal)$') THEN 'Journal'
        WHEN regexp_contains(content_type, '(?i)^(chapter|book|referenceworkentry|referencework|bookseries)$') THEN 'Book'
        WHEN regexp_contains(content_type, '(?i)^protocol$') THEN 'Protocol'
        ELSE 'Other'
    END AS content_type,

    CASE
        WHEN REGEXP_CONTAINS(hostname, 'link.springer.com') THEN 'Springer Link'
        WHEN REGEXP_CONTAINS(hostname, 'www.nature.com') THEN 'Nature'
        ELSE 'Other'
    END AS platform,

    CASE
        WHEN REGEXP_CONTAINS(source, r'.*scholar.*google.*') THEN 'google scholar'
        WHEN REGEXP_CONTAINS(source, r'.*ncbi.*') THEN 'pubmed'
        WHEN REGEXP_CONTAINS(source, r'.*twitter.*|t\.co|twt.*') THEN 'twitter'
        WHEN REGEXP_CONTAINS(source, r'.*facebook.*|fbk.*|FBK.*') THEN 'facebook'
        WHEN REGEXP_CONTAINS(source, r'.*google.*') THEN 'google'
        WHEN source = '(not set)' THEN 'direct' 
        ELSE source
    END AS normalized_source,

    (engagement_time_msec / 1000.0) AS engagement_time_secs,

    COUNT(CASE WHEN event_name = 'session_start' THEN 1 END) AS session_start,
    COUNT(CASE WHEN event_name = 'page_view' THEN 1 END) AS pageviews
    

FROM source_data

GROUP BY
    bpid,
    user_pseudo_id,
    event_month, 
    content_type,
    search_term,
    Institution,
    platform,
    normalized_source,
    ga_session_id,
    country,
    session_engaged,
    engagement_time_secs,
    medium