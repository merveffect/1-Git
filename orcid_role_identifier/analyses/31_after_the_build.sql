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

/*
    ============================================================================
    THE BUILD RAN 2026-10-30. THE MECHANISM IS EXACT AND THE FORECAST WAS NOT.
    ============================================================================
    WHAT WORKED, with nothing to qualify:

      2  all ten patterns landed. 1,699 titles / 48,785 records, every one
         recorded as PATTERN and every one in leadership. Zero exceptions.
      3  all fourteen human decisions landed as HUMAN. And two of the three
         collision overrides were genuinely load-bearing: `associate dean of
         library services` and `associate dean library services and archives`
         both came back with model_title_group = teaching_academic, so without
         them `librar` and the scoped `\bdean\b` would have claimed the same
         title and failed the build. The third had model = leadership and would
         not have collided.
      5  THE SCOPING IS EXACT. teaching_academic -48,521, leadership +48,521,
         and all eight other groups moved by zero. Not approximately zero -
         zero. practitioner, pharmacist, researcher_early, researcher_
         established, student, support_technical, trainee_clinical and
         librarian are untouched to the record.

    WHAT DID NOT MATCH, AND IT IS NOT A SMALL MISS:

      4  faculty_head   17,528 -> 33,241   predicted 19,026   (+90%, not +8.5%)
         lecturer      399,884 -> 404,367  predicted 398,858  (it went UP)

    Lecturer could only lose people from this change, and it gained 4,483. So at
    least one thing moved that this change did not move, and until that is
    named, neither number can be attributed. Two candidates, and query 10 tells
    them apart:

      a) THE SOURCE GREW. The build re-ran the seeds and both incremental
         models. A bigger ORCID snapshot or a bigger CDP lifts every audience
         at once, and +1.1% on lecturer is the right size for that.
      b) QUERY K COUNTED PEOPLE WRONG. It put 2,354 people behind 48,995
         records, which is 20.8 records each. Every other ratio in this project
         is nearer 3:1 - 12M teaching records to 400,000 lecturers is 30:1 but
         that is across the whole dictionary, not one narrow family. If the
         real figure is ~15,700 holders then the audience behaved correctly and
         the forecast was simply built on a bad count.

      (b) is the more likely of the two and it would be my error, not the
      pipeline's. Either way the +8.5% figure in the status document and in
      1.10b is not yet earned and should not be quoted until query 10 settles
      it.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- 10. RECONCILE THE GROWTH. Three counts that have to add up, and if they do
--     not, the one that is wrong is the one to fix.
-- ----------------------------------------------------------------------------
with claimed as (
    select title_key, title, frequency
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where decision_source = 'PATTERN' and title_group = 'leadership'
),

holders as (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
    where title_key in (select title_key from claimed)
)

select
    'titles the patterns claimed'               as measure,
    (select count(*) from claimed)              as value
union all
select 'records behind them  (dictionary frequency)',
    (select sum(frequency) from claimed)
union all
select 'the same records, counted in stg_role_records',
    (select count(*)
     from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
     where title_key in (select title_key from claimed))
union all
select 'PEOPLE holding at least one  <- query K said 2,354',
    (select count(*) from holders)
union all
select 'of those, in faculty_head today',
    (select count(distinct a.snid)
     from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience` a
     join holders h using (snid)
     where a.role_key = 'faculty_head')
union all
select 'faculty_head total  <- was 17,528',
    (select count(distinct snid)
     from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
     where role_key = 'faculty_head')
union all
select 'faculty_head members NOT holding one of these titles',
    (select count(distinct a.snid)
     from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience` a
     left join holders h using (snid)
     where a.role_key = 'faculty_head' and h.snid is null)
union all
select 'total employment records in the pipeline  <- is the source bigger?',
    (select count(*)
     from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`)
union all
select 'people in the CDP  <- is the CDP bigger?',
    (select count(distinct snid)
     from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_audience_builder_big`);

-- ----------------------------------------------------------------------------
-- 11. DID WE READ THE TITLE RIGHT, for faculty_head.
--
--     Precision fell from 26.3% on 71 people to 12.6% on 1,775, and the first
--     thing the disagreers said was `teaching_academic`. That is the same shape
--     as Lecturer, where 78.2% agreement turned out to be 99.2% correct reading
--     once we asked whether the TITLE said what we claimed. So ask it here:
--     of the people we put in faculty_head who called themselves something
--     else, how many have no leadership word in any of their job titles?
--
--     A person who wrote `Professor and Head of Department` in ORCID and then
--     ticked `Academic` on a survey form is not an error of ours. A person with
--     no leadership word anywhere is.
-- ----------------------------------------------------------------------------
with survey as (
    select lower(trim(email)) as email, survey_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
    where map_status = 'mapped'
),

ours as (
    select distinct snid, lower(trim(contact_email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'faculty_head' and role_label = 'CONFIRMED'
      and contact_email is not null
),

disagreed as (
    select o.snid
    from ours o
    join survey s using (email)
    group by o.snid
    having logical_or(s.survey_group = 'leadership') = false
),

their_titles as (
    select
        d.snid,
        logical_or(regexp_contains(r.role_title,
            r'(?i)(head of|\bdean\b|decano|dekan|\bchair\b|\bdirector\b|'
         || r'rector|provost|president|principal|\bchief\b|leiter|'
         || r'coordinator|coordenador|科主任)')) as has_a_leadership_word,
        array_agg(distinct r.role_title limit 4)   as titles
    from disagreed d
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
         using (snid)
    group by d.snid
)

select
    case when has_a_leadership_word
         then 'their title DOES say they lead something - not our error'
         else '*** no leadership word in any title - this is our error ***'
    end                             as reading,
    count(*)                        as people,
    round(count(*) / sum(count(*)) over (), 3)  as share,
    array_agg(titles[safe_offset(0)] order by titles[safe_offset(0)] limit 10) as examples
from their_titles
group by reading
order by people desc;

/*
    ============================================================================
    QUERY 10 SETTLED IT, AND THE FORECAST WAS RIGHT. THE READING WAS NOT.
    ============================================================================
        titles the patterns claimed                              1,685
        records behind them - DICTIONARY frequency               48,518
        the same records, counted in stg_role_records              2,557   <--
        PEOPLE holding at least one                                2,333
        of those, in faculty_head today                            1,715
        faculty_head total                                        33,241
        faculty_head members NOT holding one of these titles      31,526   <--
        total employment records in the pipeline               1,737,768   <--

    TWO THINGS FALL OUT OF THIS AND THE SECOND IS THE IMPORTANT ONE.

    1. `frequency` IS COUNTED OVER ALL OF ORCID, NOT OVER OUR UNIVERSE. The
       whole pipeline holds 1,737,768 employment records, and the dictionary
       says teaching_academic alone has 11,946,079. So every "records" figure in
       this project - 48,518 here, 11.9M for teaching, the 78,565 of the
       one-word failures - is ORCID-wide, while every "people" figure comes from
       the 1.74M records that matched a Springer Nature id. The ratio is about
       19:1.

       48,518 ORCID records  ->  2,557 of our records  ->  2,333 people.

       Query K's 2,354 was therefore CORRECT, and the 20.8-records-per-person
       ratio I called implausible is simply what that 19:1 looks like. I read
       two different universes as one, which is the error, not the count.

    2. MY CHANGE DID WHAT IT WAS PREDICTED TO DO. 1,715 of the people holding a
       pattern-claimed title are in faculty_head, against a prediction of 1,498
       new plus 280 already there - 1,778. Within 4%.

       **So the change accounts for 1,715 of faculty_head's 33,241, and
       31,526 members do not hold one of these titles at all.** The audience was
       17,528 before, so roughly 14,000 people arrived from something that is
       not this change.

    AND IT CAN ONLY BE THE ORGANISATION, BY ELIMINATION. Query 5 showed the
    leadership group gained records from the patterns and from nothing else, so
    all 31,526 already had leadership titles in the previous build. Their titles
    did not change. The only other thing faculty_head needs is for the employer
    to resolve to an academic organisation - and roughly 14,600 records with
    strong leadership titles were stranded on exactly that. +14,000 people is
    the same order. Query 13 confirms it.

    WHICH MEANS THE HEADLINE IS NOT "+8.5% FROM THE COMPOUNDS". It is: the
    compounds added 1,715 people as forecast, and separately the audience nearly
    doubled because organisations resolved. Those are two findings and they must
    be reported as two, or the compound work takes credit for the ROR data.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- 12. THE REAL READING ACCURACY FOR faculty_head, with the word list fixed.
--
--     Query 11 said 86.1% of the disagreers do have a leadership word
--     somewhere. That figure is contaminated in BOTH directions by the list I
--     used:
--       too loose - it counted `chair` and `director`, the two words this
--                   project has already measured as unreliable. `academic
--                   chair - organisational psychology` is a professorship.
--       too tight - it had no `chancellor`, so `acting vice-chancellor` was
--                   filed as our error when it is plainly leadership.
--
--     So this splits the words into the ones we trust and the ones we do not,
--     and reports three buckets instead of two. The middle bucket is the honest
--     uncertainty, and it should not be counted on either side.
-- ----------------------------------------------------------------------------
with survey as (
    select lower(trim(email)) as email, survey_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
    where map_status = 'mapped'
),

ours as (
    select distinct snid, lower(trim(contact_email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'faculty_head' and role_label = 'CONFIRMED'
      and contact_email is not null
),

disagreed as (
    select o.snid
    from ours o
    join survey s using (email)
    group by o.snid
    having logical_or(s.survey_group = 'leadership') = false
),

judged as (
    select
        d.snid,
        /* words that name a post and a level, and nothing else */
        logical_or(regexp_contains(r.role_title,
            r'(?i)(head of|\bdean\b|decano|dekan|rector|provost|chancellor|'
         || r'\bprovost\b|leiter|科主任|head of department|hod\b)')) as trusted,
        /* words this project has measured as unreliable */
        logical_or(regexp_contains(r.role_title,
            r'(?i)(\bchair\b|\bdirector\b|\bchief\b|\bhead\b|coordinator|'
         || r'coordenador|president|principal)'))                     as untrusted
    from disagreed d
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
         using (snid)
    group by d.snid
)

