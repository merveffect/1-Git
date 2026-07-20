-- Phase 4 Google auto-tagged: submission x google touchpoint with channel assignment
-- (Colab mis_3_google_auto_4_channel). Classifies each campaign as google_sea,
-- google_external_display, or google_multichannel from the j7 session shares.

{{ config(materialized='table', tags=['ga']) }}

select
    t1.*,
    t2.sessions_sea,
    t2.sessions_external_display,
    t2.sessions_total,
    t2.pct_sessions_sea,
    t2.pct_sessions_external_display,
    case
        when t2.sessions_sea > 0 and n_channels = 1 then "google_sea"
        when t2.sessions_external_display > 0 and n_channels = 1 then "google_external_display"
        when n_channels > 1 and (sessions_sea > 0 or sessions_external_display > 0) then "google_multichannel"
        else "other"
    end as channel_from_google
from (
    select *
    from {{ ref('int_google_auto_sub') }}
    where (workspace_category like "%Author%" or workspace_category like "%India%"
           or regexp_contains(lower(clean_campaign), 'hpaut') or regexp_contains(lower(clean_campaign), 'letpb'))
      and submission_date_min >= date('{{ var("mis_start_date") }}')
      and submission_date_min <= date('{{ var("mis_end_date") }}')
) t1

inner join {{ ref('int_google_auto_j7') }} t2
on upper(t1.clean_campaign) = upper(t2.clean_campaign)
