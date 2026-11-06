-- A singular test fails if it returns any rows.
-- A user's inferred_mpc_subjects must not repeat a subject: the top 3 are
-- three different MPC subjects.

SELECT
  snid,
  TO_JSON_STRING(inferred_mpc_subjects) AS inferred_mpc_subjects_json
FROM {{ ref('cdp_inferred_mpc_subjects') }}
WHERE ARRAY_LENGTH(inferred_mpc_subjects)
   != (SELECT COUNT(DISTINCT id) FROM UNNEST(inferred_mpc_subjects) AS id)
