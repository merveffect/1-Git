{{config(
  materialized = 'table'
)
}}
 
/* =========================================================
   PUBLICATIONS FROM 2022 ONWARDS
========================================================= */
 
WITH base AS (
 
SELECT
    t.id AS pub_id,
    a_grid AS grid_id
 
FROM

    {{source('publications', 'publications') }} t
 
LEFT JOIN UNNEST(t.authors) AS a
LEFT JOIN UNNEST(a.grid_ids) AS a_grid
 
WHERE
    t.year >= 2022
    AND t.type = "article"
    AND LENGTH(a_grid) > 0
 
),
 
/* =========================================================
   TOTAL PUBLICATIONS PER GRID
========================================================= */
 
publication_counts AS (
 
SELECT
    grid_id,
    COUNT(DISTINCT pub_id) AS total_articles_published
 
FROM
    base
 
GROUP BY
    grid_id
 
),
 
/* =========================================================
   BPID ↔ GRID MAPPING
========================================================= */
 
institution_mapping AS (
 
SELECT DISTINCT
    bp_id,
    BP_Full_Name,
    grid_id
 
FROM

{{ref('stg_nature_jrnl_usage_denials') }}
 
)
 
SELECT
 
    m.grid_id,
    m.bp_id,
    m.BP_Full_Name,
 
    COALESCE(p.total_articles_published,0) AS total_articles_published
 
FROM institution_mapping m
 
LEFT JOIN publication_counts p
ON m.grid_id = p.grid_id
 
ORDER BY
    total_articles_published DESC,
    m.BP_Full_Name