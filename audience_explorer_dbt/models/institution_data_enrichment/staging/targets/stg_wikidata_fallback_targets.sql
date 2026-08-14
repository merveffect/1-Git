with {{ cdp_domain_targets() }},

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
    concat('https://ror.org/', m.ror_id) as ror_id,   
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