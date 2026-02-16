{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            "field": "event_date",
            "data_type": "date",
            "granularity": "day"
        },
        tags=['staging', 'incremental']
    )
}}

SELECT
    cte1.* EXCEPT(parts),
    CONCAT( parts[SAFE_OFFSET(ARRAY_LENGTH(parts) - 2)], '/', parts[SAFE_OFFSET(ARRAY_LENGTH(parts) - 1)] ) AS regex_end
  FROM
    {{ref('cte1')}} cte1

{% if execute %}
    {% if is_incremental() %}
        WHERE cte1.event_date = DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% else %}
        WHERE cte1.event_date <= DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% endif %}
{% endif %}