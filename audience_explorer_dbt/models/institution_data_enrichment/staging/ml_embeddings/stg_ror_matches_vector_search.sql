-- It matches each candidate against the ROR reference table and returns the closest match (top_k=1).
-- VECTOR_SEARCH: It finds the closest ROR name for each candidate (top_k=1).

{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['candidate_input'],
        on_schema_change='fail',
        tags=['skip_if_empty']
    )
}}

with new_candidates as (

    select
        embedding_input,
        inst_name,
        country_name,
        country_iso,
        embedding
    from {{ ref('stg_institution_embeddings') }}

    {% if is_incremental() %}
    where not exists (
        select 1
        from {{ this }} m
        where m.candidate_input = embedding_input
    )
    {% endif %}
    limit 100000

),

vs_results as (

    select
        query.embedding_input   as candidate_input,
        query.inst_name         as candidate_inst_name,
        query.country_iso       as candidate_country_iso,
        query.country_name      as candidate_country,
        base.ror_id             as ror_id,
        base.ror_country_iso    as ror_country_iso,
        base.ror_display_name   as ror_name,
        base.ror_country_name   as ror_country,
        (1 - distance)          as cosine_similarity
    from vector_search(
        table {{ ref('stg_ror_embeddings') }}, 'embedding',
        table new_candidates, 'embedding',
        top_k => 1,
        distance_type => 'COSINE'
    )

)

select
    candidate_input,
    candidate_inst_name,
    candidate_country_iso,
    candidate_country,
    ror_id,
    ror_name,
    ror_country_iso,
    ror_country,
    cosine_similarity
from vs_results