{{ config(materialized='table') }}

/*
    ⭐ DICTIONARY 1 — title to position group

    One row per distinct job title. Human decisions in
    seeds/role_title_overrides.csv always win.

    Nothing downstream of this model runs AI.
*/

with matched as (
    select * from {{ ref('int_title_group_match') }}
),

overrides as (
    select
        to_hex(md5({{ normalize_title('title') }}))  as title_key,
        role_key                                     as title_group,
        decision                                     as human_decision,
        reviewer
    from {{ ref('role_title_overrides') }}
)

select
    m.title_key,
    m.title,
    m.frequency,
    coalesce(o.title_group, m.title_group)      as title_group,
    m.similarity,
    m.margin,
    m.runner_up,
    m.matched_anchors,
    m.frequency_tier,
    m.needs_human_review,

    case
        when o.human_decision = 'ACCEPT' then true
        when o.human_decision = 'REJECT' then false
        else m.match_decision = 'ACCEPTED'
    end                                         as is_assigned,

    case
        when o.human_decision is not null         then 'HUMAN'
        when m.match_decision = 'ACCEPTED'        then 'VECTOR'
        else 'REJECTED'
    end                                         as decision_source,

    /*
        Graded rather than binary. A title that separates cleanly scores
        full marks; one sitting near the threshold scores less, so the
        confidence carries through to the person's final score.
    */
    case
        when o.human_decision = 'ACCEPT'   then 1.0
        when o.human_decision = 'REJECT'   then 0.0
        when m.match_decision != 'ACCEPTED' then 0.0
        else least(1.0, 0.70 + (m.margin - {{ var('sim_min_margin') }}) * 2)
    end                                         as group_score

from matched m
left join overrides o using (title_key, title_group)
