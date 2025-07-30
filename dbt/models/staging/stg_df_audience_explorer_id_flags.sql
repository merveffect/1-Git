select
  canonical_segment_id
  email is null as email_flag,
  anonymous_id is null AS anonymous_id_flag,
  sap_outbound_id is null AS sap_outbound_id_flag,
  last_name is null AS last_name_flag,
  snid is null AS snid_flag,
  researcher_id is null AS researcher_id_flag,
  orcid is null AS orcid_flag,
  ga_client_id is null AS ga_client_id_flag,
  first_name is null AS first_name_flag,
  permutive_id is null AS permutive_id_flag,
  cep_id is null AS cep_id_flag
  from {{ ref('stg_df_audience_explorer_base') }}
  