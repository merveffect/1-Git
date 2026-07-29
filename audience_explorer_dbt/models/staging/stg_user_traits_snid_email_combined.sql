-- This model consolidates identity traits from raw_user_traits by canonical_segment_id.
-- It produces one email using email -> email_address fallback and one snid using snid -> user_id fallback.

with traits_candidates as (
  select
    canonical_segment_id,
    lower(name) as trait_name,
    nullif(trim(cast(value as string)), '') as trait_value
  from {{ ref('raw_user_traits') }}
  where lower(name) in ('email', 'email_address', 'snid', 'user_id')
    and canonical_segment_id is not null
),

traits_per_user as (
  select
    canonical_segment_id,
    max(case when trait_name = 'email' then lower(trait_value) end) as email,
    max(case when trait_name = 'email_address' then lower(trait_value) end) as email_address,
    max(case when trait_name = 'snid' then trait_value end) as snid,
    max(case when trait_name = 'user_id' then trait_value end) as user_id
  from traits_candidates
  group by canonical_segment_id
)

select
  canonical_segment_id,
  coalesce(email, email_address) as email,
  coalesce(snid, user_id) as snid
from traits_per_user
where coalesce(email, email_address) is not null
