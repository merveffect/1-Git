{{ config(materialized='table') }}

-- Dentist marketing audience: ORCID-identified dentists with marketing consent.
-- Only includes users with mkt_pref_opt_in = TRUE.
-- Use advertising_opt_in = TRUE to further narrow for paid channel targeting.

SELECT
  d.snid,
  d.dentist_role,
  d.organisation,
  d.department,
  d.country_code                        AS orcid_country,
  d.dentist_bucket,
  ab.advertising_opt_in,
  ab.mkt_pref_opt_in

FROM {{ ref('hcp_dentists_scored') }} d
JOIN {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }} ab
  ON d.snid = ab.snid
WHERE ab.mkt_pref_opt_in = TRUE OR ab.advertising_opt_in = TRUE

ORDER BY d.dentist_bucket, ab.advertising_opt_in DESC