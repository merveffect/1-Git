-- Select HCP signature subject labels from the behavioral baseline.
-- A signature label is both common among known HCPs and at least 2x
-- more prevalent in HCPs than in the general population. 


SELECT
  snt_label
FROM {{ ref('hcp_behavioral_baseline') }}
WHERE lift_vs_population >= 2.0
  AND hcp_prevalence_rate >= 0.05