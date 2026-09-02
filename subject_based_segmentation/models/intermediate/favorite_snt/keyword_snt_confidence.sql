{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['keyword_id'],
        on_schema_change='fail'
    )
}}

-- Nearest-SNT distance per keyword, used as a confidence signal when building
-- per-user embeddings: ambiguous/niche keywords (e.g. "Mpro", "Ciona" —
-- observed via manual spot-check to land far from any SNT, distance > ~0.33)
-- get down-weighted rather than contributing equally with confident matches
-- (e.g. "Alport Syndrome", distance ~0.007). The actual weighting formula is
-- applied downstream where user embeddings are built, not baked in here.
--
-- Incremental, capped at 50k new keywords per run (VECTOR_SEARCH scales with
-- query_rows x base_rows, so this is far more expensive per row than
-- keyword_embeddings' ML.GENERATE_EMBEDDING call). Re-running
-- dbt run --select keyword_snt_confidence repeatedly (or on a schedule) just
-- keeps picking up the next 50k until fully caught up.

with new_keywords as (

    select
        ke.keyword_id,
        ke.keyword,
        ke.embedding
    from {{ ref('keyword_embeddings') }} ke

    {% if is_incremental() %}
    where not exists (
        select 1
        from {{ this }} m
        where m.keyword_id = ke.keyword_id
    )
    {% endif %}

    limit 50000

),

vs_results as (

    select
        query.keyword_id      as keyword_id,
        query.keyword         as keyword,
        base.snt_id            as nearest_snt_id,
        base.snt_name          as nearest_snt_name,
        distance
    from vector_search(
        table {{ ref('snt_embeddings') }}, 'embedding',
        table new_keywords, 'embedding',
        top_k => 1,
        distance_type => 'COSINE'
    )

)

select
    keyword_id,
    keyword,
    nearest_snt_id,
    nearest_snt_name,
    distance
from vs_results
