{{ config(materialized='table') }}

/*
    DEPARTMENT -> DISCIPLINE

    Identical mechanism to int_title_group_match, applied to the field
    that actually carries the discipline.

    Measured margins by group in validation: 0.079 to 0.186, with every
    one of the 12 groups populated and only 1.6% of records left
    unassignable.
*/

with matches as (

    select
        query.department_key,
        query.department,
        query.frequency,
        base.group_key,
        base.anchor_term,
        1 - distance    as similarity
    from vector_search(
        table {{ ref('int_anchor_embeddings') }},      'embedding',
        table {{ ref('int_department_embeddings') }},  'embedding',
        top_k         => 20,
        distance_type => 'COSINE'
    )
    where base.axis = 'discipline'

),

per_group as (

    select
        department_key,
        department,
        frequency,
        group_key,
        max(similarity)                                         as similarity,
        array_agg(anchor_term order by similarity desc limit 3)  as matched_anchors
    from matches
    group by department_key, department, frequency, group_key

),

ranked as (

    select
        *,
        row_number() over (partition by department_key order by similarity desc) as rnk
    from per_group

)

select
    r1.department_key,
    r1.department,
    r1.frequency,
    r1.group_key                                as discipline,
    r1.similarity,
    r2.group_key                                as runner_up,
    r1.similarity - r2.similarity               as margin,
    r1.matched_anchors,

    /*
        ONE GATE: is this value close to any group at all?

        There used to be a second gate on the margin between the first and
        second choice, set at 0.13. It was wrong. That number came from a
        different quantity - the distance to a set of deliberately
        unrelated occupations, in an earlier design that no longer exists.
        Applied to the gap between two of OUR groups it rejected correct
        answers: "associate professor of medicine" failed at a margin of
        0.129, and "medical oncologist" failed with practitioner first and
        trainee_clinical second, when both of those support hcp anyway.

        With 21 groups competing, neighbouring groups are genuinely close
        and a small gap is normal rather than suspicious. The margin is
        still computed and kept - it is a good signal of confidence and
        drives the human review queue - but it no longer vetoes anything.
    */
    case
        when r1.similarity < {{ var('sim_floor') }} then 'REJECTED_LOW_SIMILARITY'
        else 'ACCEPTED'
    end                                         as match_decision,

    (     r1.similarity >= {{ var('sim_floor') }}
      and r1.similarity - r2.similarity < {{ var('sim_review_margin') }}
      and r1.frequency >= {{ var('tier_a_min_frequency') }} )  as needs_human_review

from ranked r1
left join ranked r2 on r1.department_key = r2.department_key and r2.rnk = 2
where r1.rnk = 1
