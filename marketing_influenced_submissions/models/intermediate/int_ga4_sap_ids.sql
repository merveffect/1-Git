-- Phase 1B identity: GA4 user_pseudo_id -> SAP outbound id (Colab mis_2_sap_ids_ga4_1
-- + _2 combined and deduped). Extracts the sap_outbound_id user-property from GA4
-- raw events for the processing window.
--
-- Idempotency: incremental insert_overwrite on mis_month (the processing month), so
-- re-running a month replaces its contribution. NOTE: prod mis_2_sap_ids_ga4_2 is
-- cumulative over all months; a single-month dev build only holds that month.

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
        (select p.value.string_value from unnest(user_properties) p where p.key = 'sap_outbound_id') as sap_outbound_id
    from {{ source('ga4', 'events') }}
    where _table_suffix between format_date('%Y%m%d', date('{{ var("mis_start_date") }}'))
                           and format_date('%Y%m%d', date('{{ var("mis_end_date") }}'))
      and user_pseudo_id is not null

)

select
    user_pseudo_id,
    sap_outbound_id,
    date_trunc(date('{{ var("mis_start_date") }}'), month) as mis_month
from events
where sap_outbound_id is not null
group by 1, 2, 3
