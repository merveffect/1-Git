-- Calculate subject-label overlap between Phase 1 candidates and
-- HCP signature labels. This model computes how many of each user's
-- SNT labels are considered HCP-signature.

SELECT
  p1.snid,
  seg.all_snt_labels,
  COUNTIF(hsl.snt_label IS NOT NULL) AS hcp_label_matches,
  ARRAY_LENGTH(SPLIT(COALESCE(seg.all_snt_labels, 'EMPTY'), ',')) AS total_snt_labels

FROM {{ ref('hcp_phase1_candidates') }} p1
LEFT JOIN {{ ref('snid_to_mktps_step2') }} seg
  ON p1.snid = seg.snid
LEFT JOIN UNNEST(SPLIT(COALESCE(seg.all_snt_labels, ''), ',')) AS lbl
LEFT JOIN {{ ref('hcp_signature_labels') }} hsl
  ON TRIM(lbl) = hsl.snt_label

GROUP BY
  p1.snid,
  seg.all_snt_labels