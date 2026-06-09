select b.*
from {{ ref('audience_builder_big') }} b
where exists (
        select 1
        from {{ source('devykw8828_cdi_presentation', 'segment_known_users_with_email') }} s
        where s.segment_id = b.canonical_segment_id
            and lower(trim(s.email)) = lower(trim(b.email))
)