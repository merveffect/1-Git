{{ config(materialized='table') }}

WITH scored AS (
  SELECT
    *,
    ROUND(LEAST(1.0, GREATEST(0.0,
      (COALESCE(hcp_phase1_score, 0) * 0.75)
      + (COALESCE(hcp_subject_overlap_ratio, 0) * 0.25)
    )), 4) AS combined_hcp_score
  FROM {{ ref('hcp_combined_validation') }}
)

SELECT
  snid,
  orcid_role,
  orcid_organisation,
  orcid_department,
  country_code,
  hcp_phase1_score,
  phase1_label,
  hcp_label_matches,
  total_snt_labels,
  hcp_subject_overlap_ratio,
  all_snt_labels,
  combined_hcp_score,
  CASE
    WHEN combined_hcp_score >= 0.65 THEN 'VALIDATED_HCP'
    WHEN combined_hcp_score >= 0.45 THEN 'PROBABLE_HCP'
    ELSE                                 'NOT_CONFIRMED'
  END AS final_label,
  CURRENT_TIMESTAMP() AS pipeline_run_ts
FROM scored
