{{ config(materialized='table') }}

-- Combines Phase 1 ORCID score with Phase 2 behavioral score.
-- combined_hcp_score = 0.70 × phase1_score + 0.30 × behavioral_score

SELECT
  p1.snid,
  p1.orcid_role,
  p1.orcid_organisation,
  p1.orcid_department,
  p1.country_code,
  p1.hcp_phase1_score,
  p1.phase1_label,
  p1.hcp_bucket,
  COALESCE(b.behavioral_score,      0) AS behavioral_score,
  COALESCE(b.clinical_subject_flag, 0) AS clinical_subject_flag,
  COALESCE(b.bmc_imprint_flag,      0) AS bmc_imprint_flag,
  COALESCE(b.etoc_flag,             0) AS etoc_flag,
  COALESCE(b.oa_articles_score,     0) AS oa_articles_score

FROM {{ ref('hcp_phase1_candidates') }} p1
LEFT JOIN {{ ref('hcp_behavioral_score') }} b ON p1.snid = b.snid
