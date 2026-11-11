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
        -- the column holds a TITLE GROUP (practitioner, researcher,
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
       /*
           unless_pattern VETOES A PATTERN FOR ONE TITLE. Added 2026-11-05
           for the named-chair pattern, which moves `endowed chair`,
           `chair professor of x` and `canada research chair` from
           leadership to teaching_academic. RE2 has no negative lookahead,
           so the pattern alone also took `vice chair for research` (a real
           departmental post, 23 people across faculty_head and
           hcp_administrator) and `dean and chair professor`. A title that
           ALSO names a leadership post keeps the model's group.
           Empty means no veto, which is every row written before it.
       */
       and (p.unless_pattern is null
            or p.unless_pattern = ''
            or not regexp_contains(m.title, p.unless_pattern))
       /*
           WHY THERE IS NO `and m.match_decision = 'ACCEPTED'` HERE.

           It was there for one build, on the argument that conditioning on
           a group the model had rejected would rescue what sim_floor exists
           to hold back. analyses/31 query 9 measured what it held back, and
           the argument did not survive the evidence: 34 titles, about 578
           records, and every one of them a plain faculty leadership post -

             professor head of school director of japan pacific ict centre   0.649
             endowed professor in nursing associate dean for research        0.642
             professor and head of school of computing on medway campus      0.649

           They all sit between 0.567 and 0.649, just under the 0.65 line,
           and they sit there because they are VERBOSE rather than because
           they are ambiguous - a long descriptive string dilutes every
           anchor it contains. The floor exists to stop the embedding
           guessing; a literal pattern match is not a guess, and the model
           agreeing on the group is corroboration rather than the evidence.
       */
    group by m.title_key
),

/*
    RESOLUTION, LIFTED OUT OF THE FINAL SELECT.

    It used to be a coalesce in the select list. It is a CTE now because
    second_hits below has to be scoped to the group the title ACTUALLY
    ends up in, not the one the model guessed - a title the model put in
    researcher and an override moved to teaching_academic has to be read
    as teaching_academic when we ask whether it also names a leadership
    post. Nothing about the primary answer changes.
*/
resolved as (

    select
        m.*,
        coalesce(o.title_group, pt.title_group, m.title_group) as title_group_resolved,
        o.human_decision,
        pt.title_group                                         as pattern_title_group,
        case
            when o.human_decision = 'ACCEPT' then true
            when o.human_decision = 'REJECT' then false
            when pt.title_group is not null  then true
            else m.match_decision = 'ACCEPTED'
        end                                                    as is_assigned_resolved

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

        With the join on title_key, the coalesce above does what it looks
        like it does - an ACCEPT moves the value, and a REJECT needs no group
        because the coalesce falls back to the model's and is_assigned goes
        false.
    */
    left join overrides o     using (title_key)
    left join pattern_hits pt using (title_key)

),

/*
    ⭐ A TITLE MAY NAME TWO JOBS - MERVE, 2026-11-11.

    "Eger bir kisi profesor ve lecturer yazdiysa ORCID'deki role title'ina,
    o zaman ikisi de dogru ve ikisini de o audience a almamiz gerekiyor."

    Reverses the 2026-10-30 decision in 1.10a. A title belonged to exactly
    one group, and that single constraint produced the clearest piece of
    nonsense in the whole dictionary: `professor and director` reached Head
    of Faculty while `professor & director` reached Lecturer, because the
    embedding reads a separator. 68,000 records were sorted by punctuation.

    WHY A SECOND COLUMN AND NOT A SECOND ROW. Fanning dim_title_group out to
    one row per (title, group) would multiply every record in
    int_employment_scored, change the grain of everything downstream and
    break fct_researcher_roles' uniqueness test. A second column leaves the
    grain alone: one row per title, and the role filter in
    int_employment_scored asks about both columns instead of one.

    THE LIMIT OF THE DECISION, because it is easy to over-read. This fires
    only where the TITLE ITSELF names two jobs. It is not a mechanism for
    reconciling our answer with what somebody told a survey - where ORCID
    says only `professor`, the person is a lecturer and that is the end of
    it. analyses/29's gap is not what this fixes.

    PATTERN, SO THE SCORE IS 1.0. A literal match is not a guess, which is
    the same reasoning pattern_hits already carries.

    min() picks deterministically if two rules claim one title with
    different second groups. assert_second_group_rules_do_not_collide
    reports how often, at warn severity rather than error: a third group is
    a real question and not a defect, and silently dropping one is what the
    test exists to make visible.
*/
second_hits as (

    select
        r.title_key,
        min(s.second_title_group) as title_group_2
    from resolved r
    join {{ ref('title_group_second') }} s
        on regexp_contains(r.title, s.name_pattern)
       and s.applies_when_title_group = r.title_group_resolved
       /*
           A rule can never restate the group the title already has. Without
           this, a mirror pair - teaching->leadership and leadership->teaching
           - would hand a title naming both jobs its own group back as the
           "second" one, and the title would look like it had two when it had
           one.
       */
       and s.second_title_group != r.title_group_resolved
       and (s.unless_pattern is null
            or s.unless_pattern = ''
            or not regexp_contains(r.title, s.unless_pattern))
    /*
        A rejected title has no first group, so it cannot have a second.
        Without this a REJECTed title would acquire a group through the back
        door and re-enter the audiences it was rejected from.
    */
    where r.is_assigned_resolved
    group by r.title_key

)

select
    r.title_key,
    r.title,
    r.frequency,
    r.title_group_resolved                                as title_group,

    /*
        ⭐ THE SECOND GROUP. Null for the overwhelming majority of titles.
        Where it is set, the person qualifies for the audiences of BOTH
        groups - see the block comment above second_hits.
    */
    sh.title_group_2,
    if(sh.title_group_2 is not null, 1.0, cast(null as float64)) as group_2_score,

    /*
        The model's own choice, kept alongside the resolved one. Without it
        a group-scoped pattern cannot be tested: the two pattern assertions
        join back to this model, and once a pattern has fired the title is
        no longer in the group the pattern was conditioned on, so the test
        would be circular and would silently pass.
    */
    r.title_group                                         as model_title_group,
    r.match_decision = 'ACCEPTED'                         as model_is_assigned,
    r.similarity,
    r.margin,
    r.runner_up,
    r.matched_anchors,
    r.frequency_tier,
    r.needs_human_review,

    r.is_assigned_resolved                                as is_assigned,

    case
        when r.human_decision is not null         then 'HUMAN'
        when r.pattern_title_group is not null    then 'PATTERN'
        when r.match_decision = 'ACCEPTED'        then 'VECTOR'
        else 'REJECTED'
    end                                         as decision_source,

    /*
        Graded rather than binary. A title that separates cleanly scores
        full marks; one sitting near the threshold scores less, so the
        confidence carries through to the person's final score.
    */
    case
        when r.human_decision = 'ACCEPT'   then 1.0
        when r.human_decision = 'REJECT'   then 0.0
        when r.pattern_title_group is not null then 1.0
        when r.match_decision != 'ACCEPTED' then 0.0
        else least(1.0, 0.70 + (r.similarity - {{ var('sim_floor') }})
                               / (1.0 - {{ var('sim_floor') }}) * 0.30)
    end                                         as group_score

from resolved r
left join second_hits sh using (title_key)
