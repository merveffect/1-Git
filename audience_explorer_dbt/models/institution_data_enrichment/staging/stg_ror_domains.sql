with exploded as (

    select
        lower(trim(domain))     as domain,
        r.ror_id,
        r.ror_display_name      as ror_name,
        r.ror_country_name      as ror_country
    from {{ ref('stg_ror') }} as r,
    unnest(r.domains) as domain
    where domain is not null and trim(domain) != ''

),

-- if a domain is associated with more than one institution, reject
domain_counts as (
    select domain, count(distinct ror_id) as inst_count
    from exploded
    group by domain
)

select distinct
    e.domain,
    e.ror_id,
    e.ror_name,
    e.ror_country
from exploded e
join domain_counts c using (domain)
where c.inst_count = 1
  and not ( {{ is_generic_domain('e.domain') }} )
