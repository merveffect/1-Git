/*
    No job title may be claimed by the patterns of two different groups.

    dim_title_group resolves a collision with min(title_group), which is
    deterministic but arbitrary - it would silently pick alphabetically
    and nobody would know a decision had been made. There is one pattern
    group today, so this cannot fire yet; it is here for the second one.
*/

select
    m.title,
    m.frequency,
    count(distinct p.title_group)               as groups_claiming_it,
    string_agg(distinct p.title_group, ', ')     as claimed_by
from {{ ref('dim_title_group') }} m
join {{ ref('title_group_patterns') }} p
    on regexp_contains(m.title, p.name_pattern)
group by m.title, m.frequency
having count(distinct p.title_group) > 1
