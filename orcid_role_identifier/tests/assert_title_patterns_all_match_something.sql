/*
    Every pattern in title_group_patterns must match at least one real
    job title.

    The same guard as assert_org_patterns_all_match_something, and for the
    same reason: \buniversit\b taught us that a regex matching nothing is
    not a harmless no-op but a rule we believe is running and that is not.
    These patterns are now the ONLY way into the librarian group, so a
    dead one is a silently missing audience rather than a slightly worse
    score.

    Same convention as assert_overrides_take_effect, and for the same
    reason: a pattern can match nothing because it was written ahead of
    the vocabulary, or because it is wrong, and those look identical. So
    the author declares which. [pre-emptive] in the note allows a pattern
    to match nothing; anything else matching nothing fails.

    Three carry the marker: kütüphane, 図書館 and 图书馆. Every other
    pattern has a measured title behind it - librarian 3,798 records,
    bibliotecário 158, bibliothécaire 32, bibliothèque 10,
    'директор библиотеки' 16, 'директор бібліотеки' 11. The Turkish,
    Japanese and Chinese stems are the ones ORCID has nobody for yet,
    which is worth knowing in itself: it says where this audience does
    not reach, not that the pattern is broken.

    A non-Latin pattern going dead AFTER having matched would be the
    alarming case - more likely our normalisation lost the characters
    than that the librarians left.
*/

with hits as (
    select
        p.title_group,
        p.name_pattern,
        count(m.title)      as matched_titles,
        sum(m.frequency)    as matched_records,
        coalesce(p.note, '')    as note
    from {{ ref('title_group_patterns') }} p
    left join {{ ref('dim_title_group') }} m
        on regexp_contains(m.title, p.name_pattern)
    group by 1, 2, 5
)

select title_group, name_pattern, matched_titles, matched_records
from hits
where matched_titles = 0
  and not contains_substr(note, '[pre-emptive]')
