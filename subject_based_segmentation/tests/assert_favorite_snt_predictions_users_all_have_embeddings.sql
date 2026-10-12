-- A singular test fails if it returns any rows.
-- Proves the post_hook that clears out-of-audience users actually ran. A
-- user with predictions but no row in user_embedding is unreachable: the
-- model's candidates CTE selects FROM user_embedding, so no number of runs
-- can ever refresh them, and their predictions would be served to CDI
-- forever.
--
-- If this fails, check assert_user_embedding_coverage_has_not_collapsed
-- first: the post_hook has a circuit breaker that deliberately skips the
-- cleanup when user_embedding looks under-built, and a trip there explains
-- a failure here.

SELECT p.snid
FROM {{ ref('favorite_snt_predictions') }} p
LEFT JOIN (SELECT DISTINCT snid FROM {{ ref('user_embedding') }}) e
  ON p.snid = e.snid
WHERE e.snid IS NULL
