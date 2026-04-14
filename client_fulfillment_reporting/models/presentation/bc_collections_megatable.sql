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

SELECT
  COALESCE(a.evt_date, b.evt_date, c.evt_date) AS evt_date,
  COALESCE(a.page_path, b.page_path, c.page_path) AS page_path,
  b.collection_id, -- exploded ids 

-- Metrics
  a.event_data,
  b.pageview_data,
  c.user_data,

-- Gsheet metadata
  d.collection_title AS collection_name,
  d.full_article_url,
  d.page_title,

-- Workfront metadata
  e.workfront_project_id AS wf_project_id,
  e.workfront_project_name AS wf_project_name,
  e.page_url AS wf_page_url,
  e.sponsor_feature_url AS wf_sponsor_feature_url,
  e.client_name AS wf_client_name,
  e.date_range_start AS wf_date_range_start,
  e.collection_title AS wf_collection_title

 FROM {{ref('stg_collections_ga_pageview')}} AS b
LEFT JOIN {{ref('stg_collections_ga_events')}} AS a

ON b.evt_date = a.evt_date
AND b.page_path = a.page_path
LEFT JOIN {{ref('stg_collections_ga_users')}} AS c
ON b.evt_date = c.evt_date
AND b.page_path = c.page_path

INNER JOIN {{ref('stg_gsheet_wf_metadata')}} AS d
ON b.collection_id = d.collection_id
AND b.page_path = d.page_path

LEFT JOIN {{ref('raw_workfront_metadata')}} AS e
ON b.collection_id = e.collection_id


{% if is_incremental() %}
    -- 1. Start: Look back 3 days from the current max date to catch late-arriving data/gaps
    WHERE b.evt_date >= (
        SELECT DATE_SUB(MAX(evt_date), INTERVAL 3 DAY) 
        FROM {{ this }}
    )
    -- 2. End: Exclude the last 2 days (Today and Yesterday) to ensure data is fully processed in GA4
    AND b.evt_date < DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}