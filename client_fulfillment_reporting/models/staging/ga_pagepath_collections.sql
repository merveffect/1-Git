{{ config(materialized='table') }}

SELECT
    page_path,
    ARRAY_AGG(DISTINCT col_id) AS ga_collection_ids
FROM (
    SELECT
        page_path,
        TRIM(col) AS col_id
    FROM {{ ref('stg_collections_ga_pageview') }},
    UNNEST(pageview_data) AS pv,
    UNNEST(SPLIT(pv.collection_id, ';')) AS col
    WHERE
        pv.collection_id IS NOT NULL 
        AND LOWER(TRIM(col)) NOT IN ('false', 'null', '', 'none') --
)
GROUP BY 1