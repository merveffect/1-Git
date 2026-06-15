
{{config(
  materialized = 'table'
)
}}

WITH
/* --------------------------------------------------
1️⃣ Institution FOR2 – DEDUPED
-------------------------------------------------- */
inst_for2 AS (
  SELECT
    org_grid_id,
    for2name,
    SUM(no_of_grants) AS grants,
    SUM(total_funding_eur) AS total_funding_eur
  FROM
  {{ref('stg_for2_top10_by_funding_per_institute') }}
    
  GROUP BY
    org_grid_id,
    for2name
),

/* --------------------------------------------------
2️⃣ Journal FOR2 – DEDUPED
-------------------------------------------------- */
journal_for2 AS (
  SELECT
    journal_id,
    journal_title,
    for2,
    SUM(no_of_articles) AS journal_for2_articles
  FROM
    {{ref('stg_jrnl_for2_top10') }}

  GROUP BY
    journal_id,
    journal_title,
    for2
),

/* --------------------------------------------------
3️⃣ Journal Metadata
-------------------------------------------------- */
journal_meta AS (
  SELECT
    LOWER(TRIM(Title)) AS journal_title_clean,
    `Product ID` AS journal_id_meta,
    `Launch Year` AS launch_year
  FROM

  {{source('journal_metadata', 'nature_title_list') }}
 
),

/* --------------------------------------------------
4️⃣ BP / GRID context
-------------------------------------------------- */
bp_grid AS (
  SELECT DISTINCT
    grid_id,
    bp_id,
    BP_Full_Name,
    Jrnl_Title,
    LOWER(TRIM(Jrnl_Title)) AS journal_title_clean
    
  FROM

    {{ref('mart_top_10_denied_nature_jrnls_per_institute') }}
   
),

base AS (

SELECT

  --------------------------------------------------
  -- Institute dimensions
  --------------------------------------------------
  b.bp_id,
  b.BP_Full_Name,
  b.grid_id,

  --------------------------------------------------
  -- Journal dimensions
  --------------------------------------------------
  j.journal_id,
  b.Jrnl_Title AS journal_title,
  m.launch_year,

  --------------------------------------------------
  -- FOR2 alignment
  --------------------------------------------------
  f.for2name AS inst_for2,

  --------------------------------------------------
  -- Research strength metrics
  --------------------------------------------------
  j.journal_for2_articles,

  COALESCE(f.grants,0) AS grants,

  COALESCE(f.total_funding_eur,0) AS total_funding_eur,

  --------------------------------------------------
  -- Match indicators
  --------------------------------------------------
  CASE
    WHEN f.for2name IS NOT NULL THEN 'YES'
    ELSE ''
  END AS match_flag,

  CASE
    WHEN f.for2name IS NOT NULL THEN 1
    ELSE 0
  END AS has_journal

FROM
  bp_grid b

LEFT JOIN
  journal_for2 j
    ON LOWER(TRIM(j.journal_title)) = b.journal_title_clean

LEFT JOIN
  journal_meta m
    ON b.journal_title_clean = m.journal_title_clean

INNER JOIN
  inst_for2 f
    ON f.org_grid_id = b.grid_id
   AND f.for2name = j.for2

)

SELECT
  *,

  DENSE_RANK() OVER (
    PARTITION BY bp_id
    ORDER BY total_funding_eur DESC
  ) AS funding_rank

FROM base
