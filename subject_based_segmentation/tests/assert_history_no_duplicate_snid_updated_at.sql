-- A singular test fails if it returns any rows.
-- The model has no unique_key (it is append-only), so nothing in the
-- warehouse stops a user getting two rows for the same refresh. One
-- (snid, updated_at) is one event, and a duplicate would double-count that
-- user in every change-volume figure read off this table.

SELECT snid, updated_at, COUNT(*) AS row_count
FROM {{ ref('favorite_snt_predictions_history') }}
GROUP BY snid, updated_at
HAVING COUNT(*) > 1
