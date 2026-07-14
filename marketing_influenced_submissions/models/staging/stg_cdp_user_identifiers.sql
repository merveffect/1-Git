-- Active CDP identifiers (cdp_profile_sync.user_identifiers): canonical_segment_id
-- keyed typed identifiers. Backs the active identity table mis_2_email_clientid_new
-- (email + ga_client_id split downstream). Thin passthrough of the columns used.

with source as (

    select * from {{ source('cdp_profile_sync', 'user_identifiers') }}

)

select
    canonical_segment_id,
    type,
    value
from source
