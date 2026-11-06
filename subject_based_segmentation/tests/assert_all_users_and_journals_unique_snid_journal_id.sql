-- A singular test fails if it returns any rows.
-- all_users_and_journals is one row per (snid, journal_id): a journal seen in
-- several behaviour lists (read, eTOC, page view...) must count once.

SELECT snid, journal_id, COUNT(*) AS n
FROM {{ ref('all_users_and_journals') }}
GROUP BY snid, journal_id
HAVING COUNT(*) > 1
