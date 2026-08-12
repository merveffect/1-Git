-- Phase 4 Google auto-tagged: submission x google-ads touchpoint over the lookback
-- window (Colab mis_2_google_auto_2_backfill). Enriched with marmind
-- workspace_category; channels_categories hardcoded 'N/A' (Colab Jul-2026).

{{ config(materialized='table', tags=['ga']) }}

select
    subid.*,
    ga.* except (user_pseudo_id),
    mar.workspace_category,
    'N/A' as channels_categories
from (
    select
        internal_submission_id,
        submission_date_min,
        user_pseudo_id,
        journal_id as journal_id_submission,
        imprint_code as imprint_submission
    from {{ ref('int_sub_details') }}
    where submission_date_min >= date('{{ var("mis_start_date") }}')
      and submission_date_min <= date('{{ var("mis_end_date") }}')
) subid

left join (
    select
        event_date,
        user_pseudo_id,
        clean_campaign,
        marmind_code,
        medium,
        source,
        journal_id,
        "n/a google" as channel_from_lookup
    from {{ ref('int_google_auto_1') }}
    where event_date >= date_sub(date('{{ var("mis_start_date") }}'), interval {{ var("ga_lookback_months") }} month)
      and event_date <= date('{{ var("mis_end_date") }}')
) ga
on subid.user_pseudo_id = ga.user_pseudo_id

left join {{ ref('stg_marmind') }} mar
on upper(ga.marmind_code) = upper(mar.marmind_campaign_code)
