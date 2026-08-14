{{config(
  materialized = 'table'
)
}}
 
/* =========================================================
   SDG PUBLICATIONS BY INSTITUTE (2022+)
========================================================= */
 
WITH base AS (
 
SELECT DISTINCT
 
    t.id AS pub_id,
 
    a_grid AS grid_id
 
FROM
 {{source('publications', 'publications') }} t

LEFT JOIN UNNEST(t.authors) a
LEFT JOIN UNNEST(a.grid_ids) a_grid
LEFT JOIN UNNEST(t.category_sdg.full) sdg
 
WHERE
    t.year >= 2022
    AND LOWER(t.type) = 'article'
    AND LENGTH(a_grid) > 0
    AND LENGTH(sdg.name) > 0      -- publication has at least one SDG
 
),
 
/* =========================================================
   COUNT SDG PUBLICATIONS
========================================================= */
 
sdg_counts AS (
 
SELECT
 
    grid_id,
 
    COUNT(DISTINCT pub_id) AS total_sdg_publications
 
FROM base
 
GROUP BY
    grid_id
 
),
 
/* =========================================================
   BPID MAPPING
========================================================= */
 
institution_mapping AS (
 
SELECT DISTINCT
 
    bp_id,
    BP_Full_Name,
    grid_id
 
FROM

{{ref('stg_nature_jrnl_usage_denials') }}
 

WHERE
    LENGTH(bp_id) > 0
    AND LENGTH(grid_id) > 0
 
)
 
SELECT
 
    m.grid_id,
 
    m.bp_id,
 
    m.BP_Full_Name,
 
    COALESCE(s.total_sdg_publications,0) AS total_sdg_publications
 
FROM institution_mapping m
 
LEFT JOIN sdg_counts s
 
ON m.grid_id = s.grid_id
 
ORDER BY
    total_sdg_publications DESC,
    m.BP_Full_Name