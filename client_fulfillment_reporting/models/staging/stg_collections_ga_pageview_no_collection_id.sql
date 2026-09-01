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
    ARRAY_AGG(
      STRUCT(
        total_engaged_ms,
        pageview_count,
        session_count,
        country,
        device_category,
        aq_source,
        sess_source,
        pageTitle
      )
    ) AS pageview_data
  FROM {{ ref('raw_ga4_base_pageview_data') }}

  WHERE NULLIF(TRIM(collection_id), '') IS NULL

{% if is_incremental() %}
    AND evt_date >= (
        SELECT DATE_SUB(MAX(evt_date), INTERVAL 3 DAY)
        FROM {{ this }}
    )
    AND evt_date < DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
{% endif %}

  GROUP BY page_path, evt_date
