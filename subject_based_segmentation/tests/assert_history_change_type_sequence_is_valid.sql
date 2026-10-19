-- A singular test fails if it returns any rows.
-- A user's first row must be 'new' and every later one 'changed'. That is
-- the whole contract of change_type, and it depends on the last_recorded
-- lookup finding the previous row: if that lookup ever breaks, a returning
-- user is logged as 'new' again and first_seen_at resets, silently making
-- every user look newer than they are.

WITH sequenced AS (
  SELECT
    snid,
    change_type,
    updated_at,
    ROW_NUMBER() OVER (PARTITION BY snid ORDER BY updated_at) AS event_number
  FROM {{ ref('favorite_snt_predictions_history') }}
)

SELECT snid, event_number, change_type, updated_at
FROM sequenced
WHERE (event_number = 1 AND change_type != 'new')
   OR (event_number > 1 AND change_type != 'changed')
