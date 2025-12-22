{{ config(materialized='table') }}

SELECT
  page_path,
  ARRAY_AGG(DISTINCT collection_id IGNORE NULLS) AS collection_ids,
  ARRAY_AGG(DISTINCT collection_title IGNORE NULLS) AS collection_titles
FROM {{ ref('stg_gsheet_wf_metadata') }}
GROUP BY page_path
