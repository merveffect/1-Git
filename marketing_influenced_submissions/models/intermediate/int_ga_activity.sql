-- Phase 3 GA activity: per-submission manual-channel influence flags (Colab
-- mis_3_ga_activity_4). Applies the attribution window and the RM/Collections
-- workspace rules to the submission x GA touchpoints, then aggregates to one row per
-- submission.
--
-- SN-REVIEW (C1/C5): attribution_window_days (default 180, strictly before submission)
-- and the workspace filters (%Authors%, %India%, hpaut, letpb, naver) are ported
-- verbatim. SEA is matched on the submitted journal_id; SEA "no journal" is the
-- unmatched variant kept for comparison.

{{ config(materialized='table', tags=['ga']) }}

select
    internal_submission_id,
    case when email_rm + external_display_rm + internal_display_rm + paid_social_rm + sea_rm + rg_journal_home + email_col + external_display_col + internal_display_col + paid_social_col + sea_col > 0 then 1 else 0 end as rm_activity_1plus,
    case when email_rm + external_display_rm + internal_display_rm + paid_social_rm + sea_rm + rg_journal_home >= 3 then 1 else 0 end as rm_activity_3plus,
    case when email_col + external_display_col + internal_display_col + paid_social_col + sea_col > 0 then 1 else 0 end as collections_activity,
    email_rm,
    external_display_rm,
    internal_display_rm,
    paid_social_rm,
    sea_rm,
    sea_rm_no_journal,
    seo,
    seo_no_journal,
    organic_social,
    email_col,
    external_display_col,
    internal_display_col,
    paid_social_col,
    sea_col,
    organic_social_col,
    rg_organic,
    rg_journal_home
from (
    select
        internal_submission_id,
        sum(email_rm) as email_rm,
        sum(external_display_rm) as external_display_rm,
        sum(internal_display_rm) as internal_display_rm,
        sum(paid_social_rm) as paid_social_rm,
        sum(sea_rm) as sea_rm,
        sum(sea_rm_no_journal) as sea_rm_no_journal,
        sum(seo) as seo,
        sum(seo_no_journal) as seo_no_journal,
        sum(organic_social) as organic_social,
        sum(email_col) as email_col,
        sum(external_display_col) as external_display_col,
        sum(internal_display_col) as internal_display_col,
        sum(paid_social_col) as paid_social_col,
        sum(sea_col) as sea_col,
        sum(organic_social_col) as organic_social_col,
        sum(rg_organic) as rg_organic,
        sum(rg_journal_home) as rg_journal_home
    from (
        {% set win = var("attribution_window_days") %}
        select
            internal_submission_id,
            submission_date_min,
            user_pseudo_id,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Authors%" or workspace_category like "%India%" or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb')) and channels_categories = "E-Mail" and trim(main_channels) = "Email" then 1 else 0 end as email_rm,
            sea_rm,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Authors%" or workspace_category like "%India%" or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb')) and channels_categories = "Internal Display" and trim(main_channels) = "Internal Display" then 1 else 0 end as internal_display_rm,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Authors%" or workspace_category like "%India%" or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb')) and channels_categories = "External Display" and trim(main_channels) = "External Display" then 1 else 0 end as external_display_rm,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Authors%" or workspace_category like "%India%" or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb')) and channels_categories = "Paid Social" and trim(main_channels) = "Paid Social" then 1 else 0 end as paid_social_rm,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Authors%" or workspace_category like "%India%" or regexp_contains(lower(clean_campaign), r'(hpaut|letpb)') or regexp_contains(lower(sub_channels), 'naver')) and channels_categories = "SEA" and trim(main_channels) = "SEA" then 1 else 0 end as sea_rm_no_journal,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and regexp_contains(lower(trim(sub_channels)), 'organic social') then 1 else 0 end as organic_social,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and medium = "organic" then 1 else 0 end as seo_no_journal,
            seo,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and regexp_contains(lower(sub_channels), 'researchgate referral|researchgate organic') then 1 else 0 end as rg_organic,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and regexp_contains(lower(sub_channels), 'researchgate journal home') then 1 else 0 end as rg_journal_home,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Collection%") and channels_categories = "E-Mail" and trim(main_channels) = "Email" then 1 else 0 end as email_col,
            sea_col,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Collection%") and channels_categories = "Internal Display" and trim(main_channels) = "Internal Display" then 1 else 0 end as internal_display_col,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Collection%") and channels_categories = "External Display" and trim(main_channels) = "External Display" then 1 else 0 end as external_display_col,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Collection%") and channels_categories = "Paid Social" and trim(main_channels) = "Paid Social" then 1 else 0 end as paid_social_col,
            case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Collection%") and regexp_contains(lower(trim(sub_channels)), 'organic social') then 1 else 0 end as organic_social_col
        from (
            select
                internal_submission_id,
                submission_date_min,
                user_pseudo_id,
                clean_campaign,
                event_date,
                medium,
                source,
                main_channels,
                sub_channels,
                workspace_category,
                channels_categories,
                max(case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Authors%" or workspace_category like "%India%" or regexp_contains(lower(clean_campaign), r'(hpaut|letpb)') or regexp_contains(lower(sub_channels), 'naver')) and channels_categories = "SEA" and trim(main_channels) = "SEA" and journal_id_submission = cast(journal_id as string) then 1 else 0 end) as sea_rm,
                max(case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and (workspace_category like "%Collection%") and channels_categories = "SEA" and trim(main_channels) = "SEA" and journal_id_submission = cast(journal_id as string) then 1 else 0 end) as sea_col,
                max(case when (date_diff(submission_date_min, event_date, day) > 0 and date_diff(submission_date_min, event_date, day) <= {{ win }}) and medium = "organic" and journal_id_submission = cast(journal_id as string) then 1 else 0 end) as seo
            from {{ ref('int_ga_activity_sub') }}
            where submission_date_min >= date('{{ var("mis_start_date") }}')
              and submission_date_min <= date('{{ var("mis_end_date") }}')
            group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        ) ga
    )
    group by 1
)
