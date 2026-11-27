{{ config(materialized='table') }}

/*
    ORGANISATION RESOLUTION - three routes.

    MEASURED DISTRIBUTION (38.6M employment records):
        ROR        35.3%   -> direct join, no matching needed
        RINGGOLD   31.7%   -> bridged via ROR external_ids
        no id      21.2%   -> name matching
        GRID        7.8%   -> bridged via ROR external_ids
        FUNDREF     4.0%   -> bridged via ROR external_ids
        LEI         0.0%

    organisation_name is 100% populated, so name matching is always
    available as the fallback.

    Routes are tried in order; the first hit wins.
*/

with employment_orgs as (

    select distinct
        organisation,
        org_id,
        org_id_source
    from {{ ref('stg_role_records') }}
    where organisation is not null

),

ror as (

    select ror_id, organisation, canonical_name, ror_types
    from {{ ref('stg_ror__organisations') }}

),

-- ROUTE 1: ORCID's own ROR id (free, exact)
by_ror_id as (

    select
        o.organisation,
        o.org_id,
        r.ror_id,
        r.canonical_name,
        r.ror_types,
        'ORCID_ROR_ID'      as resolution_method,
        1.0                 as resolution_confidence
    from employment_orgs o
    join ror r
      on o.org_id_source = 'ROR'
     and o.org_id = r.ror_id

),

/*
    ROUTE 2: bridge through other identifier systems

    THIS SAID `RINGGOLD 31.7% + GRID 7.8% + FUNDREF 4.0% = 43.5%` UNTIL
    2026-11-27. MEASURED THAT DAY, THE ROUTE WAS CARRYING GRID AND NOTHING
    ELSE - 113,857 records of 1,808,514, 6.3%, against the 43.5% promised:

        ROR direct          744,335   41.2%
        EXTERNAL_ID_GRID    113,857    6.3%
        NAME_EXACT          414,060   22.9%
        unresolved          536,262   29.7%

    TWO SEPARATE CAUSES, and only one of them is fixable here.

    FUNDREF - FIXED BELOW. The types matched and the VALUES did not. ORCID
    writes a FundRef id as the DOI that contains it,
    `http://dx.doi.org/10.13039/501100003339`, while ROR stores the bare
    `501100003339`. So 65,195 records never bridged: 39,957 were rescued by
    ROUTE 3 at 0.90 confidence and 25,238 resolved to nothing at all.
    Taking the last path segment recovers 64,514 of them - 99.0%, 54,414
    people - forecast before the change and then VERIFIED AFTER THE BUILD AT
    EXACTLY 64,514 / 54,414. FUNDREF+UNRESOLVED fell 25,238 -> 566 and
    FUNDREF+NAME_EXACT 39,957 -> 115. The 681 that still miss are left alone;
    they are either malformed or genuinely absent from ROR.

    AND THE WORRY ABOUT THIS CHANGE WAS WRONG, which is worth recording
    because it was the reason for measuring. FundRef is a FUNDER registry, so
    the fear was that the 39,957 records already rescued by name - sitting at
    a university, ROR type education, org_score 1.00 - would be re-pointed at
    a funding agency and scored down, since an identifier match at 0.95 beats
    a name match at 0.90. The opposite is true. Of the 64,514 bridged records:

        education   48,205   74.7%
        funder       8,405   13.0%
        facility     4,227
        company      1,735
        government     672
        healthcare     599
        nonprofit      436
        other          138
        archive         97

    Three quarters of FundRef ids point at UNIVERSITIES, not at funders -
    universities fund research, so they are in the registry. Only 13% are
    actual funding bodies.

    WHAT IT MOVED: +866 people across the audiences and NOT ONE LOST. students
    +630, hcp_researcher +128, hcp_practitioner +57, hcp_administrator +29,
    researcher +16, lecturer +2, pharmacist +2, hcp_broad +1, faculty_head +1,
    librarian 0. Small against 54,414 people gaining an employer, and that is
    the expected shape: org_score carries a 0.40 weight at most, so the change
    only flips people who were already sitting on their threshold. students
    moves most because it is the audience that leans hardest on an education
    employer. hcp_broad gains only 1 while its three children gain 214, which
    is the roll-up behaving correctly - those people were already CONFIRMED in
    the parent at its lower 0.60 threshold and have now cleared the children's
    0.70.

    THE EXTRACTION IS A NO-OP FOR EVERY OTHER SOURCE, which is why it is
    applied unconditionally rather than wrapped in a CASE: GRID ids read
    `grid.4991.5`, Ringgold and LEI ids are bare, and none of them contains
    a slash, so the expression returns them unchanged.

    RINGGOLD - NOT FIXABLE HERE. stg_ror__external_ids carries no RINGGOLD
    rows at all: GRID, WIKIDATA, ISNI, FUNDREF and nothing else. This is not
    a format problem, there is nothing on the other side of the join. It is
    the LARGEST identifier group in the source - 482,455 records, of which
    219,925 (153,611 people) resolve to nothing - and reaching it needs
    another mapping, not another join.

    ACCEPTED 2026-11-27 AS A KNOWN LIMIT, after measuring what it costs:
    127,816 of those 153,611 people (83.2%) are already CONFIRMED in some
    audience on their title alone, 6,102 reach only PROBABLE, and 19,693 are
    in nothing. The whole upside of a Ringgold mapping is a ceiling of 6,102
    people, which does not justify sourcing a commercial registry. Not a bug.
    The full reasoning is in the block comment in stg_ror__external_ids.sql.
*/
by_external_id as (

    select
        o.organisation,
        o.org_id,
        r.ror_id,
        r.canonical_name,
        r.ror_types,
        concat('EXTERNAL_ID_', o.org_id_source)     as resolution_method,
        0.95                                        as resolution_confidence
    from employment_orgs o
    join {{ ref('stg_ror__external_ids') }} x
      on x.id_type  = o.org_id_source
     -- the last path segment, so ORCID's DOI-wrapped FundRef ids reach ROR's
     -- bare ones. A no-op for every id that contains no slash - see above.
     and x.id_value = regexp_extract(coalesce(o.org_id, ''), r'([^/]+)$')
    join ror r
      on r.ror_id = x.ror_id
    where o.org_id_source != 'ROR'
      and not exists (
          select 1 from by_ror_id b
          where b.organisation = o.organisation
            and b.org_id is not distinct from o.org_id
      )

),

