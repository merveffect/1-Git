-- Phase 8 channel planning: submission x planning GA touchpoint (Colab
-- mis_3_ga_data_channel_planning_specific_2). Inner join keeps only submissions with
-- planning GA activity (main_channels not null) in the lookback window.

{{ config(materialized='table', tags=['ga']) }}

select
    subid.*,
    ga.* except (user_pseudo_id)
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

inner join (
    select
        event_date,
        user_pseudo_id,
        clean_campaign,
        marmind_code,
        workspace_category,
        funnel,
        medium,
        source,
        main_channels,
        sub_channels
    from {{ ref('int_channel_planning_1b') }}
    where event_date >= date_sub(date('{{ var("mis_start_date") }}'), interval {{ var("ga_lookback_months") }} month)
      and event_date <= date('{{ var("mis_end_date") }}')
      and main_channels is not null
) ga
on subid.user_pseudo_id = ga.user_pseudo_id
