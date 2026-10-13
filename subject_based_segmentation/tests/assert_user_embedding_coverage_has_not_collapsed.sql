-- A singular test fails if it returns any rows.
-- Reports when the circuit breaker in favorite_snt_predictions' second
-- post_hook has tripped. That hook deletes predictions for users missing
-- from user_embedding, which is the right thing when someone genuinely
-- leaves the target audience — and the wrong thing if user_embedding was
-- built from incomplete upstream data, because it would wipe predictions
-- for real users.
--
-- The hook therefore only deletes while user_embedding still covers >= 90%
-- of the users we hold predictions for. This test surfaces the other side
-- of that guard: if coverage has collapsed, the cleanup was skipped on
-- purpose and the upstream build needs looking at, not the hook.

WITH counts AS (
  SELECT
    (SELECT COUNT(DISTINCT snid) FROM {{ ref('user_embedding') }}) AS embedding_users,
    (SELECT COUNT(DISTINCT snid) FROM {{ ref('favorite_snt_predictions') }}) AS predicted_users
)

SELECT embedding_users, predicted_users
FROM counts
WHERE embedding_users < 0.9 * predicted_users
