select
	cleaned.*,
	hashed.email_hashed as hashed_email
from {{ ref('stg_df_audience_explorer_cleaned') }} cleaned
left join {{ ref ('stg_df_audience_explorer_id_flags') }} flags
on cleaned.canonical_segment_id = flags.canonical_segment_id
left join {{ ref('stg_hashing_pii') }} hashed
on cleaned.canonical_segment_id = hashed.canonical_segment_id
where cleaned.flag_column = 1

 