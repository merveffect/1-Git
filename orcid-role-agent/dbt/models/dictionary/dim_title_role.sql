{{ config(materialized='table') }}

/*
    ⭐ THE DICTIONARY - THE MOST VALUABLE ASSET IN THIS PROJECT

    "Which job title belongs to which role?" One row = (title, role).
    A title CAN belong to more than one role (multi-label).

    Built once, then joined onto the person-level table. After this
    model no AI runs anywhere in the pipeline.
*/

with matched as (

    select * from {{ ref('int_title_role_match') }}

),

judged as (

    {% if var('use_llm_judge') %}
    select title_key, role_key, judge_accepted, judge_status
    from {{ ref('int_title_role_judged') }}
    {% else %}
    -- LLM judge disabled (no Vertex connection). Empty table.
    select
        cast(null as string) as title_key,
        cast(null as string) as role_key,
        cast(null as bool)   as judge_accepted,
        cast(null as string) as judge_status
    where false
    {% endif %}

),

overrides as (

    -- Human decisions always win. May be empty.
    select
        to_hex(md5({{ normalize_title('title') }}))  as title_key,
        role_key,
        decision                                     as human_decision,
        reviewer,
        reviewed_at
    from {{ ref('role_title_overrides') }}

),

combined as (

    select
        m.title_key,
        m.title,
        m.role_key,
        m.frequency,
        m.include_similarity,
        m.distractor_margin,
        m.distractor_similarity,
        m.match_decision,
        m.frequency_tier,
        m.needs_human_review,
        m.matched_anchors,
        j.judge_accepted,
        o.human_decision,
        o.reviewer,

        case
            when o.human_decision is not null     then o.human_decision = 'ACCEPT'
            when m.match_decision = 'ACCEPTED'    then true
            when m.match_decision = 'NEEDS_JUDGE' then coalesce(j.judge_accepted, false)
            else false
        end                                          as is_role_member,

        case
            when o.human_decision is not null     then 'HUMAN'
            when m.match_decision = 'ACCEPTED'    then 'VECTOR'
            when m.match_decision = 'NEEDS_JUDGE' then 'LLM_JUDGE'
            else 'REJECTED'
        end                                          as decision_source

    from matched m
    left join judged    j using (title_key, role_key)
    left join overrides o using (title_key, role_key)

)

select
    *,
    /*
        The title's role score (the equivalent of Phase-1's role_score).
        Graded rather than binary - a real improvement, because
        "consultant cardiologist" and "clinical fellow" no longer score
        identically. Scaled by the distractor margin: titles that
        separate cleanly score full marks, borderline ones score less.
    */
    case
        when not is_role_member         then 0.0
        when decision_source = 'HUMAN'  then 1.0
        else least(1.0, 0.70 + (distractor_margin - {{ var('sim_min_margin') }}) * 2)
    end                                              as role_score
from combined
where is_role_member
   or needs_human_review        -- rejected rows stay for the review queue
