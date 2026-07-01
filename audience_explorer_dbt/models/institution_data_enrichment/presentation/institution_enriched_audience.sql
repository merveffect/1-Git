With vector_enriched as (

    select
        t.canonical_segment_id,
        t.email,
        t.researcher_id,
        t.snid,
        t.raw_inst_name        as original_raw_name,
        t.enrichment_source,
        a.ror_name             as standardized_institution_name,
        a.ror_id,
        a.ror_country,
        1                      as priority
    from {{ ref('stg_inst_enrichment_targets') }} t
    inner join {{ ref('stg_ror_match_decisions') }} a
        on t.embedding_input = a.candidate_input
        and a.match_status = '1 to 1 match'

),

domain_enriched as (

    select
        canonical_segment_id,
        email,
        researcher_id,
        snid,
        raw_inst_name          as original_raw_name,
        enrichment_source,
        standardized_institution_name,
        ror_id,
        ror_country,
        2                      as priority
    from {{ ref('stg_ror_domain_fallback_targets') }}

),

unioned as (

    select * from vector_enriched
    union all
    select * from domain_enriched

)

select
    canonical_segment_id,
    email,
    researcher_id,
    snid,
    original_raw_name,
    enrichment_source,
    standardized_institution_name,
    ror_id,
    ror_country
from unioned
qualify row_number() over (
    partition by canonical_segment_id
    order by priority
) = 1