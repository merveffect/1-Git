-- A singular test fails if it returns any rows.
-- All 10 of a user's rows come from the same refresh, so they must share one
-- computed_at. More than one distinct value means the post_hook that clears
-- superseded rows did not run or did not work.

SELECT snid, COUNT(DISTINCT computed_at) AS distinct_computed_at
FROM {{ ref('favorite_snt_predictions') }}
GROUP BY snid
HAVING COUNT(DISTINCT computed_at) > 1
