{{ config(
    materialized="incremental",
    unique_key="snt_id",
    incremental_strategy="merge"
) }}

-- Embedding of every SNT (S&T taxonomy, ~4800 codes) name, used as the
-- comparison set for favorite-SNT inference via vector search.
-- Incremental: only new SNT ids, or existing ids whose name changed, get
-- (re-)embedded on each run — a full re-embed of all ~4800 SNTs isn't needed
-- since the taxonomy source only changes incrementally over time.


WITH snt_names AS (
  SELECT snt_id, snt_name
  FROM {{ ref('snts_full_list') }}
),

to_embed AS (
  SELECT sn.snt_id, sn.snt_name
  FROM snt_names sn
  {% if is_incremental() %}
  WHERE NOT EXISTS (
    SELECT 1 FROM {{ this }} existing
    WHERE existing.snt_id = sn.snt_id
      AND existing.snt_name = sn.snt_name
  )
  {% endif %}
)

SELECT
  snt_id,
  snt_name,
  ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(
  MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
  (SELECT snt_id, snt_name, snt_name AS content FROM to_embed)
)
