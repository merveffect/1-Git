{{ config(materialized='table') }}

-- Every distinct collection recommended to any user, deduplicated once.
-- Title + description (HTML-stripped) combined into one text field to
-- embed downstream — title is always present, description (when present)

WITH deduped AS (
  SELECT
    collection_id,
    ANY_VALUE(title) AS title,
    ANY_VALUE(description) AS description
  FROM {{ ref('users_and_collection_recommendations') }}
  WHERE collection_id IS NOT NULL AND title IS NOT NULL
  GROUP BY collection_id
)

SELECT
  collection_id,
  title,
  REGEXP_REPLACE(description, r'<[^>]+>', ' ') AS description_clean,
  CONCAT(
    title,
    IF(description IS NOT NULL, CONCAT('. ', REGEXP_REPLACE(description, r'<[^>]+>', ' ')), '')
  ) AS collection_text
FROM deduped
