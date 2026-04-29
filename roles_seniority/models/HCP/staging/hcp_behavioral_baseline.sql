-- Combine HCP and population label counts, compute lift metrics
SELECT
  h.snt_label,
  h.hcp_users_with_label,
  a.total_users_with_label,
  ht.n                                                              AS total_hcps,
  tu.n                                                              AS total_population,

  -- What fraction of HCPs have this subject label?
  ROUND(SAFE_DIVIDE(h.hcp_users_with_label, ht.n), 4)              AS hcp_prevalence_rate,

  -- Of all users who have this label, what fraction are HCPs?
  ROUND(SAFE_DIVIDE(h.hcp_users_with_label, a.total_users_with_label), 4) AS label_hcp_density,

  -- Lift: how much MORE prevalent is this label in HCPs vs. the general pop?
  ROUND(
    SAFE_DIVIDE(
      SAFE_DIVIDE(h.hcp_users_with_label, ht.n),              -- HCP prevalence
      SAFE_DIVIDE(a.total_users_with_label, tu.n)             -- population prevalence
    ), 4
  )                                                                 AS lift_vs_population,

  CURRENT_TIMESTAMP()                                               AS baseline_created_ts

FROM {{ ref('hcp_label_counts') }}  h
JOIN {{ ref('hcp_all_users_labels') }}   a ON h.snt_label = a.snt_label
CROSS JOIN (SELECT COUNT(*) AS n FROM {{ ref('hcp_known_hcps') }}) ht
CROSS JOIN (SELECT COUNT(DISTINCT snid) AS n FROM {{ ref('snid_to_mktps_step2') }}) tu

ORDER BY lift_vs_population DESC