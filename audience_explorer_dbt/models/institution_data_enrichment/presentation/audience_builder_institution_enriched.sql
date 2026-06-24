with approved as (

    select
        candidate_input,
        ror_id,
        ror_name        as standardized_institution_name,
        ror_country,
        cosine_similarity
    from {{ ref('ror_match_decisions') }}
    where match_status = 'auto_approve'

),

targets as (

    select
        canonical_segment_id,
        email,
        researcher_id,
        snid,
        raw_inst_name,
        embedding_input
    from {{ ref('stg_inst_enrichment_targets') }}

)

select
    t.canonical_segment_id,
    t.email,
    t.researcher_id,
    t.snid,
    t.raw_inst_name                     as original_raw_name,
    a.standardized_institution_name,
    a.ror_id,
    a.ror_country,
    a.cosine_similarity
from targets t
inner join approved a
    on t.embedding_input = a.candidate_input