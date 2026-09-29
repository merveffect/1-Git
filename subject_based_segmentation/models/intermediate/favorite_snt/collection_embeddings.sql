{{ config(materialized='table') }}

-- Embedding of every distinct collection's title+description text.
-- Only ~9.5k distinct collections — far cheaper than the keyword channel
-- (1.8M) or the rejected article-title channel (7.7M), no batching needed.

SELECT
  collection_id,
  collection_text,
  ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(
  MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
  (SELECT collection_id, collection_text, collection_text AS content FROM {{ ref('distinct_collections') }})
)
