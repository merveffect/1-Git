{{ config(materialized='table') }}

SELECT
  snid,
  CASE final_label
    WHEN 'VALIDATED_HCP' THEN 'CONFIRMED'
    WHEN 'PROBABLE_HCP'  THEN 'PROBABLE'
  END                       AS hcp_confidence_tier,
  final_label               AS phase_label,
  combined_hcp_score        AS hcp_score,
  hcp_phase1_score,
  behavioral_score,
  clinical_subject_flag,
  bmc_imprint_flag,
  etoc_flag,
  oa_articles_score,
  hcp_bucket,
  orcid_role,
  orcid_organisation,
  orcid_department,
  country_code,
  CURRENT_TIMESTAMP()       AS pipeline_run_ts

FROM {{ ref('hcp_validated_final') }}
WHERE final_label IN ('VALIDATED_HCP', 'PROBABLE_HCP')
  AND orcid_role IS NOT NULL

ORDER BY
  CASE final_label
    WHEN 'VALIDATED_HCP' THEN 1
    WHEN 'PROBABLE_HCP'  THEN 2
  END,
  combined_hcp_score DESC
