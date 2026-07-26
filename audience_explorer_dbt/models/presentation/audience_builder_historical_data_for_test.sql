{{
config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
        'field': 'ingestion_timestamp',
        'data_type': 'timestamp',
        'granularity': 'day'
    },
    cluster_by=['canonical_segment_id'],
    tags=['daily', 'historical']
)
}}

with normalized_current as (

    select
        src.* replace(
            cast(awr_click_submit_manuscript_on_link_springer_com as string)
            as awr_click_submit_manuscript_on_link_springer_com
        )
    from {{ ref('audience_builder_big') }} src

),

current_data as (

    select
        src.*,
        current_timestamp() as ingestion_timestamp,
        farm_fingerprint(to_json_string((select as struct src.*))) as row_hash
    from normalized_current src

)

{% if is_incremental() %}

,last_state as (

    select * except(rn)
    from (
        select
            t.*,
            row_number() over (
                partition by canonical_segment_id
                order by ingestion_timestamp desc
            ) as rn
        from {{ this }} t
        where date(ingestion_timestamp) < current_date()
    )
    where rn = 1

),

last_state_hashed as (

    select
        ls.*,
        farm_fingerprint(
            to_json_string(
                (select as struct ls.* except(ingestion_timestamp))
            )
        ) as row_hash
    from last_state ls

),

changed_rows as (

    select
        c.* except(row_hash)
    from current_data c
    left join last_state_hashed l
        on c.canonical_segment_id = l.canonical_segment_id
    where l.canonical_segment_id is null
       or c.row_hash != l.row_hash

)

select * from changed_rows

{% else %}

select * except(row_hash) from current_data

{% endif %}