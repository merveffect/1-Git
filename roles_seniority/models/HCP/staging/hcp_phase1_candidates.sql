-- Phase 1 ORCID candidates selected for Phase 2 validation.
-- Only records with a confirmed or probable HCP score progress
-- to the CDP behavioral scoring stage.
SELECT
  snid,
  orcid_role,
  orcid_organisation,
  orcid_department,
  country_code,
  hcp_phase1_score,
  phase1_label,
  hcp_bucket
FROM {{ ref('hcp_identified_phase1') }}
WHERE phase1_label IN ('CONFIRMED_HCP_CANDIDATE', 'PROBABLE_HCP')