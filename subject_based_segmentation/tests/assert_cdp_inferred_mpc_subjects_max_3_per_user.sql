-- A singular test fails if it returns any rows.
-- cdp_inferred_mpc_subjects holds the top 3 inferred MPC subjects per SNID
-- (rn <= 3 in snid_to_mktps_step2). More than 3 IDs means the ranking or the
-- ';'-split of top_3_marketing_pref_ids went wrong.

SELECT
  snid,
  ARRAY_LENGTH(inferred_mpc_subjects) AS n_subjects
FROM {{ ref('cdp_inferred_mpc_subjects') }}
WHERE ARRAY_LENGTH(inferred_mpc_subjects) > 3
