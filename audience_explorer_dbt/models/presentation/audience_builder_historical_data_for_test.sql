{{
config(
    materialized='incremental',
    on_schema_change='append_new_columns',
    description='This table captures the historical data for audience builder big based on the changes. If a segment changes, a new row is added. It is used for testing purposes only.',
    partition_by={
        'field': 'ingestion_timestamp', 
        'data_type': 'timestamp', 
        'granularity': 'day'
    }
)
}}

with current_data as (
    select
        *,
        current_timestamp() as ingestion_timestamp
    from {{ ref('audience_builder_big') }}
)

{% if is_incremental() %}

, last_snapshot as (
    select * from (
        select
            *,
            row_number() over (partition by canonical_segment_id order by ingestion_timestamp desc) as rn
        from {{ this }}
        where ingestion_timestamp >= timestamp_sub(current_timestamp(), interval 3 day)
    )
    where rn = 1
)

select c.*
from current_data c
left join last_snapshot l 
    on c.canonical_segment_id = l.canonical_segment_id
where l.canonical_segment_id is null 
   or exists (
       select c.* except(ingestion_timestamp)
       except distinct
       select l.* except(ingestion_timestamp, rn)
   )

{% else %}

select * from current_data

{% endif %}