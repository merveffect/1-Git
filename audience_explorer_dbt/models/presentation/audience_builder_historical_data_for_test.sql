{{
config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    on_schema_change='append_new_columns',
    description='Historical data for audience builder big with daily change detection and timestamps',
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
),

{% if is_incremental() %}

-- Get the latest state for each segment from previous days
last_state as (
    select 
        * except(rn)
    from (
        select
            *,
            row_number() over (partition by canonical_segment_id order by ingestion_timestamp desc) as rn
        from {{ this }}
        where ingestion_timestamp < date_trunc(current_date(), day)
    )
    where rn = 1
),

-- Find segments that are new or have changed
changed_segments as (
    select
        current.*
    from current_data current
    left join last_state latest
        on current.canonical_segment_id = latest.canonical_segment_id
    where latest.canonical_segment_id is null
        or (current.* except(ingestion_timestamp)) != (latest.* except(ingestion_timestamp))
)

select * from changed_segments

{% else %}

select * from current_data

{% endif %}