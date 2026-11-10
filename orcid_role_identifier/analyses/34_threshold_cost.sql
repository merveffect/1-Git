/*
    ============================================================================
    34. WHAT RAISING A THRESHOLD WOULD COST, AND WHAT IT CANNOT BUY
    ============================================================================
    Merve, 2026-11-04:

        "ben sadece sunu istiyorum coverage ve cok audience olmasi onemli degil
         sadece emin oldugumuz kisileri alalim. belki thresholdu arttirmak bunu
         cozer educationsa bakmadan?"

    So the brief is explicit: coverage is not the objective. Certainty is. The
    question is which threshold, and to what - and this file answers only the
    first half, because the second half has to come from a table rather than
    from the shape of the problem. Nothing here proposes a number.

    THERE ARE TWO THRESHOLDS AND THEY WORK IN OPPOSITE DIRECTIONS.

    `sim_floor` = 0.65 decides whether a TITLE joins a group. Raising it is the
    wrong lever and we have measured why twice:

        junior researcher      0.870   researcher_ESTABLISHED, 42,949 records,
                                       the largest single error in the project
        independent consultant 0.867   wrong
        business consultant    0.843   wrong
        medical director       0.821   not a faculty head

    against 34 titles / ~578 records of genuine faculty leadership sitting at
    0.567-0.649 - not because they are ambiguous but because they are VERBOSE
    (analyses/31 query 8, and 2.4b in open-questions: share_below_075 is partly
    a measure of title LENGTH). Raising the floor deletes correct long titles
    and keeps wrong short ones. It is not measured here and should not move.

    The AUDIENCE thresholds in dbt_project.yml are the right lever, because the
    composite score is the only place where two independent signals - the title,
    the ROR organisation type, the department discipline - have to agree. Asking
    for agreement between axes is a claim about certainty. Asking for a higher
    cosine on one axis is not.

    WHAT THIS FILE CANNOT SEE. fct_researcher_roles keeps only CONFIRMED and
    PROBABLE rows; NOT_QUALIFIED is dropped before it is written. So every query
    below reads UPWARD from the current threshold, which is the direction asked
    for. A threshold set below a role's `probable` value cannot be costed here.

    THE PARENT ROLL-UP, WHICH BREAKS THE OBVIOUS ARITHMETIC. A pharmacist also
    gets an hcp_broad row. That row arrives carrying the CHILD's score and the
    PARENT's role_key, and the two have different weights and different
    thresholds. So the axis arithmetic must use the weights of
    coalesce(derived_from_role, role_key), while the label uses the threshold of
    role_key. Every query below does this, and query 1 reconciles it rather than
    asserting it.

    WEIGHTS AND THRESHOLDS ARE COPIED FROM dbt_project.yml AS AT 2026-11-04.
    If they are changed there, change them here - query 1 will show the drift as
    rows that fail to reconcile.

        role                w_title  w_org  w_dept  confirmed  probable  match
        hcp_broad            0.35    0.25   0.40      0.60      0.30   title_or_field
        hcp_practitioner     0.45    0.15   0.40      0.70      0.50   title_and_field
        hcp_researcher       0.40    0.20   0.40      0.70      0.50   title_and_field
        hcp_administrator    0.35    0.25   0.40      0.70      0.50   title_and_field
        pharmacist           0.55    0.15   0.30      0.60      0.30   title_required
        librarian            1.00    0.00   0.00      0.60      0.35   title_required
        researcher           0.75    0.25   0.00      0.60      0.30   title_required
        faculty_head         0.60    0.40   0.00      0.65      0.40   title_required
        lecturer             0.75    0.25   0.00      0.60      0.30   title_required

    READ THE WEIGHTS BEFORE READING THE RESULTS, because they already tell you
    where a threshold can and cannot bite:

      - librarian is 1.00 title / 0.00 org. Its audience threshold IS a
        similarity threshold, so raising it hits exactly the title-length
        problem described above. Expect query 3 to show it falling off a cliff.
      - researcher and lecturer are 0.75 / 0.25 with no department. An education
        organisation scores 1.00 and even UNKNOWN scores 0.25, so almost
        everything at a university confirms. The threshold bites on the title.
      - hcp_broad is the only title_or_field role, and 1.00*0.35 + 1.00*0.25
        = 0.60 is EXACTLY its confirmed threshold. A perfect clinical title at a
        healthcare organisation with NO DEPARTMENT AT ALL confirms on the line.
        That is the population the brief is about. Query 5 sizes it.

    RUN ORDER: 1 then 2 then 3. Query 1 is the baseline and must be read first,
    because none of the rest means anything without a measured "before".
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE BASELINE, AND A RECONCILIATION.
--
--    Run this first and keep the output. Two jobs in one statement: it states
--    today's position per role, and it checks that the weights pasted above
--    actually reproduce role_final_score. Read reconcile_mismatch first - if it
--    is not 0, the weights here have drifted from dbt_project.yml and every
--    later query is wrong.
-- ----------------------------------------------------------------------------
with w as (
    select * from unnest([
        struct('hcp_broad'         as role_key, 0.35 as w_title, 0.25 as w_org, 0.40 as w_dept, 0.60 as t_confirmed, 0.30 as t_probable),
        struct('hcp_practitioner',  0.45, 0.15, 0.40, 0.70, 0.50),
        struct('hcp_researcher',    0.40, 0.20, 0.40, 0.70, 0.50),
        struct('hcp_administrator', 0.35, 0.25, 0.40, 0.70, 0.50),
        struct('pharmacist',        0.55, 0.15, 0.30, 0.60, 0.30),
        struct('librarian',         1.00, 0.00, 0.00, 0.60, 0.35),
        struct('researcher',        0.75, 0.25, 0.00, 0.60, 0.30),
        struct('faculty_head',      0.60, 0.40, 0.00, 0.65, 0.40),
        struct('lecturer',          0.75, 0.25, 0.00, 0.60, 0.30)
    ])
),

/*
    The score was computed with the weights of the role it was SCORED for,
    which for a roll-up row is the child. The label uses the parent's
    threshold. ws = scoring weights, wl = labelling thresholds.
*/
rows_scored as (
    select
        r.role_key,
        r.derived_from_role,
        r.role_label,
        r.role_final_score,
        least(1.0,
              coalesce(r.role_score, 0.0) * ws.w_title
            + coalesce(r.org_score,  0.0) * ws.w_org
            + coalesce(r.dept_score, 0.0) * ws.w_dept
        )                                               as recomputed_score,
        wl.t_confirmed
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    join w ws on ws.role_key = coalesce(r.derived_from_role, r.role_key)
    join w wl on wl.role_key = r.role_key
)

