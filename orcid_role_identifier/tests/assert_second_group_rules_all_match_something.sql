{{ config(severity = 'warn') }}
/*
    Every rule in title_group_second must claim at least one real title.

    A dead rule is the silent failure mode of this whole mechanism: a
    mistyped pattern, or one scoped to a group whose titles never contain the
    words, does nothing at all and leaves the audiences exactly as they were.
    Merve's 11 November decision would simply not have happened, and nothing
    would say so. The same test exists for title_group_patterns.

    WARN RATHER THAN ERROR, deliberately. An error here skips every
    downstream model, which turns one dead rule into a blocked build - and we
    would rather read the warning after a build that finished than discover
    it by not getting one. Treat a warning from this test as work, not noise.
*/
with hits as (
    select
        s.applies_when_title_group,
        s.second_title_group,
        count(*)                  as titles_claimed,
        sum(d.frequency)          as records_claimed
    from {{ ref('title_group_second') }} s
    left join {{ ref('dim_title_group') }} d
           on regexp_contains(d.title, s.name_pattern)
          and d.title_group = s.applies_when_title_group
          and d.is_assigned
          and (s.unless_pattern is null
               or s.unless_pattern = ''
               or not regexp_contains(d.title, s.unless_pattern))
    group by s.applies_when_title_group, s.second_title_group
)
select * from hits where coalesce(titles_claimed, 0) = 0
