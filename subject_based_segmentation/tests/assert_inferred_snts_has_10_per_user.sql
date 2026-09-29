-- A singular test fails if it returns any rows.
-- Every snid in inferred_snts (the CDI output table) should have exactly
-- 10 rows — one per predicted SNT (favorite_rank 1 to 10 in
-- favorite_snt_predictions). Anything else means a user got dropped or
-- duplicated somewhere in the pipeline.

SELECT
  snid,
  COUNT(*) AS snt_count
FROM {{ ref('inferred_snts') }}
GROUP BY snid
HAVING COUNT(*) != 10
