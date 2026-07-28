{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
        "field": "partition_date",
        "data_type": "date",
        "granularity": "day"
    }
)
}}

select *,
date(_PARTITIONTIME) as partition_date
from {{ source('cdp_profile_sync', 'identifies') }}

{% if is_incremental() %}
    where date(_PARTITIONTIME) >= date_sub(current_date(), interval 3 day)
{% endif %}