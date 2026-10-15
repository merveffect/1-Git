{{ config(materialized='table') }}

-- Nearest-SNT distance per collection, same confidence-weighting purpose as
-- keyword_snt_confidence: down-weight collections whose text doesn't match
-- any SNT well when averaging into a user's embedding. Small scale
-- (~9.5k collections x ~4.8k SNTs).

SELECT
  query.collection_id  AS collection_id,
  base.snt_id            AS nearest_snt_id,
  base.snt_name           AS nearest_snt_name,
  distance
FROM VECTOR_SEARCH(
  TABLE {{ ref('snt_embeddings') }}, 'embedding',
  TABLE {{ ref('collection_embeddings') }}, 'embedding',
  top_k => 1,
  distance_type => 'COSINE'
)