select
    case
        when trusted             then 'CORRECT - a title names a faculty-level post'
        when untrusted           then 'UNCERTAIN - only chair/director/head, which we do not trust'
        else                          '*** OUR ERROR - no leadership word at all ***'
    end                                                     as reading,
    count(*)                                                as people,
    round(count(*) / sum(count(*)) over (), 3)              as share
from judged
group by reading
order by people desc;

-- ----------------------------------------------------------------------------
-- 13. WHERE THE OTHER ~14,000 CAME FROM. If it is the organisation, these
--     people will be concentrated in one resolution method and one org type,
--     and their TITLES will be ordinary leadership titles that existed before.
--     If they are spread evenly, the hypothesis is wrong and something else
--     changed - look at the CDP next.
-- ----------------------------------------------------------------------------
with claimed as (
    select title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where decision_source = 'PATTERN' and title_group = 'leadership'
),

holders as (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
    where title_key in (select title_key from claimed)
)

select
    s.org_resolution_method,
    s.org_type,
    count(distinct s.snid)                      as people,
    round(avg(s.org_score), 3)                  as avg_org_score,
    round(avg(s.role_score), 3)                 as avg_title_score,
    array_agg(distinct s.evidence_title limit 3) as example_titles
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` s
join (
    select distinct a.snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience` a
    left join holders h using (snid)
    where a.role_key = 'faculty_head' and h.snid is null
) newcomers using (snid)
where s.role_key = 'faculty_head'
group by org_resolution_method, org_type
order by people desc
limit 30;

