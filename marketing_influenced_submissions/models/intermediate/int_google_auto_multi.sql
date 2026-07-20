-- Phase 4 Google auto-tagged: apportion multichannel campaigns to SEA or External
-- Display (Colab mis_3_google_auto_5_channel_multi). Uses the j7 session-share
-- threshold. SN-REVIEW (C3): google_multichannel_threshold default 0.8 (>80% share);
-- a channel with the other share null but positive own share is also allocated.

{{ config(materialized='table', tags=['ga']) }}

{% set thr = var("google_multichannel_threshold") %}

select
    internal_submission_id,
    sum(external_display_to_add) as external_display_to_add,
    sum(sea_to_add) as sea_to_add
from (
    select
        t1.*,
        t2.pct_sessions_sea,
        t2.pct_sessions_external_display,
        case
            when t2.pct_sessions_sea is null and t2.pct_sessions_external_display > 0 then 1
            when t2.pct_sessions_external_display > {{ thr }} then 1
            else 0
        end as external_display_to_add,
        case
            when t2.pct_sessions_external_display is null and t2.pct_sessions_sea > 0 then 1
            when t2.pct_sessions_sea > {{ thr }} then 1
            else 0
        end as sea_to_add
    from (
        select *
        from {{ ref('int_google_auto_channel_detail') }}
        where google_multichannel > 0
    ) t1

    inner join (
        select
            internal_submission_id,
            pct_sessions_external_display,
            pct_sessions_sea
        from {{ ref('int_google_auto_channel') }}
        group by 1, 2, 3
    ) t2
    on t1.internal_submission_id = t2.internal_submission_id
)
group by 1
