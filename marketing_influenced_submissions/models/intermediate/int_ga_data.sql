-- Phase 3 GA activity: raw manual-campaign GA4 events (Colab mis_2_ga_data). Extracts
-- manually-tagged (UTM) marketing touchpoints plus researcher engagement events over
-- the attribution lookback window, and parses clean_campaign + marmind_code.
--
-- Window: GA events are pulled ga_lookback_months before the submission window start
-- (May 2026 -> from 2025-11-01) so the 180-day attribution downstream sees the full
-- lookback. In prod mis_2_ga_data is a monthly-accumulated INSERT; here it is rebuilt
-- for the whole lookback window each run.

{{ config(materialized='table', tags=['ga', 'ga_expensive']) }}

select
    *,
    regexp_extract(lower(clean_campaign), r'[A-z]{4}_[A-z0-9]{5}_[A-z0-9]{4}_.._[A-z0-9]{4}_([A-z0-9\-]{5}).*') as marmind_code
from (
    select
        *,
        case
            when not regexp_contains(campaign, r'.*[a-zA-Z]{4}_[a-zA-Z0-9]{5}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{2}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{5}_.+$') then campaign
            when regexp_contains(campaign, r'^[a-zA-Z]{4}_[a-zA-Z0-9]{5}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{2}_[a-zA-Z0-9]{4}_[a-zA-Z0-9]{5}_.+$') then campaign
            else campaign_name_cleaned
        end as clean_campaign
    from (
        select
            user_pseudo_id,
            parse_date('%Y%m%d', event_date) as event_date,
            session_traffic_source_last_click.manual_campaign.campaign_name as campaign,
            substring(session_traffic_source_last_click.manual_campaign.campaign_name, instr(session_traffic_source_last_click.manual_campaign.campaign_name, '_', 1, 3) + 1) as campaign_name_cleaned,
            (select params.value.int_value from unnest(event_params) as params where params.key = 'journal_id') as journal_id,
            case
                when device.web_info.hostname = "link.springer.com" then "springer"
                when device.web_info.hostname = "www.nature.com" then "nature"
                when device.web_info.hostname like "%biomedcentral.com%" then "bmc"
                when device.web_info.hostname like "%springeropen.com" then "springeropen"
                when device.web_info.hostname like "%springernature.com" and device.web_info.hostname <> "submission.springernature.com" then "springernature"
                when device.web_info.hostname = "www.palgrave.com" then "palgrave"
                else "other"
            end as hostname_cleaned,
            device.web_info.hostname as hostname,
            event_name,
            session_traffic_source_last_click.manual_campaign.medium as medium,
            session_traffic_source_last_click.manual_campaign.source as source,
            count(*) as event_count
        from {{ source('ga4', 'events') }}
        where _table_suffix between format_date('%Y%m%d', date_sub(date('{{ var("mis_start_date") }}'), interval {{ var("ga_lookback_months") }} month))
                              and format_date('%Y%m%d', date('{{ var("mis_end_date") }}'))
          and user_pseudo_id is not null
          and (
              session_traffic_source_last_click.manual_campaign.campaign_name is not null
              or event_name in ("session_start", "page_view", "reach_full_text_article", "reach_fta_page", "reach_journal_submission_guidelines")
          )
        group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
    )
)
