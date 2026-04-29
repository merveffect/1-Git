-- Count ALL users per label across the full population
SELECT
  TRIM(lbl) AS snt_label,
  COUNT(DISTINCT snid) AS total_users_with_label
FROM {{ ref('snid_to_mktps_step2') }},
UNNEST(SPLIT(all_snt_labels, ',')) AS lbl
WHERE all_snt_labels IS NOT NULL
  AND TRIM(lbl) != ''
GROUP BY snt_label