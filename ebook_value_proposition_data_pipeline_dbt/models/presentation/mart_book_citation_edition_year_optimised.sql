{{ config(
    materialized = "table",
    partition_by = {
        "field": "citation_year",
        "data_type": "int64",
        "range": {
            "start": 2000,
            "end": 2030,
            "interval": 1
    }
    },
    cluster_by = ["Bk_Subj_Coll", "edition_year"]
) }}


-- 🔹 1. DOI mapping (unchanged)
WITH doi_map AS (
  SELECT
    LOWER(TRIM(Item_DOI)) AS doi_norm,
    ANY_VALUE(Bk_Subj_Coll) AS Bk_Subj_Coll
  FROM {{ref('stg_doi_ebookpackage')}}
  WHERE Item_DOI IS NOT NULL
  GROUP BY doi_norm
),

-- 🔹 2. USE OPTIMISED TABLE (KEY CHANGE ✅)
base_pubs AS (
  SELECT
    opt.grid_id,
    opt.pub_id,
    opt.pub_year,
    opt.Bk_Subj_Coll
  FROM {{ref('mart_institution_ebook_publications_optimised')}} opt
  WHERE
    opt.pub_year >= 2005
    AND opt.publisher_name = 'Springer Nature'
    AND opt.publication_type IN ('monograph', 'proceeding', 'chapter')
),

-- 🔹 3. Extract citations (NO LOSS ✅)
citation_fact AS (
  SELECT
    bp.*,
    citation.id AS citing_pub_id,
    citation.year AS citation_year
  FROM base_pubs bp
  LEFT JOIN {{source('data_analytics_eu', 'publications')}} AS p
    ON p.id = bp.pub_id
  LEFT JOIN UNNEST(p.citations) AS citation
  WHERE citation.year IS NOT NULL
)

-- 🔹 4. Final enrichment
SELECT
  -- ✅ MATCHES OPTIMISED TABLE STRUCTURE
  cf.grid_id,
  cf.pub_id,
 
  cf.pub_year as Edition_year,
  cf.Bk_Subj_Coll,
  -- citation info
  cf.citing_pub_id,
  cf.citation_year,

  -- citing publication enrichment

  ro AS citing_grid_id

FROM citation_fact cf

LEFT JOIN {{source('data_analytics_eu', 'publications')}} cp
  ON cp.id = cf.citing_pub_id

LEFT JOIN UNNEST(cp.research_orgs) AS ro

LEFT JOIN {{source('data_analytics_eu', 'grid')}} g
  ON g.id = ro
