select
	cleaned.* EXCEPT(email, email_normalized, first_name, last_name, orcid, researcher_id),
	flags.email_flag,
	flags.last_name_flag,
	flags.snid_flag,
	flags.researcher_id_flag,
	flags.orcid_flag,
	flags.ga_client_id_flag,
	flags.first_name_flag,
	flags.permutive_id_flag
from {{ ref('stg_hashing_pii') }} cleaned
left join {{ ref ('stg_df_audience_explorer_id_flags') }} flags
on cleaned.canonical_segment_id = flags.canonical_segment_id

 