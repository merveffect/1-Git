-- Phase 8 channel planning: submission x channel detail within the attribution window,
-- enriched with the main attributed submission metrics (Colab
-- mis_3_ga_data_channel_planning_specific_3).

{{ config(materialized='table', tags=['ga']) }}

{% set win = var("attribution_window_days") %}

select
    subs.* except (rg_organic, rg_organic_flag, rg_journal_home, rg_journal_home_flag),
    t1.workspace_category,
    t1.funnel,
    t1.marmind_code,
    t1.main_channels,
    t1.sub_channels,
    t1.journal_id_submission,
    subs.rg_organic,
    subs.rg_organic_flag,
    subs.rg_journal_home,
    subs.rg_journal_home_flag
from (
    select *
    from (
        select
            internal_submission_id,
            journal_id_submission,
            marmind_code,
            workspace_category,
            main_channels,
            sub_channels,
            funnel,
            max(case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) then 1 else 0 end) as flag_within_6mo
        from {{ ref('int_channel_planning_2') }}
        where submission_date_min >= date('{{ var("mis_start_date") }}')
          and submission_date_min <= date('{{ var("mis_end_date") }}')
        group by 1, 2, 3, 4, 5, 6, 7
    )
    where flag_within_6mo = 1
) t1

inner join {{ ref('int_subs_all_inter') }} subs
    on t1.internal_submission_id = subs.internal_submission_id
