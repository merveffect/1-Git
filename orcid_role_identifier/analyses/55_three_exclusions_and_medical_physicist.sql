/*
    ============================================================================
    55. THE FOUR ANSWERS OF 19 NOVEMBER, SIZED BEFORE THEY ARE BUILT
    ============================================================================
    Merve read the status document through to section 6.5 and wrote an answer
    beside each open item. Four of them are decisions this pipeline can act on:

      6.1  visiting scholars and visiting fellows   -> exclude
      6.1  honorary professors                      -> exclude
      6.3  the bare qualification as a job title    -> exclude
      6.5  medical physicist (346 records)          -> clinical researcher
      6.5  a bare `doctor` (4,465 records)          -> stays in practitioner

    The fifth is not an engineering decision: veterinarians (91 people) and
    sport and exercise science (78) stay open and now have an owner, Matthew.

    ⭐ WHY THIS FILE EXISTS AT ALL, AND WHY ITS FIRST QUERY MUST RUN FIRST.
    analyses/54 could not price the consultant decision, only bracket it,
    because nobody counted the audiences before that build and ORCID grew
    underneath the comparison. Its closing note says: run the baseline BEFORE
    the seed change lands. This is that baseline. Queries 1 to 3 are written to
    be run on the CURRENT build, with the new seed rows committed and NOT yet
    built. Queries 4 and 5 are the same questions after.

    Queries 2 and 3 also do something the consultant change did not: they show
    the exact titles each new rule will take, before it takes them. The
    consultant pattern moved 17,360 records across 6,386 titles - roughly twice
    what the reading behind it implied - and that was only discovered after the
    build.
*/


-- ----------------------------------------------------------------------------
-- 1. ⭐ RUN THIS BEFORE THE BUILD. THE TEN AUDIENCES AS THEY STAND TODAY.
--
--    CONFIRMED people per audience. Paste the result into this comment, then
--    build, then run query 4. The difference between the two, minus the growth
--    the six untouched audiences show, is what these four decisions cost.
--
--    RESULT 2026-11-19, BEFORE the build, CONFIRMED only:
--
--      lecturer           427,256     <- touched: honorary, visiting scholar/fellow
--      researcher         343,716     <- touched: medical physicist joins
--      hcp_broad          177,645     <- touched: medical physicist changes route
--      hcp_researcher     109,486     <- touched: medical physicist joins
--      students           107,091     <- touched: the bare qualification leaves
--      hcp_practitioner    57,297     <- touched: medical physicist leaves
--      faculty_head        17,305     <- CONTROL
--      hcp_administrator    8,377     <- CONTROL
--      pharmacist           2,083     <- CONTROL
--      librarian              708     <- CONTROL
--
--    IDENTICAL TO analyses/54 QUERY 1, to the person, on every row. Both were
--    run on 2026-11-19 and nothing has rebuilt in between, so this baseline is
--    the same build rather than a fresh count of a moved population. That is
--    the cleanest starting point this project has ever had for a seed change.
--
--    FOUR CONTROL AUDIENCES, which is what makes the subtraction honest. None
--    of the five decisions can reach faculty_head, hcp_administrator,
--    pharmacist or librarian. Whatever those four move by between this run and
--    query 4 is the ORCID growth that happened in the hours between the two
--    builds, and it applies to the other six as well.
--
--    ⭐ AND ONE THING THIS RESULT TEACHES, WORTH MORE THAN THE NUMBERS.
--    `people` and `records` came back EQUAL on all ten rows. fct_researcher_roles
--    is ONE ROW PER PERSON PER AUDIENCE - that is what
--    assert_one_row_per_researcher asserts - so count(*) on it is not a record
--    count and never was. The record counts in this project live in
--    dim_title_group.frequency and in stg_role_records, and a figure quoted as
--    `records` off this table is a people figure wearing the wrong label. The
--    column is kept in these queries only so the equality stays visible.
-- ----------------------------------------------------------------------------
select
    role_key,
    count(distinct snid)                                as people,
    count(*)                                            as rows_which_equal_people
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
where role_label = 'CONFIRMED'
group by role_key
order by people desc
;


