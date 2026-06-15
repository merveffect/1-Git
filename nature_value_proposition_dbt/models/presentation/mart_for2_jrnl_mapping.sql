
{{config(
  materialized = 'table'
)
}}

WITH inst_for2 AS (

SELECT
    org_grid_id,
    for2,
    for2id,

    CAST(no_of_articles AS INT64) AS inst_no_of_articles,

    /* ------------------------------------
       NEW TOTAL ARTICLES COLUMN
    ------------------------------------ */

    total_articles_institute

FROM
{{ref('stg_top10_for2_per_institute') }}

),


journal_for2 AS (

SELECT
    journal_id,
    journal_title,

    for2,
    for2id,

    no_of_articles AS journal_for2_articles

FROM
{{ref('stg_jrnl_for2_top10') }}
),

journal_meta AS (

SELECT
    LOWER(TRIM(Title)) AS journal_title_clean,

    `Product ID` AS journal_id_meta,

    `Launch Year` AS launch_year

FROM

{{source('journal_metadata', 'nature_title_list') }}

),

denied_journals AS (

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

    /* ------------------------------------
       INSTITUTION INFO
    ------------------------------------ */

    d.bp_id,
    d.BP_Full_Name,
    d.grid_id,

    /* ------------------------------------
       JOURNAL INFO
    ------------------------------------ */

    d.Jrnl_Title AS journal_title,

    j.journal_id,

    m.launch_year,

    /* ------------------------------------
       FOR2 INFO
    ------------------------------------ */

    j.for2,
    j.for2id,

    /* ------------------------------------
       INSTITUTE PUBLICATION METRICS
    ------------------------------------ */

    COALESCE(f.inst_no_of_articles,0) AS inst_no_of_articles,

    COALESCE(f.total_articles_institute,0) AS total_articles_institute,

    /* ------------------------------------
       JOURNAL FOR2 STRENGTH
    ------------------------------------ */

    j.journal_for2_articles,

    /* ------------------------------------
       DEMAND SIGNALS
    ------------------------------------ */

    d.total_denials,
    d.total_requests,

    /* ------------------------------------
       MATCH FLAG
    ------------------------------------ */

    CASE
      WHEN f.for2id IS NOT NULL THEN 'YES'
      ELSE ''
    END AS match_flag

FROM denied_journals d

LEFT JOIN journal_for2 j
ON LOWER(TRIM(j.journal_title)) =
   LOWER(TRIM(d.Jrnl_Title))

LEFT JOIN journal_meta m
ON LOWER(TRIM(d.Jrnl_Title)) =
   m.journal_title_clean

LEFT JOIN inst_for2 f
ON f.org_grid_id = d.grid_id
AND f.for2id = j.for2id

)

SELECT
    *,

    /* ------------------------------------
       PUBLICATION RANK
    ------------------------------------ */

    DENSE_RANK() OVER (
      PARTITION BY bp_id
      ORDER BY inst_no_of_articles ASC
    ) AS publication_rank

FROM base