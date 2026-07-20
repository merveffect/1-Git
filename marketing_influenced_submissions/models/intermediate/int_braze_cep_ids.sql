-- Phase 1B identity: GA4 user_pseudo_id -> Braze CEP id (Colab braze_cep_ids).
-- By default reads the accumulated prod identity map; otherwise extracts the cep_id
-- user-property from raw GA4 events for the processing window only.
-- Incremental insert_overwrite on mis_month (same idempotency note as int_ga4_sap_ids).

{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={'field': 'mis_month', 'data_type': 'date', 'granularity': 'month'},
        on_schema_change='sync_all_columns',
    )
}}

{% if var('identity_extract_from_prod') %}

-- Cheap path: read prod's cumulative user_pseudo_id -> cep_id map instead of scanning
-- raw GA4 events for the window only, which undercounts in a single-month dev build.
-- Stamping mis_month = processing month places all accumulated pairs in one partition;
-- downstream int_braze_email_clientid dedups via group by, which is correct for the
-- dev single-month reconciliation.
select
    user_pseudo_id,
    cep_id,
    date_trunc(date('{{ var("mis_start_date") }}'), month) as mis_month
from {{ source('mis_prod', 'braze_cep_ids') }}
where user_pseudo_id is not null
  and cep_id is not null
group by 1, 2, 3

{% else %}

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

{% endif %}
