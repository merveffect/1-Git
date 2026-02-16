{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            "field": "event_date",
            "data_type": "date",
            "granularity": "day"
        },
        tags=['raw', 'ga4', 'incremental']
    )
}}

select * from 
{{source('b2b_e2e_report', 'b2b_ga4_test_static')}}

{% if execute %}
    {% if is_incremental() %}
        WHERE event_date = DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% else %}
        WHERE event_date <= DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% endif %}
{% endif %}