-- ROUTE 3: name matching (no identifier; organisation_name is always populated)
by_name as (

    select
        o.organisation,
        o.org_id,
        r.ror_id,
        r.canonical_name,
        r.ror_types,
        'NAME_EXACT'        as resolution_method,
        0.9                 as resolution_confidence
    from employment_orgs o
    join ror r
      on o.organisation = r.organisation
    where not exists (
        select 1 from by_ror_id b
        where b.organisation = o.organisation
          and b.org_id is not distinct from o.org_id
    )
    and not exists (
        select 1 from by_external_id x
        where x.organisation = o.organisation
          and x.org_id is not distinct from o.org_id
    )

),

combined as (
    select * from by_ror_id
    union all
    select * from by_external_id
    union all
    select * from by_name
)

select
    organisation,
    org_id,
    ror_id,
    canonical_name,
    ror_types,
    resolution_method,
    resolution_confidence
from combined
qualify row_number() over (
    partition by organisation, org_id
    -- TIE-BREAKER ADDED 2026-11-27. resolution_confidence takes one of three
    -- values - 1.0 ORCID_ROR_ID, 0.95 EXTERNAL_ID, 0.9 NAME_EXACT - so two
    -- candidates resolved by the same method tie exactly, and row_number()
    -- then picked between them arbitrarily. The same organisation could
    -- resolve to a different ROR id from one build to the next, which moves
    -- org_type, which moves org_score, which can move a person across a
    -- threshold. Nothing downstream would report it.
    order by resolution_confidence desc, ror_id, resolution_method, canonical_name
) = 1
