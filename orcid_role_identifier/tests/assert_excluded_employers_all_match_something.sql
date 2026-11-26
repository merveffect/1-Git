/*
    Every pattern in excluded_employers must match at least one organisation
    in the data. A pattern that matches nothing is either a typo or an
    employer nobody in ORCID works for, and both are worth knowing: this list
    removes PEOPLE, so a dead pattern is a rule we believe is protecting us
    and is not.

    It is also the regression guard on the two patterns that were deliberately
    narrowed. `springer` is anchored because unanchored it matched `martin
    springer center for conflict studies`; `macmillan` was dropped entirely
    because it matched `macmillan cancer support`. Neither mistake announces
    itself - the pattern still matches something, just the wrong thing - so
    this test cannot catch them. It catches the opposite failure, a pattern
    that has stopped matching at all because the spelling in the data moved.
*/

select
    x.name_pattern,
    x.category
from {{ ref('excluded_employers') }} x
where not exists (
    select 1
    from {{ ref('stg_role_records') }} r
    where regexp_contains(coalesce(r.organisation, ''), x.name_pattern)
)
