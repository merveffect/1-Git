-- Phase 1B identity: active CDP email -> GA client_id (Colab mis_2_email_clientid_new).
-- Splits cdp_profile_sync.user_identifiers into email vs ga_client_id by canonical
-- segment, then joins. SN-REVIEW (A8): GA client_id is substr(value, 7, 30) to strip
-- the GA1.x. prefix, matching the active Colab path.

with email as (

    select canonical_segment_id, value as author_email
    from {{ ref('stg_cdp_user_identifiers') }}
    where type = 'email'
    group by 1, 2

),

gaclientid as (

    select canonical_segment_id, trim(substr(value, 7, 30)) as clientid
    from {{ ref('stg_cdp_user_identifiers') }}
    where type = 'ga_client_id'
    group by 1, 2

)

select
    e.author_email,
    g.clientid
from email e
join gaclientid g using (canonical_segment_id)
where g.clientid is not null
  and e.author_email is not null
group by 1, 2
