-- Vector 1:1 matches -> user grain (joined with targets).
select
    targets.canonical_segment_id,
    targets.email,
    targets.researcher_id,
    targets.snid,
    targets.raw_inst_name,
    targets.enrichment_source,
    ror_matches.ror_name         as standardized_institution_name,
    ror_matches.ror_id,
    ror_matches.ror_country
from {{ ref('stg_inst_enrichment_targets') }} targets
inner join {{ ref('stg_ror_match_decisions') }} ror_matches
    on targets.embedding_input = ror_matches.candidate_input
    and ror_matches.match_status = '1 to 1 match'