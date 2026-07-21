select cleaned.*
from {{ ref('stg_df_audience_explorer_cleaned') }} cleaned
left join {{ ref ('stg_df_audience_explorer_id_flags') }} flags
on cleaned.canonical_segment_id = flags.canonical_segment_id
where cleaned.flag_column = 1
and cleaned.canonical_segment_id IN (
	select segment_id from {{ ref('raw_segment_known_users_with_email') }}
	where segment_id IS NOT NULL
)
 