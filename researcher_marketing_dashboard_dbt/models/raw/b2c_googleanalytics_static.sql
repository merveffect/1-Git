{{ config(
    materialized='table',
    partition_by={'field': 'date', 'data_type': 'date'}
)}}

select
    *
from {{ source('ga4_ria_researcher_report','googleanalytics') }}

{% if is_incremental() %}
  WHERE date BETWEEN 
        COALESCE(
          DATE('{{ var("backfill_start_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
        AND
        COALESCE(
          DATE('{{ var("backfill_end_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
{% else %}
  WHERE date BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                  AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}
