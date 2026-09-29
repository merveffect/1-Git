-- A singular test fails if it returns any rows.
SELECT snid, collection_id, COUNT(*) AS n
FROM {{ ref('users_and_collection_recommendations') }}
GROUP BY snid, collection_id
HAVING COUNT(*) > 1
