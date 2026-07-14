-- Phase 8 channel planning: align Google planning GA to the non-Google column set for
-- the union (Colab mis_3_ga_data_channel_planning_specific_google_2).
--
-- SN-REVIEW (E5): the exact mis_..._google_2 SQL was not available in the Colab
-- export. This approximates it by mapping channel_from_lookup -> main_channels and
-- leaving sub_channels null so the branch unions cleanly with the non-Google branch.
-- Confirm the intended Google channel mapping before promotion.

{{ config(materialized='table', tags=['ga']) }}

select
    user_pseudo_id,
    event_date,
    clean_campaign,
    medium,
    source,
    funnel,
    marmind_code,
    workspace_category,
    channel_from_lookup as main_channels,
    cast(null as string) as sub_channels
from {{ ref('int_channel_planning_google_1b') }}
