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
    page_path,
    evt_date,
    collection_id,
    ARRAY_AGG(
      STRUCT(
        total_engaged_ms,
        pageview_count,
        session_count,
        country,
        device_category,
        aq_source_sess,
        aq_medium_sess,
        pageTitle,
        BPID,
        bpid_delimit,
        aq_campaign_name_sess,
        mps_partner_id,
        type_description,
        customer_type
      )
    ) AS pageview_data
  FROM {{ ref('stg_ga4_exploded_collection_ids') }}


{% if is_incremental() %}
    -- 1. Start: Look back 3 days from the current max date to catch late-arriving data/gaps
    WHERE evt_date >= (
        SELECT DATE_SUB(MAX(evt_date), INTERVAL 3 DAY) 
        FROM {{ this }}
    )
    -- 2. End: Exclude the last 2 days (Today and Yesterday) to ensure data is fully processed in GA4
    AND evt_date < DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  {% endif %}

  GROUP BY page_path, evt_date, collection_id