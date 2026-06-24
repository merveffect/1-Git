{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='embedding_input',
        on_schema_change='append_new_columns'
    )
}}

with src as (

    select
        cand.inst_name,
        cand.country_name,
        cand.country_iso,
        cand.embedding_input,
        cand.embedding_input as content
    from {{ ref('stg_institution_enrichment_candidates') }} as cand

    {% if is_incremental() %}
    where not exists (
        select 1
        from {{ this }} t
        where t.embedding_input = cand.embedding_input
    )
    {% endif %}

),

embeddings as (

    select
        inst_name,
        country_name,
        country_iso,
        content as embedding_input,
        ml_generate_embedding_result as embedding,
        ml_generate_embedding_status as embedding_status
    from ml.generate_embedding(
        model `datasn-rm-live.institution_disambiguation.embedding_model`,
        (select inst_name, country_name, country_iso, embedding_input, content from src),
        struct(
            true as flatten_json_output,
            'SEMANTIC_SIMILARITY' as task_type
        )
    )

)

select
    inst_name,
    country_name,
    country_iso,
    embedding_input,
    embedding,
    embedding_status
from embeddings
where embedding_status = ''