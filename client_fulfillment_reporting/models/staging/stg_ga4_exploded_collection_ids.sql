{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    on_schema_change='sync_all_columns',
    partition_by={
        "field": "evt_date",
        "data_type": "date",
        "granularity": "day"
    },
    cluster_by=["page_path", "collection_id"]
) }}

SELECT
    * EXCEPT(collection_id),
    TRIM(cid) AS collection_id
FROM {{ ref('raw_ga4_base_pageview_data') }}
LEFT JOIN UNNEST(SPLIT(collection_id, ';')) AS cid ON TRUE
WHERE NULLIF(TRIM(cid), '') IS NOT NULL

{% if is_incremental() %}
    AND evt_date >= (
        SELECT DATE_SUB(MAX(evt_date), INTERVAL 3 DAY)
        FROM {{ this }}
    )
    AND evt_date < DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
{% endif %}
