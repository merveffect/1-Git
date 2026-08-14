{{config(
  materialized = 'table'
)
}}

/* =========================================================
   1. USAGE FROM SUBSCRIBED TITLES
========================================================= */

WITH usage AS (

SELECT
    bp_id,
    BP_Full_Name,
    grid_id,

    /* ------------------------------------
       USAGE ONLY FOR SUBSCRIBED TITLES
    ------------------------------------ */

    SUM(CASE WHEN Year = 2024 THEN Requests ELSE 0 END) AS usage_2024,

    SUM(CASE WHEN Year = 2025 THEN Requests ELSE 0 END) AS usage_2025,

    SUM(CASE WHEN Year = 2026 THEN Requests ELSE 0 END) AS usage_2026,

    SUM(Requests) AS total_usage

FROM

{{ref('mart_subscribed_nature_jrnls_usage_long')}}

where Access_Type = "CONTROLLED"

GROUP BY
    bp_id,
    BP_Full_Name,
    grid_id
),

/* =========================================================
   2. DENIALS FROM ORIGINAL DENIAL TABLE
========================================================= */

denials AS (

SELECT
    bp_id,
    grid_id,

    SUM(No_License_2024) AS No_License_2024,

    SUM(No_License_2025) AS No_License_2025,

    SUM(Projected_No_License_2026) AS No_License_2026,

    SUM(No_License) AS total_denials

FROM

{{ref('stg_nature_jrnl_usage_denials')}}

GROUP BY
    bp_id,
    grid_id
),

/* =========================================================
   3. TOP DENIED JOURNALS
========================================================= */

top_journals AS (

SELECT
    bp_id,
    grid_id,

    ARRAY_TO_STRING(
      ARRAY_AGG(Jrnl_Title ORDER BY total_denials DESC LIMIT 10),
      ', '
    ) AS top_denied_journals

FROM
{{ref('mart_top_10_denied_nature_jrnls_per_institute')}}

GROUP BY
    bp_id,
    grid_id
),

/* =========================================================
   4. CITATIONS
========================================================= */

citations AS (

SELECT
    bp_id,
    grid_id,

    COUNT(DISTINCT reference_id) AS citation_count

FROM
{{ref('mart_for2_denied_jrnl_citation_rows_enriched') }}

GROUP BY
    bp_id,
    grid_id
),

/* =========================================================
   5. PUBLICATIONS
========================================================= */

publications AS (

SELECT
    bp_id,
    grid_id,

    total_articles_published AS Total_pubs

FROM
{{ref('int_institute_publication_summary') }}

),

/* =========================================================
   6. SDG PUBLICATIONS
========================================================= */

sdg_publications AS (

SELECT
    bp_id,
    grid_id,

    total_sdg_publications

FROM
{{ref('int_institute_sdg_publication_summary') }}

),
/* =========================================================
   7. FUNDING
========================================================= */

funding AS (

SELECT
    bp_id,
    grid_id,

    SUM(total_funding_eur) AS total_funding

FROM

{{ref('mart_for2_jrnl_mapping_grant') }}

GROUP BY
    bp_id,
    grid_id

),
/* =========================================================
   7. SUBSCRIBED TITLES PER YEAR
========================================================= */

subscribed AS (

SELECT
    bp_id,

    MAX(CASE WHEN Financial_Year__c = "2024"
        THEN subscribed_title_count END) AS subscribed_titles_2024,

    MAX(CASE WHEN Financial_Year__c = "2025"
        THEN subscribed_title_count END) AS subscribed_titles_2025,

    MAX(CASE WHEN Financial_Year__c = "2026"
        THEN subscribed_title_count END) AS subscribed_titles_2026

FROM
{{ref('mart_subscribed_titles_per_year_per_institute') }}

GROUP BY
    bp_id
)

/* =========================================================
   FINAL OUTPUT
========================================================= */

SELECT

    u.bp_id,
    u.BP_Full_Name,
    u.grid_id,

    /* ------------------------------------
       USAGE
    ------------------------------------ */

    u.usage_2024,
    u.usage_2025,
    u.usage_2026,

    u.total_usage,

    /* ------------------------------------
       DENIALS
    ------------------------------------ */

    d.No_License_2024,
    d.No_License_2025,
    d.No_License_2026,

    d.total_denials,

    /* ------------------------------------
       TOP DENIED JOURNALS
    ------------------------------------ */

    t.top_denied_journals,

    /* ------------------------------------
       RESEARCH SIGNALS
    ------------------------------------ */

    c.citation_count,

  p.Total_pubs,
sdg.total_sdg_publications,

    f.total_funding,

    /* ------------------------------------
       SUBSCRIBED TITLES PER YEAR
    ------------------------------------ */

    s.subscribed_titles_2024,
    s.subscribed_titles_2025,
    s.subscribed_titles_2026,

    /* ------------------------------------
       RETOOL PLACEHOLDER
    ------------------------------------ */

    CAST(NULL AS STRING) AS retool_analysis

FROM usage u

LEFT JOIN denials d
USING(bp_id, grid_id)

LEFT JOIN top_journals t
USING(bp_id, grid_id)

LEFT JOIN citations c
USING(bp_id, grid_id)

LEFT JOIN publications p
USING(bp_id, grid_id)

LEFT JOIN sdg_publications sdg
USING(bp_id, grid_id)

LEFT JOIN funding f
USING(bp_id, grid_id)

LEFT JOIN subscribed s
USING(bp_id)
