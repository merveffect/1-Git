{{ config(
materialized='incremental',
incremental_strategy='insert_overwrite',
on_schema_change='sync_all_columns',
partition_by={
"field": "evt_date",
"data_type": "date",
"granularity": "day"
},
cluster_by=["page_path"]
) }}

SELECT
        evt_date,
        page_path,
        total_engaged_ms,
        pageview_count,
        session_count,
        country,
        device_category,
        aq_source,
        aq_source_sess as sess_source,
        collection_id,
        pageTitle
    FROM {{ source('rm_bc_client_fulfillment_reporting', 'bc_all_ga4_base_pageview_data') }}


{% if is_incremental() %}
    -- 1. Start: Look back 3 days from the current max date to catch late-arriving data/gaps
    WHERE evt_date >= (
        SELECT DATE_SUB(MAX(evt_date), INTERVAL 3 DAY) 
        FROM {{ this }}
    )
    -- 2. End: Exclude the last 2 days (Today and Yesterday) to ensure data is fully processed in GA4
    AND evt_date < DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}