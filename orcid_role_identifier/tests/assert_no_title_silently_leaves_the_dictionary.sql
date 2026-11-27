{{ config(severity='warn') }}
/*
    A TITLE CAN FALL OUT OF THE DICTIONARY WITHOUT ANYTHING SAYING SO.

    int_title_group_match searches every distinct title against
    int_anchor_embeddings with top_k => 20 and only THEN filters
    `where base.axis = 'title'`. The anchor table holds both axes - 151
    title anchors and 180 discipline anchors, so discipline is the
    majority - and a title whose twenty nearest neighbours are all
    discipline anchors produces NO ROW.

    THAT IS A SILENT LOSS, NOT A REJECTION. dim_title_group is built FROM
    this model: `matched` selects it directly, and the override and pattern
    joins hang off `matched`. So a title with no row is absent from the
    dictionary altogether - it cannot be rescued by a pattern, cannot be
    rescued by a human override, and never appears in the review queue.

    MEASURED 2026-11-27, the first time anybody counted it:

        906 titles, 18,745 records lost on the title side
        806 departments, 29,308 records on the mirror side
          (int_department_embeddings -> int_discipline_match, same shape)
        1  of the 906 would have been claimed by a pattern

    AND THE LOSS IS MOSTLY CORRECT. The dropped titles are `other`,
    `bioinformatics`, `geology`, `chemistry`, `physics`, `school of public
    health`, `iraq`, `sme` - discipline and department names typed into the
    title field. The department side is the exact mirror: `keynote speaker`,
    `editorial board member`, `professor`, `lecturer`, `consultant` - job
    titles typed into the department field. The post-filter is throwing away
    values that are in the wrong field, which is why the damage is 0.28% of
    the dictionary and not a catastrophe.

    WHY THE SEARCH IS NOT BEING RESTRUCTURED. Pre-filtering the anchors to
    one axis would make the loss visible as a REJECTION instead, which is
    better. But it also changes which anchors are the runner-up for every
    title that currently matches, and the decision rule here is the MARGIN
    between first and second choice, not the raw similarity. So the obvious
    fix silently re-decides all 319,032 titles in order to recover one
    pattern-rescuable title. That trade is wrong today. This test exists so
    the number stops being invisible, and so the pattern column below stays
    at the one case we know about.

    WARN, NOT ERROR, and deliberately: it returns one row today. Promote it
    the day `pattern_would_have_claimed_it` reaches zero.
*/

with lost as (
    select e.title_key, e.title, e.frequency
    from {{ ref('int_title_embeddings') }} e
    where not exists (
        select 1 from {{ ref('int_title_group_match') }} m
        where m.title_key = e.title_key
    )
)

select
    count(*)            as titles_lost,
    sum(l.frequency)    as records_lost,
    count(distinct case when p.name_pattern is not null then l.title_key end)
                        as pattern_would_have_claimed_it
from lost l
left join {{ ref('title_group_patterns') }} p
       on regexp_contains(l.title, p.name_pattern)
      and (p.unless_pattern is null
           or p.unless_pattern = ''
           or not regexp_contains(l.title, p.unless_pattern))
having count(*) > 0
