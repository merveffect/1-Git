{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['keyword_id'],
        on_schema_change='fail'
    )
}}

-- Embedding of every distinct keyword (see distinct_keywords). Incremental,
-- capped at 100k new keywords per run: with ~1.8M distinct keywords, both a
-- full re-embed and a single uncapped run are wasteful/slow. Re-running
-- dbt run --select keyword_embeddings repeatedly (or on a schedule) just
-- keeps picking up the next 100k until fully caught up.

with new_keywords as (

    select
        dk.keyword_id,
        dk.keyword
    from {{ ref('distinct_keywords') }} dk

    {% if is_incremental() %}
    where not exists (
        select 1
        from {{ this }} m
        where m.keyword_id = dk.keyword_id
    )
    {% endif %}

    limit 100000

)

select
    keyword_id,
    keyword,
    ml_generate_embedding_result as embedding
from ML.GENERATE_EMBEDDING(
    model `datasn-rm-live.institution_disambiguation.embedding_model`,
    (select keyword_id, keyword, keyword as content from new_keywords)
)
