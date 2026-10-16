/*
    Every regex in org_name_patterns must match at least one real
    organisation name. A pattern that matches nothing is not a safe
    no-op: it is a scoring rule we believe is running and that silently
    is not.

    Catches: \buniversit\b. A trailing word boundary after a prefix stem
    can never match "university", so the two most valuable patterns in
    the seed never fired once, and the org axis quietly fell back to its
    default for every unresolved organisation. It took three wrong
    hypotheses to find, because nothing failed.
*/

with orgs as (
    select distinct organisation
    from {{ ref('stg_role_records') }}
    where organisation is not null
),

hits as (
    select
        p.role_key,
        p.name_pattern,
        count(o.organisation) as matched_organisations
    from {{ ref('org_name_patterns') }} p
    left join orgs o
        on regexp_contains(o.organisation, p.name_pattern)
    group by 1, 2
)

select *
from hits
where matched_organisations = 0
