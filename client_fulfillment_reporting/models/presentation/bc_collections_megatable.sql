{{ config(
    materialized='table',
    cluster_by=["page_path"]
) }}

/* 1. CTE: Events - Orijinal mantıkla gruplanmış */
WITH array_agg_events AS (
  SELECT 
    page_path, 
    evt_date, 
    ARRAY_AGG(STRUCT(event_name, event_category, event_action, event_label, percent_scrolled, event_count, country, device_category, link_url, aq_source, link_text)) AS event_data 
  FROM {{ ref('stg_collections_ga_events_raw') }} -- Ham veriye en yakın staging modelin
  GROUP BY page_path, evt_date
),

/* 2. CTE: Pageviews - Orijinal mantıkla gruplanmış */
WITH array_agg_pv AS (
  SELECT 
    page_path, 
    evt_date, 
    ARRAY_AGG(STRUCT(total_engaged_ms, pageview_count, session_count, country, device_category, aq_source, aq_source_sess, collection_id, pageTitle)) AS pageview_data 
  FROM {{ ref('stg_collections_ga_pageview_raw') }} 
  GROUP BY page_path, evt_date
),

/* 3. CTE: Users - Orijinal mantıkla gruplanmış */
WITH array_agg_users AS (
  SELECT 
    page_path, 
    evt_date, 
    ARRAY_AGG(STRUCT(user_pseudo_id)) AS user_data 
  FROM {{ ref('stg_collections_ga_users_raw') }} -- Ham veriye en yakın staging modelin
  GROUP BY page_path, evt_date
)

/* FİNAL BİRLEŞTİRME */
SELECT 
  COALESCE(a.evt_date, b.evt_date, c.evt_date) as evt_date, 
  COALESCE(a.page_path, b.page_path, c.page_path) as page_path, 
  a.event_data, 
  b.pageview_data, 
  c.user_data, 
  d.collection_id, 
  d.collection_title as collection_name, 
  d.full_article_url, 
  d.page_title, 
  e.workfront_project_id as wf_project_id, 
  e.workfront_project_name as wf_project_name, 
  e.page_url as wf_page_url, 
  e.sponsor_feature_url as wf_sponsor_feature_url, 
  e.client_name as wf_client_name, 
  e.date_range_start as wf_date_range_start, 
  e.collection_title as wf_collection_title 

FROM array_agg_events AS a 
FULL JOIN array_agg_pv AS b USING(evt_date, page_path) 
FULL JOIN array_agg_users AS c USING(evt_date, page_path) 

/* Orijinal koddaki gibi INNER JOIN - Bu GSheet'te olmayanları eler */
INNER JOIN {{ ref('stg_gsheet_wf_metadata') }} AS d USING (page_path) 

/* Orijinal koddaki gibi LEFT JOIN */
LEFT JOIN {{ ref('raw_workfront_metadata') }} AS e USING (collection_id)