-- Phase 1B identity: GA4 user_pseudo_id -> Braze CEP id (Colab braze_cep_ids).
-- Extracts the cep_id user-property from GA4 raw events for the processing window.
-- Incremental insert_overwrite on mis_month (same idempotency note as int_ga4_sap_ids).

{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={'field': 'mis_month', 'data_type': 'date', 'granularity': 'month'},
        on_schema_change='sync_all_columns',
    )
}}

with events as (

    select
        user_pseudo_id,
        (select p.value.string_value from unnest(user_properties) p where p.key = 'cep_id') as cep_id
    from {{ source('ga4', 'events') }}
    where _table_suffix between format_date('%Y%m%d', date('{{ var("mis_start_date") }}'))
                           and format_date('%Y%m%d', date('{{ var("mis_end_date") }}'))
      and user_pseudo_id is not null

)

select
    user_pseudo_id,
    cep_id,
    date_trunc(date('{{ var("mis_start_date") }}'), month) as mis_month
from events
where cep_id is not null
group by 1, 2, 3
