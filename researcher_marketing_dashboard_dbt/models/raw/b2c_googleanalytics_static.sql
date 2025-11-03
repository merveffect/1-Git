{{ config(
    materialized='incremental',
    partition_by={'field': 'date', 'data_type': 'date'},
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"]
)}}

select
    *
from {{ source('ga4_ria_researcher_report','googleanalytics') }}

{% if is_incremental() %}
  {% set backfill_start = var("backfill_start_date", none) %}
  {% set backfill_end = var("backfill_end_date", none) %}
  WHERE date BETWEEN 
    {% if backfill_start %}
      DATE('{{ backfill_start }}')
    {% else %}
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% endif %}
    AND
    {% if backfill_end %}
      DATE('{{ backfill_end }}')
    {% else %}
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% endif %}
{% else %}
  WHERE date BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                  AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}


