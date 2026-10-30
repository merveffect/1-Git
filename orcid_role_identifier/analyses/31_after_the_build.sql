/*
    ============================================================================
    31. AFTER THE BUILD — THE CHECK LIST, IN ORDER
    ============================================================================
    Run after the build that carries the ten scoped leadership patterns and the
    fourteen human decisions (commits 03924c3, 9982239).

    THE ORDER MATTERS. 1-3 ask whether the change landed at all. 4-5 ask whether
    it did only what it was supposed to - 5 is the one that proves the scoping
    worked, and it is the query to run first if anything looks wrong. 6-7 ask
    the question that actually decides whether the change was worth making: the
    audience got bigger, did it stay right. 8-9 are the residuals.

    WHAT TO EXPECT, so a surprise is recognisable as one:

        1  dbt test passes. If it fails on
           assert_title_patterns_all_match_something naming dekan, decano,
           head of dept or head of faculty, that is the guard working on the
           four smallest patterns - put [pre-emptive] in that row's note.
        2  10 patterns, ~1,706 titles, ~48,995 records, all decision_source
           PATTERN and title_group leadership
        3  14 overrides, all HUMAN: 10+1 teaching/leadership, 3 librarian
        4  faculty_head 17,528 -> ~19,026 (+8.5%)
           lecturer    399,884 -> ~398,858 (-0.26%)
        5  ZERO records moved out of practitioner, pharmacist, researcher_*,
           student, support_technical, trainee_clinical, librarian.
           This is the whole point of the scoping. Any movement here is a bug.
        6  faculty_head precision was 26.3% on 71 people. It should not fall.
        7  lecturer 91.1% / 78.2% should be unchanged to within a rounding step.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- 1. DID THE BUILD PASS. Not a query - read the dbt output. The three that
--    matter are assert_title_patterns_do_not_collide,
--    assert_title_patterns_all_match_something and assert_overrides_take_effect.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 2. DID THE TEN PATTERNS LAND. One row per pattern, and every one of them
--    must have a non-zero count or test 1 would already have failed.
-- ----------------------------------------------------------------------------
select
    p.name_pattern,
    p.applies_when_title_group                      as scoped_to,
    count(d.title_key)                              as titles_claimed,
    sum(d.frequency)                                as records_claimed,
    countif(d.decision_source != 'PATTERN')         as not_recorded_as_pattern,
    countif(d.title_group != 'leadership')          as not_in_leadership
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.title_group_patterns` p
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
    on regexp_contains(d.title, p.name_pattern)
   and d.decision_source = 'PATTERN'
   and d.title_group = p.title_group
where p.title_group = 'leadership'
group by name_pattern, scoped_to
order by records_claimed desc;

-- ----------------------------------------------------------------------------
-- 3. DID THE FOURTEEN HUMAN DECISIONS LAND. Should be 14 rows, all HUMAN.
--    assert_overrides_take_effect already fails the build otherwise, so this is
--    to read them rather than to catch them.
-- ----------------------------------------------------------------------------
select
    d.title,
    d.frequency,
    d.title_group,
    d.decision_source,
    d.model_title_group,
    d.model_is_assigned
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
where d.title in (
    'dean s chair associate professor',
    'the sc family dean s faculty fellow and assistant professor',
    'associate professor and dean s distinguished fellow',
    'college of science dean s distinguished professor',
    'dean s associate professor',
    'associate professor and dean s chair',
    'distinguished dean s professor of formal epistemology',
    'college of engineering dean s professor',
    'assistant dean s office for psychology & adjunct professor',
    'dean s assistant full-time lecturer',
    'senior lecturer/ associate professor/ professor/ vice dean/ acting dean/ dean s advisor',
    'associate dean of library services',
    'associate dean library services and archives',
    'head of department of library and information science'
)
order by d.frequency desc;

-- ----------------------------------------------------------------------------
-- 4. DID THE TWO AUDIENCES MOVE AS PREDICTED. The prediction was 19,026 and
--    398,858. A difference of a few dozen is the overrides and the ROR data
--    moving under us; a difference of hundreds means something else happened.
-- ----------------------------------------------------------------------------
select
    role_key,
    count(distinct snid)                            as people,
    countif(in_cdp)                                 as reachable,
    case role_key
        when 'faculty_head' then 19026
        when 'lecturer'     then 398858
    end                                             as predicted
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
where role_key in ('faculty_head', 'lecturer')
group by role_key
order by people desc;

-- ----------------------------------------------------------------------------
-- 5. THE ONE THAT PROVES THE SCOPING WORKED.
--
--    An unscoped pattern would have pulled ~14,500 records out of eight groups.
--    These are the counts from the build before it. Any group other than
--    teaching_academic and leadership that has moved means the condition on
--    applies_when_title_group is not doing what it says, and that is the first
--    thing to look at before reading anything else.
-- ----------------------------------------------------------------------------
with before as (
    select * from unnest([
        struct('teaching_academic'      as title_group, 11994600 as records_before),
        struct('researcher_early'       as title_group,  8408047 as records_before),
        struct('student'                as title_group,  1970615 as records_before),
        struct('researcher_established' as title_group,  1945519 as records_before),
        struct('practitioner'           as title_group,  1650456 as records_before),
        struct('support_technical'      as title_group,  1453643 as records_before),
        struct('leadership'             as title_group,   962236 as records_before),
        struct('trainee_clinical'       as title_group,   751548 as records_before),
        struct('pharmacist'             as title_group,    74951 as records_before),
        struct('librarian'              as title_group,    21855 as records_before)
    ])
),

now as (
    select title_group, sum(frequency) as records_now
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned
    group by title_group
)

select
    b.title_group,
    b.records_before,
    n.records_now,
    n.records_now - b.records_before                as moved,
    case
        when b.title_group = 'teaching_academic'
             and n.records_now < b.records_before   then 'expected - it lost the compounds'
        when b.title_group = 'leadership'
             and n.records_now > b.records_before   then 'expected - it gained them'
        when n.records_now = b.records_before       then 'untouched, as intended'
        else '*** UNEXPECTED - the scoping is not holding ***'
    end                                             as verdict
from before b
left join now n using (title_group)
order by abs(n.records_now - b.records_before) desc;

-- ----------------------------------------------------------------------------
-- 6. THE QUESTION THAT DECIDES WHETHER IT WAS WORTH IT.
--
--    faculty_head got 1,498 people bigger. Do they agree? Precision was 26.3%
--    on 71 checkable people before, which is too few to conclude anything, so
--    the useful reading is the direction and the new sample size rather than
--    the number itself. If it falls materially, the gain was bought with wrong
--    labels and the patterns should come back out.
-- ----------------------------------------------------------------------------
with survey as (
    select lower(trim(email)) as email, survey_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
    where map_status = 'mapped'
),

ours as (
    select distinct role_key, snid, lower(trim(contact_email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_label = 'CONFIRMED' and contact_email is not null
)

select
    o.role_key                                          as we_said,
    count(distinct o.snid)                              as checkable_people,
    countif(s.survey_group = 'leadership')              as said_leadership,
    round(countif(s.survey_group = 'leadership')
          / count(distinct o.snid), 3)                  as precision,
    array_agg(distinct s.survey_group limit 6)          as what_the_rest_said
from ours o
join survey s using (email)
where o.role_key = 'faculty_head'
group by we_said;

-- ----------------------------------------------------------------------------
-- 7. AND DID LECTURER HOLD. 91.1% found / 78.2% agree before. 1,026 people
--    left it, which is 0.26%, so neither number should move by more than a
--    rounding step. If precision JUMPS, the people who left were the wrong
--    ones all along and that is worth knowing too.
-- ----------------------------------------------------------------------------
with survey as (
    select lower(trim(email)) as email, survey_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
    where map_status = 'mapped'
),

cdp as (
    select snid, lower(trim(email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big`
    where email is not null and email != ''
),

ours_titles as (
    select distinct r.snid, d.title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
         using (title_key)
    where d.is_assigned
),

ours_audience as (
    select distinct snid, lower(trim(contact_email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'lecturer' and role_label = 'CONFIRMED'
      and contact_email is not null
),

found as (
    select
        logical_or(o.title_group = 'teaching_academic') as we_found_it
    from survey s
    join cdp c using (email)
    join ours_titles o on o.snid = c.snid
    where s.survey_group = 'teaching_academic'
    group by s.email
),

agree as (
    select
        logical_or(s.survey_group = 'teaching_academic') as they_agree
    from ours_audience a
    join survey s using (email)
    group by a.snid
)

select 'did we find them  (was 0.911)' as question,
       count(*) as people, countif(we_found_it) as hits,
       round(countif(we_found_it) / count(*), 3) as rate
from found
union all
select 'do they agree     (was 0.782)',
       count(*), countif(they_agree),
       round(countif(they_agree) / count(*), 3)
from agree;

-- ----------------------------------------------------------------------------
-- 8. THE DATE RESIDUAL. analyses/30 query L, re-run on the new build so the 26
--    titles can be read with their new group showing. A closed range means the
--    post ended and the title belongs back in teaching.
-- ----------------------------------------------------------------------------
select
    title,
    frequency,
    title_group,
    decision_source,
    regexp_contains(title, r'(19|20)\d{2}\s*[-–]\s*(19|20)?\d{2}')  as has_a_closed_range,
    regexp_contains(title, r'(19|20)\d{2}\s*[-–]\s*($|[a-z])')      as has_an_open_range
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where is_assigned
  and regexp_contains(title, r'(?i)(head of (the )?(department|dept|school|faculty|'
                           || r'institute|division)|\bdean\b|decano|dekan)')
  and regexp_contains(title, r'(19|20)\d{2}')
order by frequency desc;

-- ----------------------------------------------------------------------------
-- 9. WHAT THE ASSIGNED-ONLY CONDITION STILL HOLDS BACK. Titles the model put
--    nearest to teaching_academic but rejected below the floor, which therefore
--    the pattern did not claim. Should contain nothing that is obviously a
--    faculty head. If it does, revisit the condition - on this evidence.
-- ----------------------------------------------------------------------------
select
    title,
    frequency,
    round(similarity, 3)    as similarity,
    model_title_group,
    decision_source,
    matched_anchors
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where not is_assigned
  and model_title_group = 'teaching_academic'
  and regexp_contains(title, r'(?i)(head of (the )?(department|dept|school|faculty|'
                           || r'institute|division)|\bdean\b|decano|dekan)')
order by frequency desc
limit 60;