-- ----------------------------------------------------------------------------
-- 14. THE WHOLE CHECK IN ONE QUERY. Run this and query 12, and the work on the
--     leadership compounds is finished.
--
--     Baselines are from the 30 October build, the one BEFORE the 37 rejections
--     and the removal of the assigned-only guard. Expected changes:
--
--       the 37 ended-post titles leave leadership        -972 records
--       the 34 verbose titles arrive, previously below
--         the floor and therefore in no group at all      +578 records
--       everything else                                  unchanged
--
--     So leadership should land near 1,010,363 and teaching_academic should not
--     move at all - the rejected titles were all leadership, and the verbose
--     ones were assigned to nothing. A `verdict` column saying anything other
--     than 'as expected' is the thing to look at; nothing else needs reading.
-- ----------------------------------------------------------------------------
with expected as (
    select * from unnest([
        struct('teaching_academic'      as k, 11946079 as want, 'records' as unit),
        struct('leadership'             as k,  1010363 as want, 'records' as unit),
        struct('researcher_early'       as k,  8408047 as want, 'records' as unit),
        struct('student'                as k,  1970615 as want, 'records' as unit),
        struct('researcher_established' as k,  1945519 as want, 'records' as unit),
        struct('practitioner'           as k,  1650456 as want, 'records' as unit),
        struct('support_technical'      as k,  1453643 as want, 'records' as unit),
        struct('trainee_clinical'       as k,   751548 as want, 'records' as unit),
        struct('pharmacist'             as k,    74951 as want, 'records' as unit),
        struct('librarian'              as k,    21855 as want, 'records' as unit)
    ])
),

