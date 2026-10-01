

/*
    ORCID employments[] -> COMMON ROLE RECORD SCHEMA

    This model is ORCID-specific, but its OUTPUT is source-agnostic:
    every new source (web scraping, CDP self-reported, ...) produces the
    same columns and they meet in stg_role_records.

    The visibility filter was applied in the raw layer - not repeated here.
*/

with flattened as (

    select
        r.snid,
        r.orcid_id,
        r.last_updated_at,
        e.ordering,

        -- raw text, kept for evidence and traceability
        e.role                                          as role_title_raw,
        e.organisation_name                             as organisation_raw,
        e.department_name                               as department_raw,

        -- normalised text - all matching runs on these
        
    NULLIF(TRIM(REGEXP_REPLACE(
        
    NULLIF(
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    LOWER(NORMALIZE_AND_CASEFOLD(COALESCE(e.role, ''), NFKC)),
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
                 as role_title,
        
    NULLIF(TRIM(REGEXP_REPLACE(
        
    NULLIF(
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    LOWER(NORMALIZE_AND_CASEFOLD(COALESCE(e.organisation_name, ''), NFKC)),
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
    as organisation,
        
    NULLIF(TRIM(REGEXP_REPLACE(
        
    NULLIF(
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    LOWER(NORMALIZE_AND_CASEFOLD(COALESCE(e.department_name, ''), NFKC)),
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
      as department,

        -- ORCID's own organisation identifier: ROR / GRID / RINGGOLD
        e.disambiguated_organisation_id                 as org_id,
        upper(e.disambiguated_organisation_source)      as org_id_source,

        -- per-record country, more accurate than the profile country
        e.organisation_address_country_code             as country_code,

        e.full_start_date                               as start_date,
        e.full_end_date                                 as end_date

    from `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_raw`.`raw_orcid_researchers` r,
    unnest(r.employments) e

)

select
    snid,
    orcid_id,
    role_title_raw,
    role_title,
    organisation_raw,
    organisation,
    department_raw,
    department,
    org_id,
    org_id_source,
    country_code,
    start_date,
    end_date,
    ordering,
    last_updated_at                                     as source_last_updated
from flattened
where role_title is not null