{{ config(
    materialized="incremental",
    unique_key="keyword_id",
    incremental_strategy="merge"
) }}

-- Embedding of every distinct keyword (see distinct_keywords). Incremental:
-- only keyword_ids not already embedded get processed each run — with ~1.8M
-- distinct keywords, a full re-embed every run would be wasteful.

WITH to_embed AS (
  SELECT dk.keyword_id, dk.keyword
  FROM {{ ref('distinct_keywords') }} dk
  {% if is_incremental() %}
  WHERE NOT EXISTS (
    SELECT 1 FROM {{ this }} existing
    WHERE existing.keyword_id = dk.keyword_id
  )
  {% endif %}
)

SELECT
  keyword_id,
  keyword,
  ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(
  MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
  (SELECT keyword_id, keyword, keyword AS content FROM to_embed)
)
