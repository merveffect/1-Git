{{ config(
materialized='table',
partition_by={
"field": "evt_date",
"data_type": "date",
"granularity": "day"
},
cluster_by=["page_path"]
) }}

SELECT
    page_path,
    evt_date,
    ARRAY_AGG(
      STRUCT(
        total_engaged_ms,
        pageview_count,
        session_count,
        country,
        device_category,
        aq_source,
        aq_source_sess,
        collection_id,
        pageTitle
      )
    ) AS pageview_data
  FROM {{ ref('raw_ga4_base_pageview_data') }}
  GROUP BY page_path, evt_date