
{{config(
  materialized = 'table'
)
}}

WITH inst_sdg AS (
  -- Top SDG per institute
  SELECT
    org_grid_id,
    sdgcode,
    sdgname,
    CAST(no_of_articles AS INT64) AS inst_no_of_articles
  FROM

  {{ref('stg_top10_sdg_per_institute') }}

),

journal_sdg AS (
  -- SDG per Nature journal
  SELECT
    journal_id,
    journal_title,
    sdgcode,
    no_of_articles AS journal_for2_articles
  FROM

  {{ref('stg_jrnl_sdg_top10') }}

),

journal_meta AS (
  -- Nature journal metadata (Launch year)
  SELECT
    journal_title_clean,
     journal_id,
     launch_year
  FROM

  {{ref('stg_jrnl_metadata') }}

),

denied_journals AS (
  -- Top denied unlicensed journals
  SELECT
    grid_id,
    bp_id,
    BP_Full_Name,
    Jrnl_Title,
    total_denials,
    total_requests
  FROM

  {{ref('mart_top_10_denied_nature_jrnls_per_institute') }}
    
),

base AS (

SELECT

  -- Institute info
  d.bp_id,
  d.BP_Full_Name,
  d.grid_id,

  -- Journal info
  d.Jrnl_Title AS journal_title,
  j.journal_id,
  m.launch_year,

  -- SDG mapping
  f.sdgcode,
  f.sdgname,

  COALESCE(f.inst_no_of_articles,0) AS inst_no_of_articles,

  j.journal_for2_articles,

  -- Usage
  d.total_denials,
  d.total_requests,

  -- Match flag
  CASE
    WHEN f.sdgcode IS NOT NULL THEN 'YES'
    ELSE ''
  END AS match_flag,

  CASE
    WHEN f.sdgcode IS NOT NULL THEN 1
    ELSE 0
  END AS has_journal

FROM
  denied_journals d

LEFT JOIN
  journal_sdg j
    ON LOWER(TRIM(j.journal_title)) = LOWER(TRIM(d.Jrnl_Title))

LEFT JOIN
  journal_meta m
    ON LOWER(TRIM(d.Jrnl_Title)) = m.journal_title_clean

LEFT JOIN
  inst_sdg f
    ON f.org_grid_id = d.grid_id
   AND f.sdgcode = j.sdgcode

)

SELECT
  *,

  DENSE_RANK() OVER (
    PARTITION BY bp_id
    ORDER BY inst_no_of_articles ASC
  ) AS publication_rank

FROM base
