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
        -- the column holds a TITLE GROUP (practitioner, researcher_early,
        -- ...), never a role key. It was named role_key until 2026-10-09
        -- and the alias here was the only thing saying otherwise, so an
        -- ACCEPT written with a role name silently did nothing.
        title_group,
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
        else least(1.0, 0.70 + (m.similarity - {{ var('sim_floor') }})
                               / (1.0 - {{ var('sim_floor') }}) * 0.30)
    end                                         as group_score

from matched m
/*
    JOIN ON title_key ALONE.

    This said "using (title_key, title_group)" until 2026-10-09, which
    made the whole override mechanism dead code. Joining on title_group
    as well means an override can only match when it names the group the
    model ALREADY chose - so the one thing an override exists to do,
    move a value to a different group, could never fire. A REJECT could
    not fire either: the seeded example named 'hcp', which is not a title
    group at all, so it matched nothing.

    With the join on title_key, coalesce(o.title_group, m.title_group)
    below does what it looks like it does - an ACCEPT moves the value, and
    a REJECT needs no group because the coalesce falls back to the model's
    and is_assigned goes false.
*/
left join overrides o using (title_key)
