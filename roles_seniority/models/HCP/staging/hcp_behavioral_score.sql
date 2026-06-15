{{ config(materialized='table') }}

-- Phase 2 behavioral scoring for Phase 1 candidates.
-- Uses 4 Tier 1 signals identified from HCP vs. all opt-in benchmark analysis:
--   clinical_subject_flag : 0.40 weight (Index 6.7x–10.8x)
--   bmc_imprint_flag      : 0.20 weight (Index 2.06x)
--   etoc_flag             : 0.20 weight (Index 1.76x)
--   oa_articles_score     : 0.20 weight (Index 1.88x)

SELECT
  p1.snid,

  -- Signal 1: clinical subject
  -- snid_to_mktps_step2.all_snt_labels holds up to 10 subject names as a string
  CASE WHEN REGEXP_CONTAINS(
    COALESCE(seg.all_snt_labels, ''),
    r'Clinical Medicine|Health Sciences|Internal Medicine|Oncology|Cardiology|Radiology|Public Health|Biomedical Research'
  ) THEN 1 ELSE 0 END                                                           AS clinical_subject_flag,

  -- Signal 2: BMC imprint
  CASE WHEN ab.last_submission_imprint = 'BMC' THEN 1 ELSE 0 END               AS bmc_imprint_flag,

  -- Signal 3: eTOC engagement
  CASE WHEN ab.etoc_received_all = TRUE THEN 1 ELSE 0 END           AS etoc_flag,

  -- Signal 4: OA articles (tiered: 0 = none, 0.5 = 1–4, 1.0 = 5+)
  CASE
    WHEN COALESCE(ab.oa_articles, 0) = 0  THEN 0.0
    WHEN COALESCE(ab.oa_articles, 0) <= 4 THEN 0.5
    ELSE                                       1.0
  END                                                                            AS oa_articles_score,

  ROUND(
    (CASE WHEN REGEXP_CONTAINS(COALESCE(seg.all_snt_labels, ''),
      r'Clinical Medicine|Health Sciences|Internal Medicine|Oncology|Cardiology|Radiology|Public Health|Biomedical Research'
    ) THEN 1 ELSE 0 END * 0.40)
    + (CASE WHEN ab.last_submission_imprint = 'BMC' THEN 1 ELSE 0 END * 0.20)
    + (CASE WHEN ab.etoc_received_all = TRUE THEN 1 ELSE 0 END * 0.20)
    + (CASE
        WHEN COALESCE(ab.oa_articles, 0) = 0  THEN 0.0
        WHEN COALESCE(ab.oa_articles, 0) <= 4 THEN 0.5
        ELSE 1.0
       END * 0.20),
  4) AS behavioral_score

FROM {{ ref('hcp_phase1_candidates') }} p1
LEFT JOIN {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }} ab
  ON p1.snid = ab.snid
LEFT JOIN {{ ref('snid_to_mktps_step2') }} seg
  ON p1.snid = seg.snid
