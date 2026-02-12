
WITH max_pageview_title AS (
    SELECT page_path, pageTitle AS max_pageview_title
    FROM (
      SELECT page_path, pageTitle,
        ROW_NUMBER() OVER (PARTITION BY page_path ORDER BY pageview_count DESC) AS rn
      FROM {{ref('raw_ga4_base_pageview_data') }}
      WHERE collection_id IS NOT NULL AND collection_id != "false"
    )
    WHERE rn = 1
),

reference_table AS (
    SELECT
      p.page_path,
      -- fix= split the collection ids
      TRIM(split_id) as collection_id,
      COALESCE(m.max_pageview_title, p.pageTitle) AS pageTitle
    FROM (
      SELECT page_path, collection_id, pageTitle,
        ROW_NUMBER() OVER (PARTITION BY page_path ORDER BY evt_date DESC) AS rn
      FROM {{ref('raw_ga4_base_pageview_data') }}
      WHERE collection_id IS NOT NULL AND collection_id != "false"
    ) p
    -- UNNEST ile ';' içeren ID'leri satırlara döküyoruz
    CROSS JOIN UNNEST(SPLIT(p.collection_id, ';')) AS split_id
    LEFT JOIN max_pageview_title m ON p.page_path = m.page_path
    WHERE p.rn = 1
),

filtered_reference AS (
    SELECT r.page_path, r.collection_id, r.pageTitle, w.collection_title
    FROM reference_table r
    INNER JOIN {{ref('raw_workfront_metadata') }} w
    ON r.collection_id = w.collection_id
),

gsheet_metadata AS (
    SELECT DISTINCT page_path, page_title, collection_id, collection_name, full_article_url
    FROM {{ref('raw_bc_collections_article_google_sheets_metadata') }}
)

SELECT
  COALESCE(f.page_path, g.page_path) AS page_path,
  COALESCE(f.collection_id, g.collection_id) AS collection_id,
  COALESCE(g.page_title, f.pageTitle) AS page_title,
  COALESCE(f.collection_title, g.collection_name) AS collection_title,
  g.full_article_url as full_article_url
FROM filtered_reference f
FULL OUTER JOIN gsheet_metadata g ON f.page_path = g.page_path
WHERE (f.page_path IS NULL OR (f.page_path NOT LIKE '%/figures/%' AND f.page_path NOT LIKE '%/tables/%' AND f.page_path NOT LIKE '%/schemes/%'))
ORDER BY page_path