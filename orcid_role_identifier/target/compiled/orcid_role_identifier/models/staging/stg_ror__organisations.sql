

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

    !! VERIFY COLUMN NAMES:
       bq show --schema ri-data-engineering-dd4c0eca:ror.ror_data_refresh
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
        cast(null as string)                     as ror_country_code,
        external_ids
    from `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_raw`.`raw_ror_data_refresh`
)

select
    id                                          as ror_id,
    canonical_name,
    
    NULLIF(TRIM(REGEXP_REPLACE(
        
    NULLIF(
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    LOWER(NORMALIZE_AND_CASEFOLD(COALESCE(canonical_name, ''), NFKC)),
                    r'[^\p{L}\p{N}\s&/+-]', ' '
                ),
                r'\s+', ' '
            )
        ),
        ''
    )

,
        r'\s+', ' '
    )), '')
     as organisation,     -- name-match key

    -- types is an ARRAY: a university hospital is both Education and Healthcare
    types                                       as ror_types,

    ror_country_code,

    -- non-ROR identifiers: RINGGOLD / GRID / FUNDREF / ISNI ...
    -- flattened by stg_ror__external_ids
    external_ids

from base