-- ----------------------------------------------------------------------------
-- 2. ⭐ RUN THIS BEFORE THE BUILD TOO. WHAT EACH NEW PATTERN WILL TAKE.
--
--    The three new rows in seeds/title_group_patterns.csv all move titles into
--    support_technical, which feeds no audience. This query applies the same
--    three regexes to today's dictionary, scoped exactly as the seed scopes
--    them - against model_title_group, because that is the column the pattern
--    is conditioned on and the column the collision test reads.
--
--    WHAT TO LOOK FOR, in order of how much it would change the decision:
--      - a title in the list that is plainly a working academic post
--      - the records column far larger than the reading implied
--      - anything in the honorary list that is a CLINICAL honorary post, which
--        would mean the teaching_academic scope is not holding
--
--    RESULT 2026-11-19 (before the build):
--      [paste here]
-- ----------------------------------------------------------------------------
with veto as (
    select r'librar|bibliotec|bibliotek|bibliothek|biblioth[eé]|biblioth[eè]|библиотек|бібліотек|kütüphane|図書館|图书馆' as p
)
select
    case
        when regexp_contains(d.title, r'\bhonorary\b')
            then '1 honorary - leaves Lecturer'
        when regexp_contains(d.title, r'\bvisiting\b.*\b(scholar|scholars|fellow|fellows)\b')
            then '2 visiting scholar / fellow - leaves Lecturer'
        else '3 bare qualification - leaves Students'
    end                                                 as rule,
    d.title,
    d.frequency                                         as records,
    d.model_title_group,
    d.decision_source
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d, veto v
where (
        d.model_title_group = 'teaching_academic'
        and regexp_contains(d.title, r'\bhonorary\b|\bvisiting\b.*\b(scholar|scholars|fellow|fellows)\b')
        and not regexp_contains(d.title, v.p)
      )
   or (
        d.model_title_group = 'student'
        and regexp_contains(d.title, r'^(phd|ph d|phds|ph ds|dphil|d phil|doctorate|phd holder|ph d holder|phd degree|ph d degree|doctorate degree|master|masters|master s|master degree|master s degree|msc|m sc|ms|m s|ma|m a|mphil|m phil|mba|m b a|mtech|m tech|meng|m eng|bachelor|bachelors|bachelor degree|bsc|b sc|ba|b a|beng|b eng|btech|b tech)$')
      )
order by rule, records desc
limit 200
;


-- 2a. The same three rules as a total, because query 2 is a list and a list
--     does not tell you whether to be worried. PEOPLE, not records - the
--     consultant decision was argued in records and paid in people, and the
--     two differ by a factor nobody can guess.
--
--     READ THIS ONE WITH A CAVEAT. It applies the regexes to evidence_title
--     lowercased, not to the normalised dictionary title, so a title whose
--     punctuation normalisation changes it (`Ph.D.` -> `ph d`) is counted by
--     query 2 and missed here. It is the floor of the cost, not the cost.
--
--     RESULT 2026-11-19, BEFORE the build:
--
--       1 honorary                     lecturer      978 people
--       2 visiting scholar / fellow    lecturer    1,727 people
--       3 bare qualification           students    4,241 people
--
--     ⭐ ONE AUDIENCE EACH, AND NOTHING ELSE. Not a single one of these three
--     rules reaches a second audience - no clinical row, no researcher row, no
--     faculty_head row. That is the SCOPE HOLDING, and it is the thing that
--     was worth measuring before the build rather than after: the consultant
--     pattern was scoped the same way and still had to be measured twice,
--     because scoping protects the groups the pattern cannot see and says
--     nothing about the group it can.
--
--     WHAT IT COSTS, against query 1:
--       Lecturer   427,256 -> about 424,551   -2,705   -0.63%
--       Students   107,091 -> about 102,850   -4,241   -3.96%
--
--     Students pays six times the rate Lecturer does. That is not a surprise
--     and not an argument against the decision - the bare qualification was 6%
--     of the hand-read sample and the single largest source of doubt in the
--     audience, so taking it out was always going to be the most expensive of
--     the three. 3.96% measured against 6% read is the reading holding up
--     well: the sample over-represented the problem slightly, as a sample
--     drawn from CONFIRMED rows tends to.
--
--     These are FLOORS, for the reason in the caveat above: the regexes here
--     run on evidence_title, so a title whose normalisation changes it
--     (`Ph.D.` -> `ph d`) is counted by query 2 and missed here. Query 4 is
--     what settles the real figure.
select
    case
        when regexp_contains(lower(evidence_title), r'\bhonorary\b')
            then '1 honorary'
        when regexp_contains(lower(evidence_title), r'\bvisiting\b.*\b(scholar|scholars|fellow|fellows)\b')
            then '2 visiting scholar / fellow'
        else '3 bare qualification'
    end                                                 as rule,
    role_key,
    count(distinct snid)                                as people_in_that_audience_today,
    count(*)                                            as records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
