with traits_with_email as (
  select
  canonical_segment_id,
  lower(trim(value)) as email
  from {{ ref('raw_user_traits') }}
  where lower(name) = 'email'
  and value is not null
  and value != ''
)

  select
  known_users.segment_id as canonical_segment_id,
  lower(trim(known_users.email)) as email
  from {{ ref('raw_segment_known_users_with_email') }} known_users
  join traits_with_email email_traits
  on known_users.segment_id = email_traits.canonical_segment_id
  and known_users.email = email_traits.email
  where known_users.segment_id IS NOT NULL
  and known_users.email IS NOT NULL
