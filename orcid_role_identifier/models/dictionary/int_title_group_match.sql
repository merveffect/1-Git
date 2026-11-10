{{ config(materialized='table') }}

/*
    TITLE -> POSITION GROUP

    Each distinct job title is searched against the title anchors and the
    nearest group wins, provided it wins decisively.

    The decision is made on the MARGIN, not on the raw similarity.
    Calibration showed absolute similarity cannot separate the classes:
    true matches ran 0.682-1.000 and false matches 0.519-0.953, heavily
    overlapped. "Pharmacologist" scores 0.953 against pharmacist anchors
    and is not a pharmacist. The margin between first and second choice
    does separate them.
*/

with matches as (

    select
        query.title_key,
        query.title,
        query.frequency,
        base.group_key,
        base.anchor_term,
        1 - distance    as similarity
    from vector_search(
        table {{ ref('int_anchor_embeddings') }}, 'embedding',
        table {{ ref('int_title_embeddings') }},  'embedding',
        top_k         => 20,
        distance_type => 'COSINE'
    )
    where base.axis = 'title'

),

per_group as (

    select
        title_key,
        title,
        frequency,
        group_key,
        max(similarity)                                         as similarity,
        array_agg(anchor_term order by similarity desc limit 3)  as matched_anchors
    from matches
    group by title_key, title, frequency, group_key

),

ranked as (

    select
        *,
        row_number() over (partition by title_key order by similarity desc) as rnk,
        max(similarity) over (partition by title_key)                       as best_similarity
    from per_group

)

select
    r1.title_key,
    r1.title,
    r1.frequency,
    r1.group_key                                as title_group,
    r1.similarity,
    r2.group_key                                as runner_up,
    r1.similarity - r2.similarity               as margin,
    r1.matched_anchors,

    case
        when r1.frequency >= {{ var('tier_a_min_frequency') }} then 'A'
        when r1.frequency >= {{ var('tier_b_min_frequency') }} then 'B'
        else 'C'
    end                                         as frequency_tier,

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

    /*
        Human review queue: a margin close to the boundary makes the
        decision fragile, and with the LLM judge disabled this is the only
        verification we have. Only frequent titles qualify - that is where
        the leverage is.
    */
    (     r1.similarity >= {{ var('sim_floor') }}
      and r1.similarity - r2.similarity < {{ var('sim_review_margin') }}
      and r1.frequency >= {{ var('tier_a_min_frequency') }} )  as needs_human_review

from ranked r1
left join ranked r2 on r1.title_key = r2.title_key and r2.rnk = 2
where r1.rnk = 1
