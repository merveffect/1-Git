/*
    Every pattern in excluded_employers must match at least one organisation in
    the data. A pattern that matches nothing is either a typo or an employer
    nobody in ORCID works for, and both are worth knowing: this list removes
    PEOPLE, so a dead pattern is a rule we believe is protecting us and is not.

    LEFT JOIN AND GROUP BY RATHER THAN NOT EXISTS. The first version of this
    test used NOT EXISTS with only a regexp_contains condition and BigQuery
    refused it - "LEFT ANTISEMI JOIN cannot be used without a condition that is
    an equality of fields from both sides of the join". An anti-join needs an
    equality; a LEFT JOIN does not. This is the same shape
    assert_title_patterns_all_match_something already uses.

    What this test CANNOT catch, stated so nobody trusts it too far: a pattern
    that matches the wrong thing still matches something. `springer` unanchored
    matched `martin springer center for conflict studies`, and `macmillan`
    matched `macmillan cancer support`, a cancer charity. Both were found by
    reading the matched organisation list before committing, and that reading
    is not replaced by this test. It catches the opposite failure - a pattern
    that has stopped matching because the spelling in the data moved.
*/

with hits as (

    select
        x.name_pattern,
        x.category,
        count(r.snid) as matched_records
    from {{ ref('excluded_employers') }} x
    left join {{ ref('stg_role_records') }} r
        on regexp_contains(coalesce(r.organisation, ''), x.name_pattern)
    group by 1, 2

)

select name_pattern, category, matched_records
from hits
where matched_records = 0
