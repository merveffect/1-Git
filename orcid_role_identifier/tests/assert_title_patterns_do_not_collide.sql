/*
    No job title may be claimed by the patterns of two different groups.

    dim_title_group resolves a collision with min(title_group), which is
    deterministic but arbitrary - it would silently pick alphabetically
    and nobody would know a decision had been made. There is one pattern
    group today, so this cannot fire yet; it is here for the second one.

    A pattern scoped with applies_when_title_group only claims a title the
    MODEL put in that group, so the condition below has to match the one in
    dim_title_group or the test asks a different question than the model
    answers. It compares against model_title_group rather than title_group
    for the same reason: after a pattern fires, the title has left the group
    the pattern was conditioned on, and a test joining on the resolved group
    would be circular and would always pass.

    Measured 2026-10-30 against a candidate leadership pattern set: three
    titles collide, 14 records, all librarian -
    `associate dean of library services`,
    `associate dean library services and archives`,
    `head of department of library and information science`. Scoped to
    teaching_academic they do not collide at all, because all three are
    librarian in the model.
*/

select
    m.title,
    m.frequency,
    count(distinct p.title_group)               as groups_claiming_it,
    string_agg(distinct p.title_group, ', ')     as claimed_by
from {{ ref('dim_title_group') }} m
join {{ ref('title_group_patterns') }} p
    on regexp_contains(m.title, p.name_pattern)
       and (p.applies_when_title_group is null
            or p.applies_when_title_group = ''
            or p.applies_when_title_group = m.model_title_group)
group by m.title, m.frequency
having count(distinct p.title_group) > 1