select
    role_key,
    count(*)                                                        as people,
    countif(role_label = 'CONFIRMED')                               as confirmed,
    countif(role_label = 'PROBABLE')                                as probable,
    countif(derived_from_role is not null)                          as rolled_up_from_child,

    round(min(if(role_label = 'CONFIRMED', role_final_score, null)), 4)  as confirmed_min,
    round(approx_quantiles(if(role_label = 'CONFIRMED', role_final_score, null), 2)[offset(1)], 4) as confirmed_median,
    round(max(if(role_label = 'CONFIRMED', role_final_score, null)), 4)  as confirmed_max,

    /*
        How many are sitting ON the line rather than above it. This is the
        number that decides whether a threshold move is a nudge or a cull.
    */
    countif(role_label = 'CONFIRMED'
            and abs(role_final_score - t_confirmed) < 0.0005)       as exactly_on_threshold,

    countif(abs(recomputed_score - role_final_score) > 0.0005)      as reconcile_mismatch
from rows_scored
group by role_key
order by confirmed desc;


-- ----------------------------------------------------------------------------
-- 2. WHAT ACTUALLY CARRIES EACH CONFIRMED PERSON.
--
--    This is the query the brief asks for. For every CONFIRMED person, remove
--    one axis at a time and ask whether they would still confirm. An axis is
--    ESSENTIAL if removing it drops them below the threshold.
--
--      ONE AXIS IS ENOUGH (TITLE)   the title alone clears the threshold. The
--                                   org and the department are decoration.
--      TITLE + ORG                  needs both, department not involved
--      TITLE + DEPT                 needs both, organisation not involved
--      NEEDS ALL THREE              every axis is load-bearing - the most
--                                   defensible row we produce
--      NO TITLE AT ALL              role_score = 0: arrived through the
--                                   discipline. Only possible for hcp_broad,
--                                   and it is the title_or_field edge
--
--    A high share in ONE AXIS IS ENOUGH is not automatically wrong - a
--    `consultant cardiologist` needs no corroboration. It is the population a
--    threshold raise would remove, so its size is the price.
-- ----------------------------------------------------------------------------
with w as (
    select * from unnest([
        struct('hcp_broad'         as role_key, 0.35 as w_title, 0.25 as w_org, 0.40 as w_dept, 0.60 as t_confirmed, 0.30 as t_probable),
        struct('hcp_practitioner',  0.45, 0.15, 0.40, 0.70, 0.50),
        struct('hcp_researcher',    0.40, 0.20, 0.40, 0.70, 0.50),
        struct('hcp_administrator', 0.35, 0.25, 0.40, 0.70, 0.50),
        struct('pharmacist',        0.55, 0.15, 0.30, 0.60, 0.30),
        struct('librarian',         1.00, 0.00, 0.00, 0.60, 0.35),
        struct('researcher',        0.75, 0.25, 0.00, 0.60, 0.30),
        struct('faculty_head',      0.60, 0.40, 0.00, 0.65, 0.40),
        struct('lecturer',          0.75, 0.25, 0.00, 0.60, 0.30)
    ])
),

