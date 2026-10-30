{{ config(materialized='table') }}

/*
    ⭐ DICTIONARY 1 — title to position group

    One row per distinct job title. Three ways a title gets its group,
    in this order of precedence:

      HUMAN   seeds/role_title_overrides.csv - a reviewer decided, and it
              always wins.
      PATTERN seeds/title_group_patterns.csv - the title literally
              contains the word. No similarity involved, so no doubt.
      VECTOR  the embedding's nearest anchor group, scored by similarity.

    PATTERN exists because of librarian. That group was tried twice with
    anchors and failed both times - 69% then 71% of its records below 0.75
    similarity - because 'librarian' is a ONE-WORD profession and the
    architecture asks every group for at least five anchors. Four of the
    five are then forced to be compounds, and each compound attracted its
    generic half: 'library manager' pulled 'manager' (17,340 records),
    'library officer' pulled every officer in the labour market, 'chief
    librarian' pulled chief technology officer.

    The embedding was being asked to guess something we already know for
    certain. A job title containing 'librarian' is a librarian. So the
    group has no anchors at all now, which also means it can never appear
    as a VECTOR_SEARCH result and can never take a value from another
    group. Narrower on purpose, and certain instead of probable.

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
),

/*
    A title matching a pattern IS that group - no score, no threshold.
    min() picks deterministically if two groups ever claim one title;
    assert_title_patterns_do_not_collide fails the build if they do.
*/
pattern_hits as (
    select
        m.title_key,
        min(p.title_group) as title_group
    from matched m
    join {{ ref('title_group_patterns') }} p
        on regexp_contains(m.title, p.name_pattern)
       /*
           A pattern may be scoped to the group the MODEL chose, which is
           what m.title_group still is at this point - before this join and
           before the override. Empty means unconditional, which is every
           librarian row.

           Measured 2026-10-30, analyses/30: an unconditional leadership
           pattern for `head of department` and `dean` would have moved
           ~14,500 records out of eight groups that have nothing to do with
           faculty leadership, because `head of X` and `dean` are modifiers
           rather than professions - they attach to any job and so override
           the profession word standing next to them in the same string.
           `head of department of cardiology` stopped being a clinician and
           `cluster pharmacy manager & head of department` stopped being a
           pharmacist, which was 2.7% of that whole group.

           Scoping the pattern to one group removes that by construction:
           the other groups are never consulted.
       */
       and (p.applies_when_title_group is null
            or p.applies_when_title_group = ''
            or p.applies_when_title_group = m.title_group)
    group by m.title_key
)

select
    m.title_key,
    m.title,
    m.frequency,
    coalesce(o.title_group, pt.title_group, m.title_group) as title_group,

    /*
        The model's own choice, kept alongside the resolved one. Without it
        a group-scoped pattern cannot be tested: the two pattern assertions
        join back to this model, and once a pattern has fired the title is
        no longer in the group the pattern was conditioned on, so the test
        would be circular and would silently pass.
    */
    m.title_group                                         as model_title_group,
    m.similarity,
    m.margin,
    m.runner_up,
    m.matched_anchors,
    m.frequency_tier,
    m.needs_human_review,

    case
        when o.human_decision = 'ACCEPT' then true
        when o.human_decision = 'REJECT' then false
        when pt.title_group is not null  then true
        else m.match_decision = 'ACCEPTED'
    end                                         as is_assigned,

    case
        when o.human_decision is not null         then 'HUMAN'
        when pt.title_group is not null           then 'PATTERN'
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
        when pt.title_group is not null    then 1.0
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
left join overrides o     using (title_key)
left join pattern_hits pt using (title_key)
