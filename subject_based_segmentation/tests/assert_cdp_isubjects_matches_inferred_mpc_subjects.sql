-- A singular test fails if it returns any rows.
-- isubjects exists purely so CDI can pick either column name, so the two must
-- never drift apart. BigQuery cannot compare ARRAY columns with !=, hence the
-- TO_JSON_STRING comparison — which also catches NULL vs [] ('null' vs '[]').

SELECT
  snid,
  TO_JSON_STRING(inferred_mpc_subjects) AS inferred_mpc_subjects_json,
  TO_JSON_STRING(isubjects) AS isubjects_json
FROM {{ ref('cdp_inferred_mpc_subjects') }}
WHERE TO_JSON_STRING(inferred_mpc_subjects) != TO_JSON_STRING(isubjects)