parts as (
    select
        r.role_key,
        coalesce(r.role_score, 0.0) * ws.w_title    as c_title,
        coalesce(r.org_score,  0.0) * ws.w_org      as c_org,
        coalesce(r.dept_score, 0.0) * ws.w_dept     as c_dept,
        coalesce(r.role_score, 0.0)                 as role_score,
        wl.t_confirmed
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    join w ws on ws.role_key = coalesce(r.derived_from_role, r.role_key)
    join w wl on wl.role_key = r.role_key
    where r.role_label = 'CONFIRMED'
),

/*
    Each "without" total is rebuilt from the components rather than subtracted
    from the capped total - least(1.0, a+b+c) minus c is not least(1.0, a+b).
*/
judged as (
    select
        role_key,
        case
            when role_score = 0                                   then 'NO TITLE AT ALL'
            when least(1.0, c_title) + 1e-9 >= t_confirmed        then 'ONE AXIS IS ENOUGH (TITLE)'
            when least(1.0, c_title + c_org)  + 1e-9 >= t_confirmed then 'TITLE + ORG'
            when least(1.0, c_title + c_dept) + 1e-9 >= t_confirmed then 'TITLE + DEPT'
            else 'NEEDS ALL THREE'
        end                                                       as carried_by
    from parts
)

select
    role_key,
    carried_by,
    count(*)                                                      as people,
    round(100 * count(*) / sum(count(*)) over (partition by role_key), 1) as pct_of_role
from judged
group by role_key, carried_by
order by role_key, people desc;


-- ----------------------------------------------------------------------------
-- 3. THE LADDER. What each candidate threshold keeps.
--
--    One row per (role, candidate threshold): people still CONFIRMED, the share
--    of today's CONFIRMED they represent, and how many of them are marketable,
--    because the reachable number is the one that matters commercially.
--
--    cand below a role's current threshold is shown as NULL-ish - it cannot be
--    costed, because NOT_QUALIFIED rows were never written. Read only the rows
--    at or above `current_threshold`.
-- ----------------------------------------------------------------------------
with w as (
    select * from unnest([
        struct('hcp_broad'         as role_key, 0.60 as t_confirmed),
        struct('hcp_practitioner',  0.70),
        struct('hcp_researcher',    0.70),
        struct('hcp_administrator', 0.70),
        struct('pharmacist',        0.60),
        struct('librarian',         0.60),
        struct('researcher',        0.60),
        struct('faculty_head',      0.65),
        struct('lecturer',          0.60)
    ])
),

