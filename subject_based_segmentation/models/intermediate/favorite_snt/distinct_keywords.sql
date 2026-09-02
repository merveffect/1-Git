{{ config(materialized="table") }}

-- Every distinct keyword across the target audience, deduplicated once so
-- keyword_embeddings only ever embeds each unique keyword one time instead
-- of once per (user, keyword) occurrence (~1.8M distinct vs far more rows).
-- keyword_id is a hash of the keyword text so it's stable across runs and
-- usable as a merge key even for very long keyword strings.

WITH parsed AS (
  SELECT
    -- custom \term\,\term\ format (not JSON) — see users_with_content_signal
    REGEXP_EXTRACT_ALL(keywords_last_60d, r'\\([^\\]+)\\') AS keywords
  FROM {{ ref('users_with_content_signal') }}
  WHERE keywords_last_60d IS NOT NULL
)

SELECT DISTINCT
  TO_HEX(MD5(keyword)) AS keyword_id,
  keyword
FROM parsed, UNNEST(keywords) AS keyword
WHERE keyword IS NOT NULL AND TRIM(keyword) != ''
