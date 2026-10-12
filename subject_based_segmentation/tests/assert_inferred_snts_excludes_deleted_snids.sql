-- A singular test fails if it returns any rows.
-- The CDI-facing guarantee: nothing about a deleted user leaves this
-- pipeline, matching what cdp_inferred_mpc_subjects does on the MPC side.

SELECT s.snid
FROM {{ ref('inferred_snts') }} s
JOIN {{ source('prod_mpc_dbt_presentation', 'snid_deletions') }} d
  ON d.snid = s.snid
