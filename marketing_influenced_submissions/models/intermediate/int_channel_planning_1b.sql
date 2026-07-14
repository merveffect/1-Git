-- Phase 8 channel planning: union of non-Google and Google planning GA (Colab
-- mis_3_ga_data_channel_planning_specific_1b).

{{ config(materialized='table', tags=['ga']) }}

select
    user_pseudo_id, event_date, clean_campaign, medium, source,
    funnel, marmind_code, workspace_category, main_channels, sub_channels
from {{ ref('int_channel_planning_specific') }}

union all

select
    user_pseudo_id, event_date, clean_campaign, medium, source,
    funnel, marmind_code, workspace_category, main_channels, sub_channels
from {{ ref('int_channel_planning_google_2') }}
