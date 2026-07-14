-- Phase 4 Google auto-tagged: per-campaign SEA vs External Display session shares
-- (Colab mis_3_google_auto_3_j7). Uses the j7 report to compute pct_sessions_sea /
-- pct_sessions_external_display for the campaigns seen in the author workspaces.

{{ config(materialized='table', tags=['ga']) }}

select
    *,
    safe_divide(sessions_sea, sessions_total) as pct_sessions_sea,
    safe_divide(sessions_external_display, sessions_total) as pct_sessions_external_display
from (
    select
        ga.clean_campaign,
        ga.n_users,
        ga.n_subs,
        j7.n_channels,
        j7.sessions_sea,
        j7.sessions_external_display,
        j7.sessions_other,
        j7.sessions_total
    from (
        select
            clean_campaign,
            count(distinct user_pseudo_id) as n_users,
            count(distinct internal_submission_id) as n_subs
        from {{ ref('int_google_auto_sub') }}
        where (workspace_category like "%Author%" or workspace_category like "%India%"
               or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb'))
        group by 1
    ) ga

    left join (
        select
            clean_campaign,
            count(distinct main_channels) as n_channels,
            sum(case when main_channels = "sea" then sessions else null end) as sessions_sea,
            sum(case when main_channels = "external display" then sessions else null end) as sessions_external_display,
            sum(case when main_channels <> "external display" and main_channels <> "sea" then sessions else null end) as sessions_other,
            sum(sessions) as sessions_total
        from {{ ref('stg_j7') }}
        where date >= "2024-07-01"
          and clean_campaign not in ("(referral)", "(organic)", "(direct)", "(not set)", "organic", "referral")
        group by 1
    ) j7
    on upper(ga.clean_campaign) = upper(j7.clean_campaign)
)
