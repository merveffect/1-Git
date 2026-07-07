With vector_enriched as (

    select
        targets.canonical_segment_id,
        targets.email,
        targets.researcher_id,
        targets.snid,
        targets.raw_inst_name        as original_raw_name,
        targets.enrichment_source,
        ror_matches.ror_name             as standardized_institution_name,
        ror_matches.ror_id,
        ror_matches.ror_country,
        1                      as priority
    from {{ ref('stg_inst_enrichment_targets') }} targets
    inner join {{ ref('stg_ror_match_decisions') }} ror_matches
        on targets.embedding_input = ror_matches.candidate_input
        and ror_matches.match_status = '1 to 1 match'

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

wikidata_ror_enriched as (

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
        3                      as priority
    from {{ ref('stg_wikidata_fallback_targets') }}

),

wikidata_name_enriched as (
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
        4                      as priority
    from {{ ref('stg_wikidata_names_fallback_targets') }}
),

unioned as (
    select * from vector_enriched
    union all
    select * from domain_enriched
    union all
    select * from wikidata_ror_enriched
    union all
    select * from wikidata_name_enriched
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