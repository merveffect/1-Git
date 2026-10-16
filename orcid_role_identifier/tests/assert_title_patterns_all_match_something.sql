/*
    Every pattern in title_group_patterns must match at least one real
    job title.

    The same guard as assert_org_patterns_all_match_something, and for the
    same reason: \buniversit\b taught us that a regex matching nothing is
    not a harmless no-op but a rule we believe is running and that is not.
    These patterns are now the ONLY way into the librarian group, so a
    dead one is a silently missing audience rather than a slightly worse
    score.

    The non-Latin patterns are the ones to watch - 図書館, 图书馆,
    библиотек, бібліотек, kütüphane. If one of them matches nothing it is
    more likely our normalisation lost the characters than that no such
    librarian exists.
*/

with hits as (
    select
        p.title_group,
        p.name_pattern,
        count(m.title)      as matched_titles,
        sum(m.frequency)    as matched_records
    from {{ ref('title_group_patterns') }} p
    left join {{ ref('dim_title_group') }} m
        on regexp_contains(m.title, p.name_pattern)
    group by 1, 2
)

select * from hits where matched_titles = 0
