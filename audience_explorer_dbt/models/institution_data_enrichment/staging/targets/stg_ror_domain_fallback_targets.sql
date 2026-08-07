-- Fallback targets for ROR enrichment, based on email domain matching.
with {{ cdp_domain_targets() }}

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