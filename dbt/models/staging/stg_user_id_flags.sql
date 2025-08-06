SELECT 
*,
CASE when email is null THEN 0 ELSE 1 END AS email_flag,
CASE when anonymous_id is null THEN 0 ELSE 1 END AS anonymous_id_flag,
CASE when sap_outbound_id is null THEN 0 ELSE 1 END AS sap_outbound_id_flag,
CASE when last_name is null THEN 0 ELSE 1 END AS last_name_flag,
CASE when snid is null THEN 0 ELSE 1 END AS snid_flag,
CASE when researcher_id is null THEN 0 ELSE 1 END AS researcher_id_flag,
CASE when orcid is null THEN 0 ELSE 1 END AS orcid_flag,
CASE when ga_client_id is null THEN 0 ELSE 1 END AS ga_client_id_flag,
CASE when first_name is null THEN 0 ELSE 1 END AS first_name_flag,
CASE when permutive_id is null THEN 0 ELSE 1 END AS permutive_id_flag,
CASE when cep_id is null THEN 0 ELSE 1 END AS cep_id_flag
FROM {{ ref('raw_audience_explorer_test') }}