where role_label = 'CONFIRMED'
  and (
        (title_group = 'teaching_academic'
         and regexp_contains(lower(evidence_title), r'\bhonorary\b|\bvisiting\b.*\b(scholar|scholars|fellow|fellows)\b')
         and not regexp_contains(lower(evidence_title), r'librar|bibliotec|bibliotek|bibliothek'))
     or (title_group = 'student'
         and regexp_contains(lower(evidence_title), r'^(phd|phds|dphil|doctorate|master|masters|msc|ms|ma|mphil|mba|mtech|meng|bachelor|bachelors|bsc|ba|beng|btech)$'))
      )
group by rule, role_key
order by rule, people_in_that_audience_today desc
;


-- ----------------------------------------------------------------------------
-- 3. ⭐ RUN THIS BEFORE THE BUILD TOO. THE TWO CONSEQUENCES OF MOVING
--    `medical physicist` FROM practitioner TO researcher.
--
--    The override is written for the EXACT title. Part (a) asks whether that
--    is enough or whether the variants carry more than the 346 records the
--    decision was taken on.
--
--    Part (b) is the one that matters, and it is the lesson of 2026-11-19
--    applied in advance: check the group a move could leak INTO, not only the
--    group it was aimed at. The researcher group feeds hcp_researcher, which
--    is what was wanted - but it ALSO feeds the all-fields Researcher
--    audience, with no department test at all, and hcp_researcher DOES test
--    the department. So:
--      - a medical physicist in an oncology or radiology department ends up in
--        Researcher, Clinical researcher and Healthcare (broad)
--      - a medical physicist whose department reads as physics ends up in
--        Researcher ONLY, and leaves the healthcare audiences altogether
--    Part (b) says how many are in each case before the build decides it.
--
--    RESULT 2026-11-19, BEFORE the build, part (b):
--
--      health_clinical   170 people   Cancer Center / Center for Radiology and
--                                     Nuclear Medicine / Clinic for Radiooncology /
--                                     Clinic for Radiotherapy / Clinical Oncology /
--                                     Clinical Physics, Health Technology Management
--                                     Unit / Comprehensive Cancer Center / Department
--                                     for Medical Physics and Radiation Protection
--
--    ONE ROW. No life_biomedical, no other discipline, no NO DEPARTMENT MATCH.
--    Every medical physicist this pipeline confirms today works in a
--    radiotherapy, radiology or oncology department, and the example
--    departments read like a list of exactly the places the decision assumed
--    they would be. So the feared case - a medical physicist in a physics
--    department who falls out of the healthcare audiences when the title moves
--    to the researcher group - DOES NOT EXIST among the people we confirm.
--    The move costs nothing in hcp_broad.
--
--    ⭐ AND THE GAP THAT RESULT OPENS, WHICH IS THE REAL FINDING HERE.
--    The decision was taken on 346 RECORDS. This query sees 170 PEOPLE, and it
--    can only ever see people who are CONFIRMED somewhere today - that is what
--    the filter says. A medical physicist whose department does not read as
--    clinical is in no audience at all right now, so they are invisible to
--    this query by construction. After the move they would confirm in the
--    all-fields Researcher audience, which has no department test, on the
--    title alone.
--
--    So the healthcare side of this decision is measured and safe, and the
--    Researcher side is NOT: query 3c sizes the population this one cannot
--    see, and it has to be read before the gain in Researcher is quoted.
-- ----------------------------------------------------------------------------
select
    title,
    frequency                                           as records,
    title_group,
    model_title_group,
    decision_source
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where regexp_contains(title, r'medical physic')
order by records desc
;


-- 3b. Where those people would land, read off the department they already
--     carry. health_clinical and life_biomedical are the two disciplines
--     hcp_researcher accepts - anything else means the healthcare audiences
--     are lost for that person.
select
    coalesce(discipline, 'NO DEPARTMENT MATCH')         as discipline,
    count(distinct snid)                                as people,
    count(*)                                            as records,
    string_agg(distinct evidence_dept order by evidence_dept limit 8)   as example_departments
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
where role_label = 'CONFIRMED'
  and lower(evidence_title) = 'medical physicist'
group by discipline
order by people desc
;


