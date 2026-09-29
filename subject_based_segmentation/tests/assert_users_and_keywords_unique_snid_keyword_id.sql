-- A singular test fails if it returns any rows.
SELECT snid, keyword_id, COUNT(*) AS n
FROM {{ ref('users_and_keywords') }}
GROUP BY snid, keyword_id
HAVING COUNT(*) > 1
