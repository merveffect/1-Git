-- Phase 8 channel planning: multichannel Google campaign allocation for planning
-- (Colab mis_3_ga_data_channel_planning_specific_google_multi).
--
-- SN-REVIEW (E3): this path uses channel_planning_multi_threshold (default 0.5),
-- DELIBERATELY different from the main MIS Google multichannel path (0.8).

{{ config(materialized='table', tags=['ga']) }}

{% set thr = var("channel_planning_multi_threshold") %}

select
    t1.*,
    t4.pct_sessions_external_display,
    t4.pct_sessions_sea,
    t4.sessions_total,
    case
        when t4.pct_sessions_external_display > {{ thr }} then "External Display"
        when t4.pct_sessions_sea > {{ thr }} then "SEA"
        else "check"
    end as channel_from_multi
from (
    select clean_campaign, count(*) as nrows
    from {{ ref('int_google_auto_channel') }}
    where channel_from_google = "google_multichannel"
    group by 1
) t1
left join (
    select clean_campaign, pct_sessions_external_display, pct_sessions_sea, sessions_total
    from {{ ref('int_google_auto_channel') }}
    group by 1, 2, 3, 4
) t4
on t1.clean_campaign = t4.clean_campaign
