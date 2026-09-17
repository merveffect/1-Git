{{ config(materialized='table') }}

-- (snid, collection_id) pairs, mirroring users_and_keywords.sql.

SELECT DISTINCT snid, collection_id
FROM {{ ref('users_and_collection_recommendations') }}
WHERE collection_id IS NOT NULL
