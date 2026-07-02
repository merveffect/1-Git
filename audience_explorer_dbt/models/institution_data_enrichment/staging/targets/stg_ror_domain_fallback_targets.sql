-- Fallback targets for ROR enrichment, based on email domain matching.

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

)

select
    with_domain.canonical_segment_id,
    with_domain.email,
    with_domain.researcher_id,
    with_domain.snid,
    with_domain.institution_name as raw_inst_name,
    with_domain.email_domain,
    ror.ror_id,
    ror.ror_name    as standardized_institution_name,
    ror.ror_country as ror_country,
    'Domain_ROR_match'           as enrichment_source
from with_domain
inner join {{ ref('stg_ror_domains') }} as ror
    on with_domain.email_domain = ror.domain
where with_domain.email_domain is not null
