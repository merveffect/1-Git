SELECT *,
CASE 
 WHEN canonical_segment_id IS NULL
    AND anonymous_id IS NULL
    AND sap_outbound_id IS NULL
    AND last_name IS NULL
    AND snid IS NULL
    AND researcher_id IS NULL 
    AND orcid IS NULL
    AND ga_client_id IS NULL 
    AND email IS NULL
    AND first_name IS NULL 
    AND permutive_id IS NULL
 THEN 1
 ELSE 0
END AS flag_column 
FROM {{ ref('raw_audience_explorer_test') }}