people as (
    select
        r.role_key,
        r.role_final_score,
        coalesce(a.is_marketable, false)    as is_marketable
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience` a
           on a.snid = r.snid and a.role_key = r.role_key
    where r.role_label = 'CONFIRMED'
),

today as (
    select role_key, count(*) as confirmed_today, countif(is_marketable) as marketable_today
    from people group by role_key
),

candidates as (
    select cand / 100 as cand from unnest(generate_array(60, 95, 5)) as cand
)

select
    p.role_key,
    w.t_confirmed                                   as current_threshold,
    c.cand                                          as candidate_threshold,
    countif(p.role_final_score + 1e-9 >= c.cand)    as confirmed_at_candidate,
    t.confirmed_today,
    countif(p.role_final_score + 1e-9 >= c.cand) - t.confirmed_today    as people_lost,
    round(100 * countif(p.role_final_score + 1e-9 >= c.cand) / t.confirmed_today, 1) as pct_retained,
    countif(p.role_final_score + 1e-9 >= c.cand and p.is_marketable)    as marketable_at_candidate,
    t.marketable_today
from people p
join w    on w.role_key = p.role_key
join today t on t.role_key = p.role_key
cross join candidates c
where c.cand + 1e-9 >= w.t_confirmed
group by p.role_key, w.t_confirmed, c.cand, t.confirmed_today, t.marketable_today
order by p.role_key, c.cand;


-- ----------------------------------------------------------------------------
-- 4. WHERE THE PEOPLE PILE UP.
--
--    A weighted sum of three bounded axes does not produce a smooth
--    distribution - it produces a handful of discrete values, one per
--    combination of axis scores. The top 12 per role, with a running share.
--
--    This is the query that decides HOW MUCH to move a threshold, because if a
--    third of a role sits on one value then 0.01 is not a nudge, it is a cull.
-- ----------------------------------------------------------------------------
with people as (
    select role_key, round(role_final_score, 3) as score_value
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_label = 'CONFIRMED'
),

piles as (
    select
        role_key,
        score_value,
        count(*)                                                            as people,
        round(100 * count(*) / sum(count(*)) over (partition by role_key), 1) as pct_of_role
    from people
    group by role_key, score_value
),

ranked as (
    select
        p.*,
        row_number() over (partition by role_key order by people desc)       as rn,
        sum(pct_of_role) over (partition by role_key order by people desc
                               rows between unbounded preceding and current row) as pct_cumulative
    from piles p
)

select role_key, score_value, people, pct_of_role, round(pct_cumulative, 1) as pct_cumulative
from ranked
where rn <= 12
order by role_key, people desc;


-- ----------------------------------------------------------------------------
-- 5. hcp_broad's TWO ONE-LEGGED ROUTES - the practitioner question.
--
--    hcp_broad is the only title_or_field role, which means a record can enter
--    it on the title alone or on the discipline alone. Both routes exist by
--    design (11.6% of records have no department, and an unmistakable clinical
--    title should not be lost), but they are also the least corroborated rows
--    in the whole output, and the brief is about exactly those.
--
--    Counted on hcp_broad's OWN rows only. A rolled-up row came from a child
--    role that already required both axes, so it is not one-legged.
-- ----------------------------------------------------------------------------
with rows_own as (
    select
        r.role_score,
        r.org_score,
        r.dept_score,
        r.role_final_score,
        r.title_group,
        coalesce(a.is_marketable, false) as is_marketable
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience` a
           on a.snid = r.snid and a.role_key = r.role_key
    where r.role_key = 'hcp_broad'
      and r.role_label = 'CONFIRMED'
      and r.derived_from_role is null
),

judged as (
    select
        case
            when coalesce(role_score, 0) = 0                        then 'DISCIPLINE ONLY - no clinical title'
            when coalesce(dept_score, 0) = 0 and coalesce(org_score, 0) = 0
                                                                    then 'TITLE ONLY - no org, no department'
            when coalesce(dept_score, 0) = 0                        then 'TITLE + ORG - no department'
            when coalesce(org_score, 0)  = 0                        then 'TITLE + DEPT - no typed org'
            else 'ALL THREE PRESENT'
        end                                                         as route,
        role_final_score,
        is_marketable
    from rows_own
)

select
    route,
    count(*)                                                        as people,
    round(100 * count(*) / sum(count(*)) over (), 1)                as pct_of_hcp_broad_own,
    countif(is_marketable)                                          as marketable,
    round(min(role_final_score), 4)                                 as score_min,
    round(max(role_final_score), 4)                                 as score_max
from judged
group by route
order by people desc;


