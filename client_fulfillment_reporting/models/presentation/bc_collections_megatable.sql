{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={"field": "evt_date", "data_type": "date"},
    cluster_by=["page_path"]
) }}

-- Array AGG each so that they can be coalesced in next step
-- Agg for pageviews
WITH array_agg_pv AS (
  SELECT
    page_path,
    evt_date,
    ARRAY_AGG(STRUCT(
      total_engaged_ms,
      pageview_count,
      session_count,
      country,
      device_category,
      aq_source,
      aq_source_sess,
      collection_id,
      pageTitle
    )) AS pageview_data
  FROM {{ref(stg_collections_ga_pageview)}}
  {% if is_incremental() %}
    WHERE evt_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}
  GROUP BY
    page_path,
    evt_date
),

-- Agg for events
array_agg_events AS (
  SELECT
    page_path,
    evt_date,
    ARRAY_AGG(STRUCT(
      event_name,
      event_category,
      event_action,
      event_label,
      percent_scrolled,
      event_count,
      country,
      device_category,
      link_url,
      aq_source,
      link_text
    )) AS event_data
  FROM {{ref(stg_collections_ga_events)}}
  {% if is_incremental() %}
    WHERE evt_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}
  {% if is_incremental() %}
    WHERE evt_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}
  GROUP BY
    page_path,
    evt_date
),

-- Agg for users
array_agg_users AS (
  SELECT
    page_path,
    evt_date,
    ARRAY_AGG(STRUCT(
      user_pseudo_id
    )) AS user_data
  FROM {{ref(stg_collections_ga_users)}}
  {% if is_incremental() %}
    WHERE evt_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}
  GROUP BY
    page_path,
    evt_date
)

-- Combine everything into one table with COALESCE
SELECT
  COALESCE(a.evt_date, b.evt_date, c.evt_date) AS evt_date,
  COALESCE(a.page_path, b.page_path, c.page_path) AS page_path,
  a.event_data,
  b.pageview_data,
  c.user_data,
  d.collection_id,
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
FROM array_agg_events AS a
FULL JOIN array_agg_pv AS b
  USING (evt_date, page_path)
FULL JOIN array_agg_users AS c
  USING (evt_date, page_path)
INNER JOIN {{ref(stg_gsheet_wf_metadata)}} AS d
  USING (page_path)
LEFT JOIN {{ref(raw_workfront_metadata)}} AS e
  USING (collection_id)
