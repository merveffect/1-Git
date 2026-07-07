{{ config(
  materialized='incremental',
  incremental_strategy='insert_overwrite',
  partition_by={
    "field": "evt_date",
    "data_type": "date",
    "granularity": "day"
  },
  cluster_by=["page_path"]
) }}

WITH gsheet_null_cid AS (
  -- All page_paths from gsheet where collection_id is empty or NULL
  SELECT *
  FROM {{ ref('stg_gsheet_wf_metadata') }}
  WHERE NULLIF(TRIM(collection_id), '') IS NULL
),

pageview AS (
  SELECT page_path, evt_date, ARRAY_CONCAT_AGG(pageview_data) AS pageview_data
  FROM {{ ref('stg_collections_ga_pageview_no_collection_id') }}
  {% if is_incremental() %}
    WHERE evt_date >= (
        SELECT DATE_SUB(MAX(evt_date), INTERVAL 3 DAY)
        FROM {{ this }}
    )
    AND evt_date < DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}
  GROUP BY page_path, evt_date
),

workfront AS (
  -- Since there is no collection_id, workfront is joined via page_url (if available)
  SELECT *
  FROM {{ ref('raw_workfront_metadata') }}
  QUALIFY ROW_NUMBER() OVER (
      PARTITION BY page_url
      ORDER BY
          (NULLIF(TRIM(collection_title), '') IS NOT NULL) DESC
  ) = 1
)

-- Main join (gsheet-centric)
SELECT
  pv.evt_date,
  gs.page_path,
  gs.collection_id AS gsheet_collection_id, -- Will always be NULL in this model by design
  gs.collection_title AS gsheet_collection_name,
  gs.full_article_url,
  gs.page_title,
  
  -- GA4 metrics
  pv.pageview_data,
  a.event_data,
  c.user_data,
  
  -- Workfront info (matched via page URL)
  wf.workfront_project_id AS wf_project_id,
  wf.workfront_project_name AS wf_project_name,
  wf.page_url AS wf_page_url,
  wf.client_name AS wf_client_name
FROM gsheet_null_cid gs
-- Drive date-level granularity and avoid row explosion by anchoring on pageview first
INNER JOIN pageview pv 
  ON gs.page_path = pv.page_path
LEFT JOIN {{ ref('stg_collections_ga_events') }} AS a
  ON pv.evt_date = a.evt_date AND gs.page_path = a.page_path
LEFT JOIN {{ ref('stg_collections_ga_users') }} AS c
  ON pv.evt_date = c.evt_date AND gs.page_path = c.page_path
LEFT JOIN workfront AS wf
  ON gs.full_article_url = wf.page_url -- Adjust to gs.page_path if mapping requires it
