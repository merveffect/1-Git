{{ config(materialized='table') }}

WITH base AS (
  SELECT * FROM {{ ref('hcp_combined_validation') }}
),

with_cdp AS (
  SELECT
    *,
    GREATEST(0.0,
      ROUND(
        (COALESCE(hcp_subject_overlap_ratio, 0) * 0.50)
        + (has_clinical_article_reads * 0.25)
        + (has_clinical_keywords      * 0.15)
        + CASE
            WHEN submguidelines_30d >= 10 THEN -0.30
            WHEN submguidelines_30d >= 5  THEN -0.15
            WHEN submguidelines_30d >= 2  THEN -0.05
            ELSE 0.0
          END,
      4)
    ) AS cdp_behavioral_score
  FROM base
),

with_combined AS (
  SELECT
    *,
    ROUND(LEAST(1.0, GREATEST(0.0,
      (COALESCE(hcp_phase1_score, 0) * 0.60) + cdp_behavioral_score
    )), 4) AS combined_hcp_score
  FROM with_cdp
)

SELECT
  snid,
  orcid_role,
  orcid_organisation,
  orcid_department,
  country_code,
  hcp_phase1_score,
  phase1_label,
  has_clinical_article_reads,
  has_clinical_keywords,
  submguidelines_30d,
  hcp_label_matches,
  total_snt_labels,
  hcp_subject_overlap_ratio,
  all_snt_labels,
  cdp_behavioral_score,
  combined_hcp_score,
  CASE
    WHEN combined_hcp_score >= 0.65 AND submguidelines_30d < 5 THEN 'VALIDATED_HCP'
    WHEN combined_hcp_score >= 0.45                             THEN 'PROBABLE_HCP'
    ELSE                                                           'NOT_CONFIRMED'
  END AS final_label,
  CURRENT_TIMESTAMP() AS pipeline_run_ts
FROM with_combined