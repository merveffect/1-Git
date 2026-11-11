{{ config(severity = 'warn') }}
/*
    How often two rules claim one title with DIFFERENT second groups.

    dim_title_group resolves it with min(), which is deterministic and
    therefore safe, but it drops a claim - and a title naming three jobs is a
    real question rather than a defect. `professor, researcher and director`
    is both a leadership and a research claim on a teaching title, and min()
    keeps `leadership` because it sorts first.

    WARN RATHER THAN ERROR for that reason: the number is what we want, not a
    stopped build. If it is large, the answer is a third column, and that is
    a decision with a measurement behind it rather than a bug to fix.
*/
with claims as (
    select
        d.title_key,
        d.title,
        d.frequency,
        d.title_group,
        s.second_title_group
    from {{ ref('dim_title_group') }} d
    join {{ ref('title_group_second') }} s
         on regexp_contains(d.title, s.name_pattern)
        and d.title_group = s.applies_when_title_group
        and s.second_title_group != d.title_group
        and (s.unless_pattern is null
             or s.unless_pattern = ''
             or not regexp_contains(d.title, s.unless_pattern))
    where d.is_assigned
)
select
    title_key,
    title,
    frequency,
    title_group,
    string_agg(distinct second_title_group order by second_title_group) as claimed_by
from claims
group by title_key, title, frequency, title_group
having count(distinct second_title_group) > 1