-- 3c. ⭐ THE POPULATION QUERY 3b CANNOT SEE. Everyone who typed this title,
--     confirmed or not, read off the record table rather than off the audience
--     table. The difference between this and 3b's 170 is the number of people
--     who are in NO audience today and who the move puts into Researcher.
--
--     WHY IT IS A SEPARATE QUERY AND NOT A WIDER FILTER ON 3b: fct_researcher_roles
--     only holds people an audience already claimed, so no filter on it can
--     reach somebody it never claimed. Asking the same table more gently is how
--     a selection bias survives a measurement.
--
--     RESULT 2026-11-19, BEFORE the build:
--
--       people_who_typed_it   291
--       records               354
--
--     ⭐ AND THIS IS WHY 3b WAS NOT ENOUGH. 291 people typed this title and 3b
--     found 170 of them. So roughly 121 PEOPLE - about 41% - typed `medical
--     physicist` and are in NO AUDIENCE AT ALL today. They are not a cost of
--     the move and they were not in the decision: the open item was phrased as
--     a MOVE, from practitioner to clinical researcher, and it turns out to be
--     a move AND a recruitment.
--
--     Why they are invisible today. The title sits in the practitioner group,
--     and both audiences it feeds need more than the title: hcp_practitioner
--     is title_and_field, so a non-clinical department keeps them out, and
--     hcp_broad needs 0.60 from 0.35xtitle + 0.25xorg + 0.40xdept, which a
--     clinical title with no clinical department cannot reach unless the
--     employer scores full marks. After the move the title sits in the
--     researcher group, and the all-fields Researcher audience is
--     title_required at 0.75xtitle + 0.25xorg - so a HUMAN-decided title
--     scores 0.75 on the title axis alone and confirms with no department and
--     no employer at all. Every one of the 291 should appear in Researcher
--     after the build.
--
--     READ THE 121 AS APPROXIMATE, and here is the exact reason. 3b filters
--     lower(evidence_title) on fct_researcher_roles, while this query filters
--     role_title on stg_role_records, which is ALREADY normalised. They are
--     not the same string test - `Medical Physicist.` normalises to `medical
--     physicist` but does not survive a bare lower() - so 3b can undercount
--     slightly and the gap can be a little smaller than 121. Query 4 settles
--     it, and nothing between here and there needs the exact number.
--
--     WHAT DOES NOT CHANGE. All 170 of the people already confirmed carry a
--     health_clinical department, which is one of the two disciplines
--     hcp_researcher accepts, so they re-confirm there and roll straight back
--     up into hcp_broad. The healthcare side of this decision still costs
--     nothing. The only open figure is how many of the 291 land in Researcher
--     who were nowhere before.
select
    count(distinct snid)                                as people_who_typed_it,
    count(*)                                            as records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records`
-- role_title is ALREADY normalised in this model - title_key is
-- md5(role_title) and joins straight to dim_title_group - so no Jinja and no
-- lower() belongs here. analyses/20 is in check_analyses.py's known-bad list
-- for exactly that mistake: a file carrying Jinja cannot be pasted into
-- BigQuery without compiling it first.
where role_title = 'medical physicist'
;


-- ----------------------------------------------------------------------------
-- 4. AFTER THE BUILD. THE SAME TEN AUDIENCES.
--
--    Subtract query 1. The audiences none of these four decisions touches -
--    hcp_administrator, faculty_head, pharmacist, librarian - give the growth
--    rate for the hours between the two runs, which should be near zero if
--    both are run on the same day. That is the whole point of running query 1
--    first: the cost is then a subtraction rather than an estimate.
--
--    RESULT 2026-11-20, after the build. PASS=79 WARN=1 ERROR=0 SKIP=0, the
--    one warning being the known assert_second_group_rules_do_not_collide
--    baseline, which moved 247 -> 250 with the refreshed vocabulary.
--
--      THE FOUR CONTROLS FIRST, because they set the resolution:
--        faculty_head        17,305 ->  17,421    +116   +0.670%
--        librarian              708 ->     713      +5   +0.706%
--        pharmacist           2,083 ->   2,090      +7   +0.336%
--        hcp_administrator    8,377 ->   8,398     +21   +0.251%
--                                              median   +0.503%
--
--      THE SIX THE DECISIONS TOUCHED:
--        lecturer           427,256 -> 426,449    -807   -0.189%
--        students           107,091 -> 102,026  -5,065   -4.729%
--        researcher         343,716 -> 344,847  +1,131   +0.329%
--        hcp_broad          177,645 -> 178,556    +911   +0.513%
--        hcp_researcher     109,486 -> 109,854    +368   +0.336%
--        hcp_practitioner    57,297 ->  57,351     +54   +0.094%
--
--    THE COST, as a subtraction against the control median rather than an
--    estimate. This is what analyses/54 could not do.
--
--      Lecturer     expected 429,405, actual 426,449   cost 2,956
--                   predicted before the build: 2,705.  HELD.
--      Students     expected 107,630, actual 102,026   cost 5,604
--                   predicted before the build: 4,241 as a FLOOR. The real
--                   cost is 32% above the floor, and the floor said why:
--                   query 2a ran on evidence_title, so `Ph.D.` -> `ph d` and
--                   every other title the normalisation changes was invisible
--                   to it. Query 5 shows the rule took 26 titles carrying
--                   11,304 records, against the 4,241 people 2a could see.
--      Practitioner expected  57,585, actual  57,351   loss   234
--                   `medical physicist` took 170 confirmed people out of it.
--                   Consistent, and the remaining 64 is inside the band.
--      hcp_broad    expected 178,538, actual 178,556   difference +18
--                   ⭐ THE PREDICTION THAT MATTERED MOST, AND IT IS EXACT.
--                   3b found all 170 medical physicists in health_clinical
--                   departments, so they re-confirm in hcp_researcher and roll
--                   back up here, and the move costs this audience nothing.
--                   +0.513% against a control median of +0.503%.
--
--    ⭐ AND THE TWO THE METHOD CANNOT MEASURE, WHICH IS WORTH MORE THAN THE
--    NUMBERS ABOVE. The medical physicist gain in Researcher and in
--    hcp_researcher does NOT appear. 291 people is 0.085% of Researcher and
--    170 is 0.155% of hcp_researcher, while the four control audiences spread
--    across 0.455 percentage points - which is about 1,560 people at
--    Researcher's base. The decision is four to eighteen times smaller than
--    the instrument's resolution.
--
--    So control subtraction has a FLOOR, and it is roughly half a percent of
--    the audience being measured. Below that, this method cannot tell a
--    decision from a week of ORCID. The answer is not a better subtraction:
--    it is query 5, which reads the dictionary and sees the title itself -
--    one title, 354 records, researcher, HUMAN, with no growth term in it at
--    all. Size a small decision on the dictionary and a large one on the
--    audience.
-- ----------------------------------------------------------------------------
select
    role_key,
    count(distinct snid)                                as people
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
where role_label = 'CONFIRMED'
group by role_key
order by people desc
;


-- ----------------------------------------------------------------------------
-- 5. AFTER THE BUILD. DID THE FIVE DECISIONS LAND WHERE THEY WERE AIMED?
--
--    One row per decision, and every one of them should read the way the note
--    in the seed says it will. A title still in its old group here means the
--    rule did not fire - which is the failure mode assert_overrides_take_effect
--    and assert_title_patterns_all_match_something exist to catch, but those
--    tests cannot see a pattern that fired on the wrong titles.
--
--    RESULT 2026-11-20, after the build. ALL FIVE LANDED:
--
--      medical physicist   researcher         HUMAN        1 title     354 recs
--      doctor              practitioner       HUMAN        1 title   4,536 recs
--      honorary            support_technical  PATTERN    568 titles  1,969 recs
--      visiting            support_technical  PATTERN    479 titles  4,338 recs
--      bare qualification  support_technical  PATTERN     26 titles 11,304 recs
--
--    ⭐ AND THEN THE RESIDUE, WHICH IS THE REAL FINDING IN THIS FILE AND WAS
--    NOT PREDICTED. Both teaching patterns are scoped to the group the MODEL
--    chose, which protects every group they cannot see - that was the point,
--    and 2a confirmed it held. What nobody asked before the build is what is
--    LEFT in those groups. Query 5 answers it, because it reads every title
--    matching the regex regardless of where it ended up:
--
--      honorary, STILL ASSIGNED, by VECTOR:
--        researcher        241 titles   1,127 records   <- IN the Researcher audience
--        trainee_clinical  100 titles     198 records
--        practitioner       92 titles     113 records
--        leadership         17 titles      19 records
--        student            11 titles      14 records
--        pharmacist          3 titles       3 records
--
--      visiting scholar / fellow, STILL ASSIGNED, by VECTOR:
--        researcher        285 titles   1,216 records   <- IN the Researcher audience
--        student            33 titles      38 records
--        trainee_clinical   13 titles      17 records
--        practitioner       11 titles      11 records
--
--    THE TWO RESIDUES ARE NOT THE SAME KIND OF THING, and the difference is
--    the whole point.
--
--    VISITING IS CONSISTENT AND NEEDS NOTHING. `visiting researcher` (67,191
--    records) and `visiting scientist` (32,662) were deliberately sent to the
--    researcher group on 2026-10-09 and 2026-10-21, on the argument that they
--    name research. `visiting research fellow` is the same title with a
--    different noun, so leaving it in Researcher follows the decision already
--    taken rather than escaping it. The question answered on 19 November was
--    whether a visiting fellow is TEACHING STAFF, and it is answered.
--
--    HONORARY IS NOT CONSISTENT, and it contradicts a decision this project
--    already took. On 2026-10-16 marketing REJECTED `honorary researcher`
--    outright - it is in this result as `researcher / HUMAN / 1 title / 71
--    records`, not assigned to anything. But 241 other honorary titles sit in
--    the researcher group by VECTOR and ARE assigned, carrying 1,127 records:
--    `honorary research fellow` and its family. So the same reasoning that
--    removed one string leaves 241 of its siblings in the project's
--    highest-scoring audience.
--
--    NO RULE IS PROPOSED HERE. Widening the honorary pattern to the researcher
--    group is one field, and it would take ~1,127 records out of a 99.0%
--    audience - which is a definition question of exactly the shape marketing
--    just answered for Lecturer, asked again about Researcher, and not a thing
--    to decide from the size of it. It is written up as an open item instead.
--
--    AND THE CLINICAL RESIDUE IS THE SCOPE WORKING, not a hole. 198 records in
--    trainee_clinical and 113 in practitioner are honorary clinical posts. An
--    honorary consultant is usually a working clinician who holds the honorary
--    title so they can supervise students - the person the November decision
--    explicitly did not want to lose - and the teaching scope is what kept
--    them. This is the one place where leaving a pattern narrow was the whole
--    reason it was safe.
--
--    ONE SMALL STRUCTURAL HOLE, measured at 10 records and not patched.
--    `bare qualification / student / PATTERN / 1 title / 10 records` is not
--    the new rule firing. Seed row 28 sends student-shaped titles from the
--    RESEARCHER group into `student`, and its alternation contains `phd` and
--    `ph d`. The new rule is scoped to model group `student`, so a bare
--    qualification the model read as researcher is claimed by row 28, lands
--    in Students, and the exclusion never sees it. The two do not collide
--    because they are scoped to different groups, which is why the test
--    passed. The clean fix is an `unless_pattern` on ROW 28 - a title that is
--    nothing but a qualification is not a doctoral student - and it is one
--    field. Left alone pending Merve, because it is 10 records today and the
--    honorary question above would land in the same build.
-- ----------------------------------------------------------------------------
select
    case
        when title = 'medical physicist'  then 'medical physicist -> expect researcher, HUMAN'
        when title = 'doctor'             then 'doctor -> expect practitioner, HUMAN'
        when regexp_contains(title, r'\bhonorary\b')
                                          then 'honorary -> expect support_technical, PATTERN'
        when regexp_contains(title, r'\bvisiting\b.*\b(scholar|scholars|fellow|fellows)\b')
                                          then 'visiting -> expect support_technical, PATTERN'
        else 'bare qualification -> expect support_technical, PATTERN'
    end                                                 as decision,
    title_group,
    decision_source,
    count(*)                                            as titles,
    sum(frequency)                                      as records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where title in ('medical physicist', 'doctor')
   or regexp_contains(title, r'\bhonorary\b')
   or regexp_contains(title, r'\bvisiting\b.*\b(scholar|scholars|fellow|fellows)\b')
   or regexp_contains(title, r'^(phd|ph d|phds|ph ds|dphil|d phil|doctorate|phd holder|ph d holder|phd degree|ph d degree|doctorate degree|master|masters|master s|master degree|master s degree|msc|m sc|ms|m s|ma|m a|mphil|m phil|mba|m b a|mtech|m tech|meng|m eng|bachelor|bachelors|bachelor degree|bsc|b sc|ba|b a|beng|b eng|btech|b tech)$')
group by decision, title_group, decision_source
order by decision, records desc
;
