{{config(
  materialized = 'table'
)
}}

/* =========================
1️⃣ Publications (Lean)
========================= */

WITH pubs AS (
  SELECT
    t.id AS pub_id,
    t.year AS pub_year,
    DATE(t.year, 1, 1) AS pub_date,

    t.doi,
    LOWER(t.type) AS publication_type,

   Lower(t.journal.title) AS journal_title,
     REPLACE(t.journal.id, 'jour.', '') AS journal_id,

    t.publisher.name AS publisher_name,

    research_orgs_grids AS grid_id

  FROM 
  
  {{source('publications', 'publications') }} AS t

  LEFT JOIN UNNEST(t.research_orgs) research_orgs_grids

  WHERE
    t.year >= 2017                      -- 🔥 adjust if truly 2027
    AND LOWER(t.type) = 'article'
    AND t.publisher.name = 'Springer Nature'
    AND t.doi IS NOT NULL
    AND t.journal.id IS NOT NULL        -- 🔥 ensures journal only
),

/* =========================
2️⃣ Journal Imprint (ONLY needed enrichment)
========================= */

journal_meta AS (
  SELECT
    journal_id,
    journal_Title as jrnl_title,

  FROM 

  {{ref('stg_jrnl_metadata') }}
 
  GROUP BY ALL),

/* =========================
3️⃣ BPID mapping (ONLY from usage table)
========================= */

bpid_map AS (
  SELECT DISTINCT
    grid_id,
    bp_id,
    BP_Full_Name
  FROM

  {{ref('stg_nature_jrnl_usage_denials') }}
  
)

/* =========================
4️⃣ Final Output
========================= */

SELECT
  p.pub_id,
  p.pub_year,
  p.pub_date,
  p.doi,
  p.journal_title,
  p.journal_id,
  p.grid_id,
  b.bp_id,
  b.BP_Full_Name

FROM pubs p

LEFT JOIN journal_meta j
  ON p.journal_title = j.Jrnl_Title    -- 🔥 clean join

LEFT JOIN bpid_map b
  ON p.grid_id = b.grid_id


