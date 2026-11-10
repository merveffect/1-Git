/*
    ============================================================================
    41. WHICH TITLES TWO PATTERNS CLAIM AT ONCE
    ============================================================================
    The build of 2026-11-10 failed on assert_title_patterns_do_not_collide
    with 2 results, which skipped 29 downstream nodes and left every
    audience count unchanged. That is the test doing its job: without it,
    dim_title_group resolves a collision with min(title_group), picking
    alphabetically and saying nothing.

    This is the test's own query without the HAVING, so it NAMES the titles
    instead of counting them. Query 1 after a fix should return no rows.

    THE SUSPECTED CAUSE, and query 1 either confirms it or does not. The
    librarian rows are the only UNSCOPED patterns in the seed - eleven of
    them, one per script, claiming any title with a library stem anywhere
    in it. The student row added for 1.17 is scoped to researcher. A title
    the model put in researcher that names BOTH a student and a library is
    claimed by both. The library stems have been added to the student
    veto, which is the shape the pharmacist-scoped rows already use: a
    title naming the competing group keeps the model's group and the other
    pattern claims it alone.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE COLLISIONS, NAMED. Should be empty.
--
--    The join conditions are copied from dim_title_group deliberately. A
--    scoped pattern only claims a title the MODEL put in that group, and
--    the comparison is against model_title_group rather than title_group
--    because after a pattern fires the title has left the group the
--    pattern was conditioned on - joining on the resolved group would be
--    circular and would always pass.
-- ----------------------------------------------------------------------------
select
    m.title,
    m.frequency,
    m.model_title_group,
    count(distinct p.title_group)             as groups_claiming_it,
    string_agg(distinct p.title_group, ', ')  as claimed_by
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` m
join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.title_group_patterns` p
    on regexp_contains(m.title, p.name_pattern)
       and (p.applies_when_title_group is null
            or p.applies_when_title_group = ''
            or p.applies_when_title_group = m.model_title_group)
       and (p.unless_pattern is null
            or p.unless_pattern = ''
            or not regexp_contains(m.title, p.unless_pattern))
where m.decision_source != 'HUMAN'
group by m.title, m.frequency, m.model_title_group
having count(distinct p.title_group) > 1
order by m.frequency desc
;


-- ----------------------------------------------------------------------------
-- 2. EVERY PATTERN'S REACH, so a collision can be read rather than hunted.
--
--    titles_claimed counts what each row actually takes after its own
--    scope and veto. A row claiming far more or far less than its note
--    says is the thing to look at, collision or not.
-- ----------------------------------------------------------------------------
select
    p.title_group,
    coalesce(p.applies_when_title_group, '(unscoped)')  as scope,
    substr(p.name_pattern, 1, 44)                       as pattern_head,
    if(coalesce(p.unless_pattern, '') = '', 'no veto', 'has veto') as veto,
    count(distinct m.title)                             as titles_claimed,
    sum(m.frequency)                                    as records_claimed
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.title_group_patterns` p
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` m
    on regexp_contains(m.title, p.name_pattern)
       and (p.applies_when_title_group is null
            or p.applies_when_title_group = ''
            or p.applies_when_title_group = m.model_title_group)
       and (p.unless_pattern is null
            or p.unless_pattern = ''
            or not regexp_contains(m.title, p.unless_pattern))
group by p.title_group, scope, pattern_head, veto
order by records_claimed desc
;
