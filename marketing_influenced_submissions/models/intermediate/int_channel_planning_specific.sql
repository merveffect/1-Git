-- Phase 8 channel planning: non-Google planning GA touchpoints (Colab
-- mis_3_ga_data_channel_planning_specific). Adds funnel (parsed from the campaign
-- name) and restricts to Author/India/China/RG/Naver activity.
--
-- SN-REVIEW (E3): funnel = substr(clean_campaign, 12, 4) with an 'NA' override for
-- RG/Naver organic/referral rows, ported verbatim. Expected values: AWA1, CON1, DEC1,
-- ATT1, NA. The disabled lookup_channel_funnel_detail join is intentionally omitted.

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
    main_channels,
    sub_channels
from (
    select
        t1.user_pseudo_id,
        t1.event_date,
        t1.clean_campaign,
        t1.medium,
        t1.source,
        t1.main_channels,
        t1.sub_channels,
        case when (
            lower(trim(t1.clean_campaign)) in ('(organic)', '(referral)', 'confirmation-email')
            and regexp_contains(lower(t1.sub_channels), r'(naver|researchgate)')
        ) then 'NA' else substr(t1.clean_campaign, 12, 4) end as funnel,
        t1.marmind_code,
        mar.workspace_category
    from {{ ref('int_ga_data_channel') }} t1
    left join {{ ref('stg_marmind') }} mar
        on upper(t1.marmind_code) = upper(mar.marmind_campaign_code)
    where (
        lower(trim(t1.clean_campaign)) not in ('(organic)', '(referral)', 'confirmation-email')
        or regexp_contains(lower(t1.sub_channels), r'(naver|researchgate)')
    )
    and (
        mar.workspace_category like "%Authors%"
        or mar.workspace_category like "%India%"
        or regexp_contains(lower(t1.clean_campaign), r'(hpaut|letpb)')
        or regexp_contains(lower(t1.sub_channels), r'(naver|researchgate)')
    )
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
)
