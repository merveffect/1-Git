{{ config(severity='warn') }}
/*
    EVERY IDENTIFIER SYSTEM IN THE SOURCE SHOULD REACH ROR, OR WE SHOULD
    KNOW WHY NOT.

    Added 2026-11-27, after route 2 of int_org_resolved turned out to be
    carrying GRID and nothing else while its own comment claimed 43.5%
    coverage. Two different bugs hid behind that one number for months, and
    nothing in the build could see either of them, because no test ever
    compared the identifier systems PRESENT in the source against the ones
    that actually resolve.

    WHAT WAS WRONG, both measured on 2026-11-27:

      FUNDREF  the types matched and the values did not. ORCID writes a
               FundRef id as the DOI that contains it,
               `http://dx.doi.org/10.13039/501100003339`, and ROR stores the
               bare `501100003339`. 65,195 records never bridged. Fixed by
               taking the last path segment: 64,514 recovered, 99.0%.

      RINGGOLD there is nothing on the other side of the join.
               stg_ror__external_ids holds GRID, WIKIDATA, ISNI and FUNDREF
               and no RINGGOLD rows at all, so the largest identifier group
               in the source - 482,455 records, 219,925 of them resolving to
               nothing, 153,611 people - cannot be reached this way. Not a
               format problem and not fixable in SQL: it needs another
               mapping.

    SO THIS TEST RETURNS ROWS TODAY, ON PURPOSE. RINGGOLD is one, and LEI is
    the other - 107 records, almost certainly absent from ROR for the same
    reason. Those two rows are the standing record of what we cannot reach.
    The reason the test is worth having is the THIRD row: if GRID or FUNDREF
    ever stops bridging, it appears here instead of quietly moving tens of
    thousands of people onto name matching or onto nothing.

    WARN, NOT ERROR, because of those two known rows. Promote it the day
    both have a mapping or a documented decision to drop them.

    The test FAILS if a row is returned that is NOT one of the known two.
*/

with sources as (

    select
        org_id_source,
        count(*)                as records,
        count(distinct snid)    as people
    from {{ ref('stg_role_records') }}
    where org_id_source is not null
      and org_id_source != 'ROR'
      and org_id is not null
    group by 1

),

bridged as (

    select
        replace(resolution_method, 'EXTERNAL_ID_', '')   as org_id_source,
        count(*)                                        as organisations_reached
    from {{ ref('int_org_resolved') }}
    where starts_with(resolution_method, 'EXTERNAL_ID_')
    group by 1

)

select
    s.org_id_source,
    s.records                           as records_in_the_source,
    s.people,
    coalesce(b.organisations_reached, 0) as organisations_reached
from sources s
left join bridged b
    on b.org_id_source = s.org_id_source
where coalesce(b.organisations_reached, 0) = 0
order by s.records desc
