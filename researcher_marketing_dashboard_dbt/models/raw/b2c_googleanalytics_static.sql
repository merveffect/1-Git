{{
  config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"],
    partition_by={
      'field': 'date', 
      'data_type': 'date'
    }
  )
}}

select
    *
from {{ source('ga4_ria_researcher_report','googleanalytics') }}

{{ incremental_date_filter('date') }}




