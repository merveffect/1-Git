-- Count distinct HCPs per label
SELECT
  snt_label,
  COUNT(DISTINCT snid) AS hcp_users_with_label
FROM {{ ref('hcp_labels_exploded') }}
GROUP BY snt_label