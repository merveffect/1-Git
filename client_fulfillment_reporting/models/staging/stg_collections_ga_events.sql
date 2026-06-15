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

SELECT
  page_path,
  evt_date,
  ARRAY_AGG(STRUCT(event_name, event_category, event_action, event_label, percent_scrolled, event_count, country, device_category, link_url, aq_source, link_text)) AS event_data
FROM
  {{ ref('raw_ga4_base_event_data') }}


{% if is_incremental() %}
    -- 1. Start: Look back 3 days from the current max date to catch late-arriving data/gaps
    WHERE evt_date >= (
        SELECT DATE_SUB(MAX(evt_date), INTERVAL 3 DAY) 
        FROM {{ this }}
    )
    -- 2. End: Exclude the last 2 days (Today and Yesterday) to ensure data is fully processed in GA4
    AND evt_date < DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}

GROUP BY
  page_path,
  evt_date




