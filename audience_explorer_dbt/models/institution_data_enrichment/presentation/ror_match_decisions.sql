{{
    config(
        materialized='table'
    )
}}

-- it is possible that the ROR match is a false positive, so we need to make a decision on whether to auto-approve, send for review, or reject.
-- Threshold: 0.97 + ISO match = auto_approve. ISO conflict or low score = review/reject.

with matches as (

    select
        candidate_input,
        candidate_inst_name,
        candidate_country,
        candidate_country_iso,
        ror_id,
        ror_name,
        ror_country,
        ror_country_iso,
        cosine_similarity
    from {{ ref('stg_ror_matches_vector_search') }}

),

decided as (

    select
        *,

        -- is iso match? (case insensitive, trim whitespace)
        case
            when candidate_country_iso is not null
                 and ror_country_iso is not null
                 and upper(trim(candidate_country_iso)) = upper(trim(ror_country_iso))
                then true
            else false
        end as country_iso_match,

        case
            -- high confidence + country consistent -> auto approve
            when cosine_similarity >= 0.97
                 and candidate_country_iso is not null
                 and ror_country_iso is not null
                 and upper(trim(candidate_country_iso)) = upper(trim(ror_country_iso))
                then 'auto_approve'

            -- high score but country conflict (Jeju/Vienna type) -> needs review
            when cosine_similarity >= 0.97
                then 'needs_review'

            -- gray area -> needs review
            when cosine_similarity >= 0.95
                then 'needs_review'

            -- low score -> reject
            else 'reject'
        end as match_status

    from matches

)

select
    candidate_input,
    candidate_inst_name,
    candidate_country,
    candidate_country_iso,
    ror_id,
    ror_name,
    ror_country,
    ror_country_iso,
    cosine_similarity,
    country_iso_match,
    match_status
from decided
