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
    where date(_PARTITIONTIME) >= timestamp_sub(timestamp_trunc(current_timestamp(), day), interval 3 day
    )

{% endif %}