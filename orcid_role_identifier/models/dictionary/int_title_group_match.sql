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

/*
    ⭐ frequency IS JOINED HERE, NOT TAKEN FROM THE EMBEDDING CACHE.
    MEASURED 2026-11-11, analyses/50 query 2g.

    int_title_embeddings is materialized incremental with
    unique_key='title_key', and its incremental filter is
    `title_key not in (select title_key from this)`. So a title already in
    the cache is never in the next run's source set, the MERGE matches
    nothing, and the row is never updated. The EMBEDDING should indeed never
    be recomputed - that is the whole point of the model and where the cost
    saving lives - but `frequency` was sitting in the same row, so it froze
    at whatever the title's record count was the first time that title was
    ever seen, and the entire dictionary downstream read the frozen number.

    HOW WRONG IT HAD GOT. dim_title_group.frequency summed to 30,488,093
    against a live corpus of 1,767,500 - 17.3 times over. Per title it ran 14
    to 30 times high, a different factor each time, because each title froze
    on a different day: `graduate research assistant` 106,438 against 7,304
    live, `professor & director` 2,185 against 74.

    WHAT IT BROKE. Every record figure quoted from the dictionary, which is
    most of the record figures in the seed notes and the status document. And
    frequency_tier and needs_human_review, which compare it against
    tier_a_min_frequency = 50 - at 17x nearly every title cleared tier A, so
    the human review queue was ordered by a number that had not been true for
    months.

    WHAT IT DID NOT BREAK. Nothing about the classification. The embedding,
    the similarity, the group and the score never read frequency. And no
    figure counted from stg_role_records or fct_researcher_roles is affected,
    which is every PEOPLE figure we have ever reported.

    LEFT JOIN, NOT INNER. The cache holds 327,291 titles against 314,716 in
    the corpus today - 12,575 titles that existed once and do not now. An
    inner join would drop them, which would silently change what the override
    and pattern assertions have to match against. They keep their row and
    take frequency 0, so they fall out of the tiering on their own.
*/
with_frequency as (

    select
        m.*,
        coalesce(d.frequency, 0)                                as frequency
    from matches m
    left join {{ ref('int_title_distinct') }} d using (title_key)

),

per_group as (

    select
        title_key,
        title,
        frequency,
        group_key,
        max(similarity)                                         as similarity,
        array_agg(anchor_term order by similarity desc limit 3)  as matched_anchors
    from with_frequency
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
