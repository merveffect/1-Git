-- A singular test fails if it returns any rows.
-- The model's central promise: a refresh that produces the same ten SNTs in
-- the same order writes nothing. Two consecutive rows for one user with an
-- identical fingerprint mean that promise broke, and the change-volume
-- numbers would then be counting restamps as real changes.
--
-- This is what makes "4,088 users changed yesterday" trustworthy: without
-- it, the figure could just as well be 250,000 users being re-stamped.

WITH sequenced AS (
  SELECT
    snid,
    fingerprint,
    updated_at,
    LAG(fingerprint) OVER (PARTITION BY snid ORDER BY updated_at) AS previous_fingerprint
  FROM {{ ref('favorite_snt_predictions_history') }}
)

SELECT snid, updated_at, fingerprint
FROM sequenced
WHERE previous_fingerprint = fingerprint
