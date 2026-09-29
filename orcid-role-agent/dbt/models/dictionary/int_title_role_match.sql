{{ config(materialized='table') }}

/*
    ============================================================================
    VECTOR SEARCH RESULT + DECISION
    ============================================================================
    Calibration (analyses/02, 37 test titles) showed:

      ABSOLUTE SIMILARITY DOES NOT SEPARATE THE CLASSES
        true matches   0.682 - 1.000
        false matches  0.519 - 0.953     <-- heavy overlap
        "pharmacologist" scores 0.953 against pharmacist anchors but is
        not a pharmacist. No single absolute threshold splits these.

      WHAT DOES SEPARATE THEM: THE DISTRACTOR MARGIN
        '__distractor' is a pseudo-role holding common occupations that
        are none of our targets (software engineer, hr manager, lawyer...).
        The question is no longer "how similar is this title to the role"
        but "how much MORE similar is it to the role than to unrelated
        occupations?"
        true matches:  minimum +0.13
        false matches: mostly NEGATIVE, highest +0.12

      MULTI-LABEL MUST SURVIVE
        An earlier "best role must beat the runner-up" rule would have
        rejected titles that genuinely belong to two roles, such as
        "Professor of Cardiology". Instead sim_tie_band accepts EVERY
        role within 0.12 of the best. The runner-up is not penalised
        because both can be true at the same time.
    ============================================================================
*/

with matches as (

    select
        query.title_key,
        query.title,
        query.frequency,
        base.role_key,
        base.anchor_term,
        base.polarity,
        1 - distance     as similarity
    from vector_search(
        table {{ ref('int_anchor_embeddings') }}, 'embedding',
        table {{ ref('int_title_embeddings') }},  'embedding',
        top_k           => 20,
        distance_type   => 'COSINE'
    )

),

-- target roles: best include / exclude anchor per role
per_role as (

    select
        title_key,
        title,
        frequency,
        role_key,
        max(if(polarity = 'include', similarity, null))  as include_similarity,
        max(if(polarity = 'exclude', similarity, null))  as exclude_similarity,
        array_agg(
            if(polarity = 'include', anchor_term, null) ignore nulls
            order by similarity desc limit 3
        )                                                as matched_anchors
    from matches
    where role_key != '__distractor'
    group by title_key, title, frequency, role_key

),

-- reference point: how close is the title to non-target occupations?
distractor as (

    select
        title_key,
        max(similarity)                                  as distractor_similarity,
        array_agg(anchor_term order by similarity desc limit 2) as nearest_distractors
    from matches
    where role_key = '__distractor'
    group by title_key

),

combined as (

    select
        r.*,
        coalesce(d.distractor_similarity, 0.0)          as distractor_similarity,
        d.nearest_distractors,

        -- ⭐ THE PRIMARY MEASURE
        r.include_similarity
            - coalesce(d.distractor_similarity, 0.0)    as distractor_margin,

        -- best role for this title (used by the multi-label tie band)
        max(r.include_similarity) over (partition by r.title_key) as best_role_similarity

    from per_role r
    left join distractor d using (title_key)
    where r.include_similarity is not null

)

select
    title_key,
    title,
    frequency,
    role_key,
    include_similarity,
    exclude_similarity,
    distractor_similarity,
    distractor_margin,
    best_role_similarity,
    nearest_distractors,
    matched_anchors,

    -- a role-specific exclude anchor closer than the include anchor is a trap
    coalesce(exclude_similarity, 0) > include_similarity as blocked_by_exclusion,

    -- within the tie band of the best role? (multi-label)
    include_similarity >= best_role_similarity - {{ var('sim_tie_band') }}
                                                        as within_tie_band,

    case
        when frequency >= {{ var('tier_a_min_frequency') }} then 'A'
        when frequency >= {{ var('tier_b_min_frequency') }} then 'B'
        else 'C'
    end                                                 as frequency_tier,

    case
        -- 1. role-specific exclusion (caught 9 of 15 false matches in calibration)
        when coalesce(exclude_similarity, 0) > include_similarity
            then 'REJECTED_EXCLUSION'

        -- 2. floor filter
        when include_similarity < {{ var('sim_floor') }}
            then 'REJECTED_LOW_SIMILARITY'

        -- 3. closer to non-target occupations, or margin too small
        when include_similarity - distractor_similarity < {{ var('sim_min_margin') }}
            then 'REJECTED_DISTRACTOR'

        -- 4. far from the best role - another role is clearly a better fit
        when include_similarity < best_role_similarity - {{ var('sim_tie_band') }}
            then 'REJECTED_BETTER_ROLE_EXISTS'

        else 'ACCEPTED'
    end                                                 as match_decision,

    /*
        Human review queue: a margin close to the boundary makes the
        decision fragile. With the LLM judge disabled this is the only
        verification mechanism we have - and it only covers FREQUENT
        titles (tier A), which is where the leverage is.
    */
    (     include_similarity - distractor_similarity >= {{ var('sim_min_margin') }}
      and include_similarity - distractor_similarity <  {{ var('sim_review_margin') }}
      and frequency >= {{ var('tier_a_min_frequency') }} ) as needs_human_review

from combined
