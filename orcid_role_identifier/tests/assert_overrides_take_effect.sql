/*
    Every row in role_title_overrides must reach dim_title_group and be
    recorded as the decision there: an ACCEPT must land as HUMAN with the
    group the reviewer named, a REJECT as REJECTED and unassigned.

    An override is a human overruling the model after reading the
    evidence. It is the most expensive input in the project and the only
    one that cannot be reproduced, so silence here is the worst failure
    mode we have: the review work looks done and is not applied.

    Catches two real bugs, both silent:
      - the join was `using (title_key, title_group)`, so an override
        could only match when it already named the group the model had
        chosen. Every reassignment - the entire reason the mechanism
        exists - did nothing.
      - the CTE aliased a title-group column as role_key, so an ACCEPT
        written with a role name was dropped.

    A row also fails here if the title has simply disappeared from the
    source. That is worth failing on: it means we are carrying a review
    decision for a title nobody writes any more, and it should be
    retired rather than left to rot in the seed.
*/

with expected as (
    select
        title,
        to_hex(md5({{ normalize_title('title') }})) as title_key,
        title_group                                as expected_group,
        decision
    from {{ ref('role_title_overrides') }}
),

actual as (
    select title_key, title_group, decision_source, is_assigned
    from {{ ref('dim_title_group') }}
)

select
    e.title,
    e.decision,
    e.expected_group,
    a.title_group     as actual_group,
    a.decision_source,
    case
        when a.title_key is null        then 'title not in the dictionary at all'
        when e.decision = 'ACCEPT'
             and (a.decision_source != 'HUMAN'
                  or a.title_group != e.expected_group)
                                        then 'ACCEPT did not take effect'
        when e.decision = 'REJECT'
             and (a.decision_source != 'REJECTED' or a.is_assigned)
                                        then 'REJECT did not take effect'
    end as failure
from expected e
left join actual a using (title_key)
where a.title_key is null
   or (e.decision = 'ACCEPT' and (a.decision_source != 'HUMAN'
                                  or a.title_group != e.expected_group))
   or (e.decision = 'REJECT' and (a.decision_source != 'REJECTED'
                                  or a.is_assigned))