-- ----------------------------------------------------------------------------
-- 6. WHAT NO THRESHOLD CAN TOUCH.
--
--    A HUMAN ACCEPT override and a PATTERN match both set group_score to 1.00
--    outright - see the case expression in dim_title_group. So role_score for
--    those titles is 1.00 by decision, not by measurement, and they clear any
--    threshold we could set. 533 overrides and 21 patterns are in that position.
--
--    That is the honest limit of this whole exercise: raising a threshold
--    removes WEAKLY EVIDENCED people, not WRONGLY LABELLED ones. The 5.7% we
--    measured wrong in faculty_head were mostly confident scores.
--
--    READ frequency WITH CARE. dim_title_group.frequency is counted over ALL of
--    ORCID, not over the 1,737,768 records that carry a Springer Nature id. The
--    ratio is roughly 19:1. These are TITLE counts, not people.
-- ----------------------------------------------------------------------------
select
    title_group,
    decision_source,
    count(*)                                                        as titles,
    sum(frequency)                                                  as orcid_records,
    round(100 * sum(frequency) / sum(sum(frequency)) over (partition by title_group), 1)
                                                                    as pct_of_group_records,
    round(min(group_score), 3)                                      as group_score_min,
    round(max(group_score), 3)                                      as group_score_max
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where is_assigned
group by title_group, decision_source
order by title_group, orcid_records desc;


-- ----------------------------------------------------------------------------
-- 7. THE DECISION TABLE. One row per role, everything in one place.
--
--    Run this last and bring the output to the threshold conversation. It says,
--    per role: where we are, what one step and two steps up would cost, and
--    what share of today's CONFIRMED is carried by a single axis - which is the
--    population a raise is aimed at.
--
--    It does NOT recommend a number. The number comes from reading this beside
--    query 4, because a role whose mass sits on one score value cannot be
--    nudged at all - it can only be stepped over.
-- ----------------------------------------------------------------------------
with w as (
    select * from unnest([
        struct('hcp_broad'         as role_key, 0.35 as w_title, 0.25 as w_org, 0.40 as w_dept, 0.60 as t_confirmed),
        struct('hcp_practitioner',  0.45, 0.15, 0.40, 0.70),
        struct('hcp_researcher',    0.40, 0.20, 0.40, 0.70),
        struct('hcp_administrator', 0.35, 0.25, 0.40, 0.70),
        struct('pharmacist',        0.55, 0.15, 0.30, 0.60),
        struct('librarian',         1.00, 0.00, 0.00, 0.60),
        struct('researcher',        0.75, 0.25, 0.00, 0.60),
        struct('faculty_head',      0.60, 0.40, 0.00, 0.65),
        struct('lecturer',          0.75, 0.25, 0.00, 0.60)
    ])
),

parts as (
    select
        r.role_key,
        r.role_final_score,
        coalesce(r.role_score, 0.0)                 as role_score,
        coalesce(r.role_score, 0.0) * ws.w_title    as c_title,
        wl.t_confirmed,
        coalesce(a.is_marketable, false)            as is_marketable
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    join w ws on ws.role_key = coalesce(r.derived_from_role, r.role_key)
    join w wl on wl.role_key = r.role_key
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience` a
           on a.snid = r.snid and a.role_key = r.role_key
    where r.role_label = 'CONFIRMED'
)

select
    role_key,
    t_confirmed                                                     as threshold_today,
    count(*)                                                        as confirmed_today,
    countif(is_marketable)                                          as marketable_today,

    countif(role_final_score + 1e-9 >= t_confirmed + 0.05)          as confirmed_plus_005,
    countif(role_final_score + 1e-9 >= t_confirmed + 0.10)          as confirmed_plus_010,
    round(100 * countif(role_final_score + 1e-9 >= t_confirmed + 0.05) / count(*), 1) as pct_kept_plus_005,
    round(100 * countif(role_final_score + 1e-9 >= t_confirmed + 0.10) / count(*), 1) as pct_kept_plus_010,

    /* the population a raise is aimed at */
    countif(least(1.0, c_title) + 1e-9 >= t_confirmed)              as carried_by_title_alone,
    round(100 * countif(least(1.0, c_title) + 1e-9 >= t_confirmed) / count(*), 1) as pct_title_alone,

    /* and the population it cannot reach */
    countif(role_score >= 0.9995)                                   as role_score_is_1_00,
    round(100 * countif(role_score >= 0.9995) / count(*), 1)        as pct_role_score_1_00
from parts
group by role_key, t_confirmed
order by confirmed_today desc;
