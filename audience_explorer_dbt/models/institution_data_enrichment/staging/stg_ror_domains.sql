With ror as (
    select
        id as ror_id,
        -- primary display name
        (
            select n.value
            from unnest(names) n
            where 'ror_display' in unnest(n.types)
            limit 1
        ) as ror_name,
        -- primary country
        (
            select loc.geonames_details.country_name
            from unnest(locations) loc
            limit 1
        ) as ror_country,
        domains
    from {{ ref('raw_ror_data') }}
),

exploded as (
    select
        lower(trim(domain)) as domain,
        ror_id,
        ror_name,
        ror_country
    from ror, unnest(domains) as domain
    where domain is not null and trim(domain) != ''
),

--if a domain is associated with more than one institution, we will not use it for matching
domain_counts as (
    select domain, count(distinct ror_id) as inst_count
    from exploded
    group by domain
)

select distinct
    exploded.domain,
    exploded.ror_id,
    exploded.ror_name,
    exploded.ror_country
from exploded 
join domain_counts using (domain)
where domain_counts.inst_count = 1
  and not ( {{ is_generic_domain('exploded.domain') }} )