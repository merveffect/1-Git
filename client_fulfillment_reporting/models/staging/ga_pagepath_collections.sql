{{ config(materialized='table') }}

SELECT
  page_path,
  ARRAY_AGG(DISTINCT col_id) AS ga_collection_ids
FROM (
  SELECT
    page_path,
    TRIM(col) AS col_id
  FROM {{ ref('raw_ga4_base_pageview_data') }},
  UNNEST(SPLIT(collection_id, ';')) AS col
  WHERE
    collection_id IS NOT NULL
    AND LOWER(TRIM(col)) NOT IN ('false', 'null', '')
)
GROUP BY page_path
