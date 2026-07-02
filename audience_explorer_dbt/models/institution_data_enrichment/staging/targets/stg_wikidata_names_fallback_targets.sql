-- Final fallback: WikiData name-based enrichment for missing ROR IDs.
-- For people where domain matching didn't yield official ROR enrichment,
-- try matching via WikiData.

with cdp as (

    select
        canonical_segment_id,
        email,
        researcher_id,
        snid,
        institution_name
    from {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
    where (mkt_pref_opt_in = true or is_legitimate_interest_author_opted_in = true)
      and (institution_name is null or trim(institution_name) = '')
      and email is not null

),

with_domain as (

    select
        *,
        {{ extract_email_domain('email') }} as email_domain
    from cdp

),

-- WikiData: email domain -> ror_id
matched as (
    select
        with_domain.canonical_segment_id,
        with_domain.email,
        with_domain.researcher_id,
        with_domain.snid,
        with_domain.institution_name as raw_inst_name,
        with_domain.email_domain,
        wikidata.ror_id
    from with_domain 
    inner join {{ ref('stg_wikidata_domains') }} wikidata
        on with_domain.email_domain = wikidata.domain
    where with_domain.email_domain is not null
),

-- Filter to ror_ids that do NOT exist in official ROR data
missing_from_ror as (
    select m.*
    from matched m
    left join {{ ref('stg_ror') }} stg_ror
        on m.ror_id = stg_ror.ror_id
    where stg_ror.ror_id is null
),

-- Get institution names from WikiData
with_names as (
    select
        missing_from_ror.canonical_segment_id,
        missing_from_ror.email,
        missing_from_ror.researcher_id,
        missing_from_ror.snid,
        missing_from_ror.raw_inst_name,
        missing_from_ror.ror_id,
        raw_wikidata.institution_name as standardized_institution_name,
        cast(null as string) as ror_country,
        'WIKIDATA_NAME' as enrichment_source
    from missing_from_ror 
    inner join {{ ref('raw_wikidata') }} raw_wikidata
        on missing_from_ror.ror_id = raw_wikidata.ror_id
)

select
    canonical_segment_id,
    email,
    researcher_id,
    snid,
    raw_inst_name,
    ror_id,
    standardized_institution_name,
    ror_country,
    enrichment_source
from with_names

qualify row_number() over (
    partition by canonical_segment_id
    order by email
) = 1