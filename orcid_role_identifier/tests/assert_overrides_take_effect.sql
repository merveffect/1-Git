/*
    Every row in role_title_overrides must reach dim_title_group and be
    recorded as the decision there: an ACCEPT lands as HUMAN carrying the
    group the reviewer named, a REJECT lands as HUMAN with is_assigned
    false and group_score 0.

    Both are HUMAN. decision_source answers WHO decided, not what they
    decided, and 'REJECTED' is reserved for the vector failing to clear
    sim_floor. That distinction is load-bearing: a human REJECT should
    never be reopened, while a vector rejection should go back into the
    review queue, and collapsing them into one value would lose the only
    thing that tells them apart. The first version of this test asserted
    REJECT -> 'REJECTED' and failed on all 25 rejections, which was the
    test being wrong rather than the pipeline.

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
    select title_key, title_group, decision_source, is_assigned, group_score
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
             and (a.decision_source != 'HUMAN' or a.is_assigned
                  or a.group_score != 0.0)
                                        then 'REJECT did not take effect'
    end as failure
from expected e
left join actual a using (title_key)
where a.title_key is null
   or (e.decision = 'ACCEPT' and (a.decision_source != 'HUMAN'
                                  or a.title_group != e.expected_group))
   or (e.decision = 'REJECT' and (a.decision_source != 'HUMAN'
                                  or a.is_assigned
                                  or a.group_score != 0.0))
