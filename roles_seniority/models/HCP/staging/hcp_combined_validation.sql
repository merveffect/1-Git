-- Combine Phase 1 candidate data with subject overlap metrics.
SELECT
  p1.snid,
  p1.orcid_role,
  p1.orcid_organisation,
  p1.orcid_department,
  p1.country_code,
  p1.hcp_phase1_score,
  p1.phase1_label,
  COALESCE(sub.hcp_label_matches, 0) AS hcp_label_matches,
  COALESCE(sub.total_snt_labels, 0)  AS total_snt_labels,
  sub.all_snt_labels,
  ROUND(
    SAFE_DIVIDE(
      COALESCE(sub.hcp_label_matches, 0),
      NULLIF(COALESCE(sub.total_snt_labels, 0), 0)
    ), 4
  ) AS hcp_subject_overlap_ratio

FROM {{ ref('hcp_phase1_candidates') }} p1
LEFT JOIN {{ ref('hcp_candidate_subjects') }} sub ON p1.snid = sub.snid
