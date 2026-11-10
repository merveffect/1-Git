{{ config(materialized='view') }}

/*
    ROR ORGANISATION REGISTRY

    WHAT IT IS FOR:
    Scoring needs the organisation TYPE. "Does this person work in a
    hospital, a university, or a bank?" The same title means different
    things in different settings:

        "Director" + hospital   -> healthcare administrator
        "Director" + bank       -> irrelevant

    Deriving the type from the NAME is unreliable ("St. Mary's Hosp." -
    a hospital?). A regex would miss hundreds of variants; this was a
    known weakness in Phase-1.

    ROR gives it to us directly: every organisation has an id and a TYPE.

        ror_id: 013czdx64
        name:   Heidelberg University Hospital
        types:  [Education, Healthcare]       <-- what we need

    These types are scored via seeds/org_type_scores.csv.

    ror_data_refresh is ROR's OWN registry dump (confirmed), not a
    previously produced matching output.

    WHAT WE DELIBERATELY DO NOT TAKE:
    ROR also carries a country per organisation. We ignore it. The country
    we use comes from ORCID itself -
    employments[].organisation_address_country_code - which is recorded per
    POST rather than per organisation and is populated on 100% of records.
    A person can hold a German profile and a UK post, and it is the post we
    are targeting. Carrying two country fields only invited confusion.
*/

with base as (
    select
        id,
        coalesce(
            (
                select n.value
                from unnest(names) n
                where 'ror_display' in unnest(coalesce(n.types, []))
                limit 1
            ),
            (
                select n.value
                from unnest(names) n
                limit 1
            )
        )                                        as canonical_name,
        types,
        external_ids
    from {{ ref('raw_ror_data_refresh') }}
)

select
    id                                          as ror_id,
    canonical_name,
    {{ normalize_title('canonical_name') }}     as organisation,     -- name-match key

    -- types is an ARRAY: a university hospital is both Education and Healthcare
    types                                       as ror_types,

    -- non-ROR identifiers: RINGGOLD / GRID / FUNDREF / ISNI ...
    -- flattened by stg_ror__external_ids
    external_ids

from base
