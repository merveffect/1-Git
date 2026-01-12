{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={"field": "evt_date", "data_type": "date"},
    cluster_by=["page_path"]
) }}

WITH a AS (
  SELECT *
  FROM {{ ref('stg_collections_ga_events') }}
  {% if is_incremental() %}
    WHERE evt_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}
),

b AS (
  SELECT *
  FROM {{ ref('stg_collections_ga_pageview') }}
  {% if is_incremental() %}
    WHERE evt_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}
),

c AS (
  SELECT *
  FROM {{ ref('stg_collections_ga_users') }}
  {% if is_incremental() %}
    WHERE evt_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}
)

SELECT
  COALESCE(a.evt_date, b.evt_date, c.evt_date) AS evt_date,
  COALESCE(a.page_path, b.page_path, c.page_path) AS page_path,

  -- GA4 behaviour
  a.event_data,
  b.pageview_data,
  c.user_data,

  -- GA4 → Collection matching
  g.ga_collection_ids,

  -- Collection / article metadata
  d.collection_title AS collection_name,
  d.full_article_url,
  d.page_title,

  -- Workfront enrichment
  e.workfront_project_id AS wf_project_id,
  e.workfront_project_name AS wf_project_name,
  e.page_url AS wf_page_url,
  e.sponsor_feature_url AS wf_sponsor_feature_url,
  e.client_name AS wf_client_name,
  e.date_range_start AS wf_date_range_start,
  e.collection_title AS wf_collection_title

FROM a
FULL JOIN b
  USING (evt_date, page_path)
FULL JOIN c
  USING (evt_date, page_path)

/* Sheet enrichment */
LEFT JOIN {{ ref('stg_gsheet_wf_metadata') }} AS d
  USING (page_path)

/* GA4 → Workfront collection matching (ARRAY-based) */
LEFT JOIN {{ ref('ga_pagepath_collections') }} AS g
  ON g.page_path = COALESCE(a.page_path, b.page_path, c.page_path)

LEFT JOIN {{ ref('raw_workfront_metadata') }} AS e
  ON e.collection_id IN UNNEST(g.ga_collection_ids)

/* Business rule: Sheet OR Workfront */
WHERE
  d.page_path IS NOT NULL
  OR e.collection_id IS NOT NULL

