With extracted as (

    select
        regexp_extract(ror_id, r'ror\.org/(.+)$') as ror_id_code,
        ror_id                                    as ror_id_raw,
        {{ extract_domain_from_url('website') }}  as domain
    from {{ ref('raw_wikidata') }}
    where website is not null and trim(website) != ''

),

cleaned as (

    select
        coalesce(ror_id_code, ror_id_raw) as ror_id,
        domain
    from extracted
    where domain is not null
      and trim(domain) != ''
      and not ( {{ is_generic_domain('domain') }} )

),

-- if a domain is associated with multiple ROR IDs, we cannot use it for enrichment
domain_counts as (
    select domain, count(distinct ror_id) as ror_count
    from cleaned
    group by domain
)

select distinct
    c.domain,
    c.ror_id
from cleaned c
join domain_counts dc using (domain)
where dc.ror_count = 1