select *,
from {{ source('cdp_profile_sync', 'user_traits') }}
where canonical_segment_id is not null






