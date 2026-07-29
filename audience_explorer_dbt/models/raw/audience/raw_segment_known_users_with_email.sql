with base as (
	select
		*,
		lower(trim(email)) as email_normalized
	from {{ source('prod_cdi_presentation', 'segment_known_users_with_email') }}
	where segment_id is not null
		and email is not null
),

dedup_by_segment as (
	select *
	from base
	qualify row_number() over (
		partition by segment_id
		order by created_at desc, email_normalized desc
	) = 1
),

dedup_by_email as (
	select *
	from dedup_by_segment
	qualify row_number() over (
		partition by email_normalized   
		order by created_at desc, segment_id desc
	) = 1
)

select * except(email_normalized)
from dedup_by_email


