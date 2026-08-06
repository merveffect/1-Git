-- Phase 8 channel planning: Google auto-tag planning GA with channel + funnel (Colab
-- mis_3_ga_data_channel_planning_specific_google_1b). Resolves multichannel campaigns
-- via int_channel_planning_google_multi.

{{ config(materialized='table', tags=['ga']) }}

select
    t1.user_pseudo_id,
    t1.event_date,
    t1.clean_campaign,
    t1.medium,
    t1.source,
    t1.funnel,
    t1.marmind_code,
    t1.workspace_category,
    case when t1.channel_from_lookup = "google_multichannel" then t2.channel_from_multi else t1.channel_from_lookup end as channel_from_lookup
from (
    select
        user_pseudo_id,
        event_date,
        clean_campaign,
        medium,
        "google" as source,
        case
            when channel_from_google like "%sea%" then "SEA"
            when channel_from_google like "%external_display%" then "External Display"
            else channel_from_google
        end as channel_from_lookup,
        substr(clean_campaign, 12, 4) as funnel,
        marmind_code,
        workspace_category
    from {{ ref('int_google_auto_channel') }}
    where clean_campaign <> "(organic)"
      and clean_campaign <> "(referral)"
      and clean_campaign <> "confirmation-email"
      and (workspace_category like "%Authors%" or workspace_category like "%India%"
           or workspace_category like "%New Launches%"
           or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb'))
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9
) t1
left join {{ ref('int_channel_planning_google_multi') }} t2
    on t1.clean_campaign = t2.clean_campaign
