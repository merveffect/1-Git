-- Phase 4 Google auto-tagged: per-submission SEA / External Display / multichannel
-- influence flags (Colab mis_3_google_auto_5_channel_detail). Applies the attribution
-- window and RM/Collections workspace rules; SEA is matched on the submitted journal.

{{ config(materialized='table', tags=['ga']) }}

{% set win = var("attribution_window_days") %}

select
    internal_submission_id,
    submission_date_min,
    sum(external_display_rm) as external_display_rm,
    sum(sea_rm) as sea_rm,
    sum(sea_rm_no_journal) as sea_rm_no_journal,
    sum(external_display_col) as external_display_col,
    sum(sea_col) as sea_col,
    sum(sea_col_no_journal) as sea_col_no_journal,
    sum(google_multichannel) as google_multichannel
from (
    select
        internal_submission_id,
        submission_date_min,
        user_pseudo_id,
        sea_rm,
        case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Authors%" or workspace_category like "%India%" or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb')) and channel_from_google = "google_external_display" then 1 else 0 end as external_display_rm,
        case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Authors%" or workspace_category like "%India%" or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb')) and channel_from_google = "google_sea" then 1 else 0 end as sea_rm_no_journal,
        sea_col,
        case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Collection%") and channel_from_google = "google_external_display" then 1 else 0 end as external_display_col,
        case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Collection%") and channel_from_google = "google_sea" then 1 else 0 end as sea_col_no_journal,
        case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Authors%" or workspace_category like "%India%" or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb')) and channel_from_google = "google_multichannel" then 1 else 0 end as google_multichannel
    from (
        select
            internal_submission_id,
            submission_date_min,
            user_pseudo_id,
            event_date,
            journal_id_submission,
            journal_id,
            clean_campaign,
            workspace_category,
            sessions_sea,
            sessions_external_display,
            pct_sessions_sea,
            pct_sessions_external_display,
            channel_from_google,
            max(case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Authors%" or workspace_category like "%India%" or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb')) and channel_from_google = "google_sea" and journal_id_submission = cast(journal_id as string) then 1 else 0 end) as sea_rm,
            max(case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Collection%") and channel_from_google = "google_sea" and journal_id_submission = cast(journal_id as string) then 1 else 0 end) as sea_col
        from {{ ref('int_google_auto_channel') }}
        where submission_date_min >= date('{{ var("mis_start_date") }}')
          and submission_date_min <= date('{{ var("mis_end_date") }}')
        group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
    ) ga
)
group by 1, 2
