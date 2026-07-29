with traits_with_email as (
  select
    canonical_segment_id,
    email
  from {{ ref('stg_user_traits_snid_email_combined') }}
),

matched as (
  select
    known_users.segment_id as canonical_segment_id,
    lower(trim(known_users.email)) as email,
    known_users.created_at
  from {{ ref('raw_segment_known_users_with_email') }} known_users
  join traits_with_email email_traits
    on known_users.segment_id = email_traits.canonical_segment_id
   and lower(trim(known_users.email)) = email_traits.email
  where known_users.segment_id is not null
    and known_users.email is not null
),

dedup_by_canonical as (
  select
    canonical_segment_id,
    email,
    created_at
  from matched
  qualify row_number() over (
    partition by canonical_segment_id
    order by created_at desc, email
  ) = 1
),

dedup_by_email as (
  select
    canonical_segment_id,
    email
  from dedup_by_canonical
  qualify row_number() over (
    partition by email
    order by created_at desc, canonical_segment_id
  ) = 1
)

select
  canonical_segment_id,
  email
from dedup_by_email
