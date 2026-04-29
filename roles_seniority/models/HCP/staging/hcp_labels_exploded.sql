-- Explode SNT labels for known HCPs
SELECT
  k.snid,
  TRIM(lbl) AS snt_label
FROM {{ ref('hcp_known_hcps') }} k
JOIN {{ ref('snid_to_mktps_step2') }} seg
  ON k.snid = seg.snid,
UNNEST(SPLIT(seg.all_snt_labels, ',')) AS lbl
WHERE seg.all_snt_labels IS NOT NULL
  AND TRIM(lbl) != ''