groups_now as (
    select title_group as k, sum(frequency) as got
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned
    group by title_group
),

checks as (
    -- A. every group's record count against what it should be
    select
        'group  ' || e.k                            as check_name,
        e.want                                      as expected,
        coalesce(g.got, 0)                          as actual,
        coalesce(g.got, 0) - e.want                 as diff
    from expected e
    left join groups_now g using (k)

    union all

    -- B. did the 37 rejections land
    select 'the 37 ended-post titles, rejected', 37,
        (select count(*)
         from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
         where decision_source = 'HUMAN' and not is_assigned
           and regexp_contains(title, r'(19|20)\d{2}')
           and regexp_contains(title, r'(?i)(head of|\bdean\b)')),
        0

    union all

    -- C. did the verbose ones arrive, now that the guard is gone
    select 'verbose titles the patterns can now reach', 34,
        (select count(*)
         from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
         where decision_source = 'PATTERN' and title_group = 'leadership'
           and similarity < 0.65),
        0

    union all

    -- D. the two audiences. No prediction on these - the rejections and the
    --    verbose titles pull in opposite directions by a few hundred people,
    --    and which way it nets out is what this reports.
    select 'PEOPLE in faculty_head  (was 33,241)', 33241,
        (select count(distinct snid)
         from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
         where role_key = 'faculty_head'), 0

    union all

    select 'PEOPLE in lecturer  (was 404,367)', 404367,
        (select count(distinct snid)
         from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
         where role_key = 'lecturer'), 0
),

judged as (
    select
        check_name,
        expected,
        actual,
        actual - expected                               as diff,
        case
            when check_name like 'PEOPLE%'              then 'no prediction - just read it'
            when actual = expected                      then 'as expected'
            when check_name = 'group  leadership'
                 and abs(actual - expected) < 200       then 'as expected, within rounding'
            else '*** LOOK AT THIS ***'
        end                                             as verdict
    from checks
)

select check_name, expected, actual, diff, verdict
from judged
order by
    case when verdict like '***%' then 0
         when check_name like 'PEOPLE%' then 1
         else 2 end,
    abs(diff) desc;
