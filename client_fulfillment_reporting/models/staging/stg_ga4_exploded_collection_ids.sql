SELECT
  * EXCEPT(collection_id),
  TRIM(cid) AS collection_id
FROM {{ ref('raw_ga4_base_pageview_data') }}
LEFT JOIN UNNEST(SPLIT(collection_id, ';')) AS cid ON TRUE