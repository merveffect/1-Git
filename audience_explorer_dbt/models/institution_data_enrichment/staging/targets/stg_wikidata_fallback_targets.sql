With cdp as (

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
        c.canonical_segment_id,
        c.email,
        c.researcher_id,
        c.snid,
        c.institution_name as raw_inst_name,
        c.email_domain,
        w.ror_id
    from with_domain c
    inner join {{ ref('stg_wikidata_domains') }} w
        on c.email_domain = w.domain
    where c.email_domain is not null
),

-- name comes from ROR table, not from WikiData table, because we want to use the standardized name from ROR
ror_names as (
    select
        regexp_extract(r.ror_id, r'ror\.org/(.+)$') as ror_id,
        r.ror_display_name,
        r.ror_country_name
    from {{ ref('stg_ror') }} r
)

select
    m.canonical_segment_id,
    m.email,
    m.researcher_id,
    m.snid,
    m.raw_inst_name,
    m.email_domain,
    m.ror_id,
    r.ror_display_name  as standardized_institution_name,
    r.ror_country_name  as ror_country,
    'WIKIDATA_ROR_NAME' as enrichment_source
from matched m
inner join ror_names r
    on m.ror_id = r.ror_id

qualify row_number() over (
    partition by canonical_segment_id
    order by email
) = 1