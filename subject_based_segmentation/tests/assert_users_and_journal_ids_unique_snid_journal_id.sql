-- A singular test fails if it returns any rows.
SELECT snid, journal_id, COUNT(*) AS n
FROM {{ ref('users_and_journal_ids') }}
GROUP BY snid, journal_id
HAVING COUNT(*) > 1
