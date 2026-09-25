-- Phase 3 GA activity: manual GA touchpoints with channel grouping (Colab
-- mis_3_ga_data_channel). Normalises medium/source, then joins the RM channel
-- groupings reference to attach main_channels / sub_channels.
--
-- SN-REVIEW (C4): uses the NATIVE channel-groupings table via stg_channel_groupings
-- (the Colab points at ae_metadata.channel_groupings, the Drive-backed sheet). The
-- email-source nulling exceptions and the google+cpc External Display exclusion are
-- ported verbatim, including rct_subjectalert: without that source-specific exception,
-- its lookup row becomes generic and duplicates every email touchpoint. Processes the
-- whole lookback window (prod accumulates monthly).

{{ config(materialized='table', tags=['ga']) }}

select
    user_pseudo_id,
    event_date,
    clean_campaign,
    medium,
    source,
    journal_id,
    marmind_code,
    main_channels,
    sub_channels
from (
    select
        *
    from (
        select
            t1.*,
            lkp.source as source_lookup,
            lkp.medium as medium_lookup,
            lkp.main_channels,
            lkp.sub_channels,
            case when lkp.source is null then null else strpos(lower(t1.source), lower(lkp.source)) > 0 end as match_source
        from (
            select
                user_pseudo_id,
                event_date,
                clean_campaign,
                case when (lower(source) = 'linkedin' and lower(medium) = 'paid') then 'paid_social' else lower(medium) end as medium,
                case when lower(medium) = 'internal_display' and lower(source) = 'snlink' then 'slink' else lower(source) end as source,
                journal_id,
                marmind_code
            from {{ ref('int_ga_data') }}
            where event_date >= date_sub(date('{{ var("mis_start_date") }}'), interval {{ var("ga_lookback_months") }} month)
              and event_date <= date('{{ var("mis_end_date") }}')
              and medium <> "(not set)"
              and campaign is not null
            group by 1, 2, 3, 4, 5, 6, 7
        ) t1

        left join (
            select
                case
                    when lower(medium) = 'email' and lower(source) = 'researchgate' then 'researchgate'
                    when lower(medium) in ('email', 'e-mail') and lower(source) = 'chatgpt.com' then 'chatgpt.com'
                    when lower(medium) = 'email' and lower(source) = 'etoc' then 'etoc'
                    when lower(medium) = 'email' and lower(source) = 'rct_subjectalert' then 'rct_subjectalert'
                    when lower(medium) = 'email' and lower(source) in ('peeref.com', 'letpub.com', 'growkudos.com') then lower(source)
                    when lower(medium) = 'email' then null
                    else lower(source)
                end as source,
                medium,
                main_channels,
                sub_channels
            from {{ ref('stg_channel_groupings') }}
            where not (lower(source) = 'google' and lower(medium) = 'cpc' and trim(main_channels) = 'External Display')
            group by 1, 2, 3, 4
        ) lkp
        on (
            (lower(t1.source) = lower(lkp.source) and lower(t1.medium) = lower(lkp.medium))
            or (lower(t1.medium) = 'email' and lower(lkp.medium) = 'email' and lkp.source is null)
        )
    )
    where match_source = true
       or match_source is null
)
