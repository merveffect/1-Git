{{ config(
  materialized='incremental',
  incremental_strategy='insert_overwrite',
  partition_by={
    "field": "evt_date",
    "data_type": "date",
    "granularity": "day"
    },
  cluster_by=["page_path", "collection_id"]
) }}

WITH pageview AS (
  SELECT *
  FROM {{ ref('stg_collections_ga_pageview') }}
  {% if is_incremental() %}
    WHERE evt_date >= (
        SELECT DATE_SUB(MAX(evt_date), INTERVAL 3 DAY)
        FROM {{ this }}
    )
    AND evt_date < DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}
),

gsheet AS (
  SELECT DISTINCT page_path, collection_id
  FROM {{ ref('stg_gsheet_wf_metadata') }}
  WHERE NULLIF(TRIM(collection_id), '') IS NOT NULL
),

workfront AS (
  SELECT *
  FROM {{ ref('raw_workfront_metadata') }}
  QUALIFY ROW_NUMBER() OVER (
      PARTITION BY collection_id
      ORDER BY
          (NULLIF(TRIM(collection_title), '') IS NOT NULL AND collection_title != collection_id) DESC,
          (NULLIF(TRIM(collection_title), '') IS NOT NULL) DESC
  ) = 1
),

-- GA4 collection_id matches gsheet (on collection_id + page_path) or workfront (on collection_id)
cid_matched AS (
  SELECT pv.page_path, pv.evt_date, pv.collection_id, pv.pageview_data
  FROM pageview pv
  LEFT JOIN gsheet gs
    ON pv.collection_id = gs.collection_id AND pv.page_path = gs.page_path
  LEFT JOIN workfront wf
    ON pv.collection_id = wf.collection_id
  WHERE gs.collection_id IS NOT NULL OR wf.collection_id IS NOT NULL
),

-- (page_path, evt_date) pairs where at least one collection_id matched gsheet or workfront
pages_with_match AS (
  SELECT DISTINCT page_path, evt_date FROM cid_matched
),

-- All (page_path, evt_date, collection_id) triples from GA4 that did NOT match gsheet or workfront
all_unmatched AS (
  SELECT DISTINCT pv.page_path, pv.evt_date, pv.collection_id
  FROM pageview pv
  LEFT JOIN cid_matched cm
    ON pv.page_path = cm.page_path
    AND pv.evt_date = cm.evt_date
    AND pv.collection_id = cm.collection_id
  WHERE cm.collection_id IS NULL
),

-- Fallback: for pages with ZERO matched collection_ids, assign gsheet collection_id via page_path
-- and re-aggregate all pageview_data for that (page_path, evt_date) under the gsheet collection_id
fallback AS (
  SELECT
    u.page_path,
    u.evt_date,
    gs.collection_id,
    pv_agg.pageview_data
  FROM (SELECT DISTINCT page_path, evt_date FROM all_unmatched) u
  LEFT JOIN pages_with_match pm ON u.page_path = pm.page_path AND u.evt_date = pm.evt_date
  INNER JOIN gsheet gs ON u.page_path = gs.page_path
  INNER JOIN (
    SELECT page_path, evt_date, ARRAY_CONCAT_AGG(pageview_data) AS pageview_data
    FROM pageview
    GROUP BY page_path, evt_date
  ) pv_agg ON u.page_path = pv_agg.page_path AND u.evt_date = pv_agg.evt_date
  WHERE pm.page_path IS NULL  -- only pages where NO collection_id matched at all
),

-- Unmatched collection_ids from pages that DO have other matched collection_ids
-- These are preserved as-is with their own per-collection_id pageview_data
partial_unmatched AS (
  SELECT u.page_path, u.evt_date, u.collection_id, pv.pageview_data
  FROM all_unmatched u
  INNER JOIN pages_with_match pm ON u.page_path = pm.page_path AND u.evt_date = pm.evt_date
  INNER JOIN pageview pv
    ON u.page_path = pv.page_path
    AND u.evt_date = pv.evt_date
    AND u.collection_id = pv.collection_id
),

scope AS (
  SELECT page_path, evt_date, collection_id, pageview_data FROM cid_matched
  UNION ALL
  SELECT page_path, evt_date, collection_id, pageview_data FROM fallback
  UNION ALL
  SELECT page_path, evt_date, collection_id, pageview_data FROM partial_unmatched
)

SELECT
  b.evt_date,
  b.page_path,
  b.collection_id,
  a.event_data,
  b.pageview_data,
  c.user_data,
  d.collection_title AS collection_name,
  d.full_article_url,
  d.page_title,
  e.workfront_project_id AS wf_project_id,
  e.workfront_project_name AS wf_project_name,
  e.page_url AS wf_page_url,
  e.sponsor_feature_url AS wf_sponsor_feature_url,
  e.client_name AS wf_client_name,
  e.date_range_start AS wf_date_range_start,
  e.collection_title AS wf_collection_title
FROM scope AS b
LEFT JOIN {{ ref('stg_collections_ga_events') }} AS a
  ON b.evt_date = a.evt_date AND b.page_path = a.page_path
LEFT JOIN {{ ref('stg_collections_ga_users') }} AS c
  ON b.evt_date = c.evt_date AND b.page_path = c.page_path
LEFT JOIN {{ ref('stg_gsheet_wf_metadata') }} AS d
  ON b.collection_id = d.collection_id AND b.page_path = d.page_path
LEFT JOIN workfront AS e
  ON b.collection_id = e.collection_id
