/*
    ============================================================================
    51. THE STUDENTS AUDIENCE - what to run, before and after
    ============================================================================
    Merve, 2026-11-12: "sen simdi students diye yeni bir audience olusturabilir
    misin?" - with faculty_head parked until a different source table arrives.

    WHAT WAS ADDED. One config block and two seed rows sets. No model, macro or
    SQL file was touched.

      dbt_project.yml         roles.students
      org_type_scores.csv     10 rows, inherited from researcher
      role_detail_map.csv     6 org_type rows, same labels as researcher

    THE GROUP IS NOT NEW - THE AUDIENCE IS. `student` has been one of the nine
    title groups from the start and has 11 anchors, so the model has been
    assigning it all along with nothing on the other end. Three things fill it:
    the anchors (VECTOR), title_group_patterns row 28 (PATTERN), and the
    researcher -> student rule in title_group_second, which is 21,668 records.

    RUN ORDER
      Queries 1 and 2 on the CURRENT build, before anything is rebuilt.
      Then:  dbt build --select org_type_scores+ role_detail_map+ \
                               int_employment_scored+
      Then queries 3 to 7.

    WHY THAT BUILD COMMAND. A new role is read by jinja in
    int_employment_scored and everything downstream of it. The dictionary does
    not change at all - no re-embedding, no vector search - so this is the
    cheapest build in the project.

    THE ONE SETTING THAT DEFINES THIS AUDIENCE is current_only: true. Seven of
    the nine other roles count a post somebody has left. A student in 2010 is
    not a student now, so this one does not, and query 2 measures what that
    decision costs before the build rather than after.
*/


-- ----------------------------------------------------------------------------
-- 1. BEFORE - what is actually in the student group, and who put it there.
--
--    decision_source is the column to read. PATTERN and the second group are
--    certain matches scoring 1.0; VECTOR is graded and is where any error
--    will be. If VECTOR dominates, the 11 anchors need reading before this
--    audience is delivered to anybody.
-- ----------------------------------------------------------------------------
select
    decision_source,
    count(*)                                            as distinct_titles,
    sum(frequency)                                      as records,
    round(avg(group_score), 3)                          as avg_group_score,
    string_agg(title order by frequency desc limit 10)  as biggest_titles
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where is_assigned
  and (title_group = 'student' or title_group_2 = 'student')
group by decision_source
order by records desc
;


-- ----------------------------------------------------------------------------
-- 2. BEFORE - WHAT current_only: true COSTS, which is the whole design of this
--    audience stated as a number.
--
--    A person counts only if they hold a student title in a CURRENT post. This
--    splits the population three ways: current only, past only, and both. The
--    past-only column is what the setting removes, and it should be large -
--    these are today's professors and postdocs, who are already in Lecturer
--    and Researcher. If it comes back small, the setting is doing less than it
--    looks and is worth re-arguing.
-- ----------------------------------------------------------------------------
with student_records as (
    select
        s.snid,
        s.is_current
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
         on s.title_key = t.title_key
        and t.is_assigned
        and (t.title_group = 'student' or t.title_group_2 = 'student')
),
per_person as (
    select
        snid,
        countif(is_current)      as current_posts,
        countif(not is_current)  as past_posts
    from student_records
    group by snid
)
select
    case
        when current_posts > 0 and past_posts = 0 then '1 current only - IN'
        when current_posts > 0 and past_posts > 0 then '2 both - IN'
        else                                           '3 past only - EXCLUDED by current_only'
    end                                                 as standing,
    count(*)                                            as people
from per_person
group by standing
order by standing
;


-- ----------------------------------------------------------------------------
-- 1b. BEFORE - QUERY 1 CONFLATED TWO THINGS AND HAS TO BE SPLIT.
--
--     decision_source describes how the title's PRIMARY group was decided, not
--     how it reached `student`. So `graduate research assistant` and `phd
--     researcher`, which arrive through the researcher -> student rule, were
--     counted under their primary's VECTOR decision, and query 1's 188,054
--     VECTOR records are two populations added together.
--
--     This separates them, because they do not carry the same risk. A title
--     whose PRIMARY group is student was chosen by the embedding against 11
--     anchors and is a guess. A title that gains student as a SECOND group
--     matched a literal pattern and is certain.
-- ----------------------------------------------------------------------------
select
    case
        when title_group   = 'student' then '1 PRIMARY group is student'
        when title_group_2 = 'student' then '2 SECOND group - a title naming two jobs'
    end                                                 as route,
    decision_source,
    count(*)                                            as distinct_titles,
    sum(frequency)                                      as records,
    round(avg(coalesce(group_score, group_2_score)), 3) as avg_score,
    string_agg(title order by frequency desc limit 8)   as biggest_titles
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where is_assigned
  and (title_group = 'student' or title_group_2 = 'student')
group by route, decision_source
order by records desc
;


-- ----------------------------------------------------------------------------
-- 1c. BEFORE - THE BARE `student` ANCHOR, which is the librarian lesson
--     arriving in a new group.
--
--     The anchor list carries `student,student,en,` - one word, and a generic
--     occupational noun. The librarian block in dbt_project.yml records what
--     that does: a one-word profession forces the embedding to match on a word
--     that other jobs also contain, and 'library manager' pulled in 'manager',
--     17,340 records. Here the same shape predicts STAFF who work WITH
--     students being read as students: student affairs, student services, dean
--     of students, student recruitment.
--
--     This is a measurement, not a claim. If it comes back small the anchor is
--     fine as it is. If it is large, the fix is a veto row in
--     title_group_patterns, not a threshold change - the same conclusion
--     librarian reached.
--
--     THE REGEX IS MULTILINGUAL FROM THE FIRST LINE. An English-only pattern
--     beside a multilingual anchor set has now been wrong four times in this
--     project, every time in the same direction, so the Spanish, Portuguese,
--     French, German and Turkish forms are here from the start rather than
--     added after the first reading.
-- ----------------------------------------------------------------------------
with flagged as (
    select
        title,
        frequency,
        title_group,
        decision_source,
        round(group_score, 3)                           as group_score,
        regexp_contains(title, r'\b(student|students|studierenden|studenten|estudiantil|estudiantiles|etudiante?s?|öğrenci)\s+(affairs|services|service|success|support|welfare|experience|engagement|life|union|administration|records|recruitment|admissions|placement|advisor|adviser|advising|counsel\w*|mentor\w*|wellbeing|well being|accommodation|housing|finance|funding)\b') as staff_of_students,
        regexp_contains(title, r'\b(dean|director|head|manager|coordinator|coordinador\w*|officer|administrator|registrar|secretar\w*|advisor|adviser|counsel\w*|dekan\w*|decano)\b.{0,24}\b(student|students|studierenden|studenten|estudiantil|estudiantiles|etudiante?s?|öğrenci)\b') as leads_students,
        regexp_contains(title, r'\b(intern|interne|internee|internship|internships|estagi\w+|praktikant\w*|stagiaire|stajyer|trainee|trainees|graduate trainee|management trainee)\b') as intern_or_trainee
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned
      and (title_group = 'student' or title_group_2 = 'student')
)
select
    case
        when staff_of_students or leads_students
             then '1 STAFF WHO WORK WITH STUDENTS - almost certainly wrong'
        when intern_or_trainee
             then '2 INTERN OR TRAINEE - a definition question for marketing'
        else '3 reads as a student'
    end                                                 as kind,
    count(*)                                            as distinct_titles,
    sum(frequency)                                      as records,
    round(avg(group_score), 3)                          as avg_score,
    string_agg(title order by frequency desc limit 20)  as biggest_titles
from flagged
group by kind
order by kind
;

-- 1c-ii. The staff half itself, biggest first, so a veto can be written from
--        what is actually there rather than from the four compounds I can name.
with flagged as (
    select title, frequency, title_group, round(group_score, 3) as group_score
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where is_assigned
      and (title_group = 'student' or title_group_2 = 'student')
      and (regexp_contains(title, r'\b(student|students|studierenden|studenten|estudiantil|estudiantiles|etudiante?s?|öğrenci)\s+(affairs|services|service|success|support|welfare|experience|engagement|life|union|administration|records|recruitment|admissions|placement|advisor|adviser|advising|counsel\w*|mentor\w*|wellbeing|well being|accommodation|housing|finance|funding)\b')
        or regexp_contains(title, r'\b(dean|director|head|manager|coordinator|coordinador\w*|officer|administrator|registrar|secretar\w*|advisor|adviser|counsel\w*|dekan\w*|decano)\b.{0,24}\b(student|students|studierenden|studenten|estudiantil|estudiantiles|etudiante?s?|öğrenci)\b'))
)
select title, frequency, title_group, group_score
from flagged
order by frequency desc
limit 60
;


-- ----------------------------------------------------------------------------
-- 1c-iii. BEFORE - MERVE'S TRAINEE RULE, AND WHETHER THE ORG RULE ALREADY
--         IMPLEMENTS IT.
--
--         Merve, 2026-11-12: "Staj yapan bir ogrenci -> ogrencidir / Sirketteki
--         graduate trainee -> ogrenci degil, calisan". Query 1c sized the
--         family at 424 titles and 3,942 records, which is large enough to
--         need an answer and small enough that the answer is cheap either way.
--
--         THE CLAIM TO TEST is that no title rule is needed, because the
--         Education-only organisation rule decided in the same message already
--         removes the company trainees on its own. This splits the family two
--         ways at once - by employer type, and by whether the title names a
--         STUDENT as well as a trainee - so the claim is checked rather than
--         assumed.
--
--         HOW TO READ IT. The only cell that matters is Education with no
--         student word: a `graduate trainee` or `management trainee` employed
--         by a university, which the org rule cannot refuse and Merve's rule
--         says is an employee. If that cell is small, nothing more is needed.
--         If it is not, it is one veto row in title_group_patterns.
-- ----------------------------------------------------------------------------
with family as (
    select
        s.snid,
        s.role_title,
        s.organisation,
        s.org_id,
        regexp_contains(s.role_title,
            r'\b(student|students|studierende\w*|studenten|estudiante\w*|etudiante?s?|öğrenci|phd|ph d|doctoral|doctorate|postgraduate|post graduate|graduate school|undergraduate|master|masters|bachelor)\b')
                                                        as also_names_a_student
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
         on s.title_key = t.title_key
        and t.is_assigned
        and (t.title_group = 'student' or t.title_group_2 = 'student')
    where s.is_current
      and regexp_contains(s.role_title,
            r'\b(intern|interne|internee|internship|internships|estagi\w+|praktikant\w*|stagiaire|stajyer|trainee|trainees)\b')
),
typed as (
    select
        f.*,
        coalesce(o.ror_types[safe_offset(0)], 'UNKNOWN')    as org_type
    from family f
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.int_org_resolved` o
           on f.organisation = o.organisation
          and f.org_id is not distinct from o.org_id
)
select
    case when org_type = 'Education' then 'Education - QUALIFIES'
         else 'not Education - already refused' end     as employer,
    if(also_names_a_student, 'title also names a student',
                             'TRAINEE WORD ONLY')       as title_says,
    count(*)                                            as records,
    count(distinct snid)                                as people,
    string_agg(distinct role_title order by role_title limit 25) as example_titles
from typed
group by employer, title_says
order by employer, title_says
;


-- ----------------------------------------------------------------------------
-- 1d. BEFORE - WHAT "AN EDUCATION EMPLOYER IS REQUIRED" COSTS, BY ROR TYPE.
--
--     Merve, 2026-11-12: "organizasyon bilgisi cozulmeyenler ogrenci olarak
--     atanmasin. egitim kurumunda olmalari sart". Implemented as Education
--     1.00 and every other type 0.00, with weights 0.60 / 0.40 against a 0.65
--     threshold so the organisation can actually refuse somebody - at the
--     previous 0.75 / 0.25 and 0.60 it could not have refused anyone at all.
--
--     THIS QUERY IS THE BILL FOR THAT DECISION, and it is run before the build
--     rather than discovered after. Two of the rows it will return are real
--     students that the rule now refuses:
--
--       Healthcare   a medical student or clinical trainee at a hospital
--       Facility     a doctoral student at a research institute - Max Planck,
--                    CNRS, CSIC
--
--     The rest are the intended effect: Company is the graduate trainees
--     Merve excluded in the same message, and UNKNOWN is refused by name.
--
--     If Healthcare and Facility together are large, they are one seed edit
--     away from being let back in and this is the number that argues for it.
--     It reproduces int_employment_scored's own org join - on organisation AND
--     org_id, with ror_types[safe_offset(0)] as the type - so it reads what
--     the scoring will read rather than something near enough.
-- ----------------------------------------------------------------------------
with student_records as (
    select
        s.snid,
        s.organisation,
        s.org_id,
        s.is_current
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
         on s.title_key = t.title_key
        and t.is_assigned
        and (t.title_group = 'student' or t.title_group_2 = 'student')
    /*  current_only: true, so a past post cannot carry anybody and counting
        them here would overstate every row.  */
    where s.is_current
),
typed as (
    select
        r.snid,
        coalesce(o.ror_types[safe_offset(0)], 'UNKNOWN')    as org_type
    from student_records r
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.int_org_resolved` o
           on r.organisation = o.organisation
          and r.org_id is not distinct from o.org_id
)
select
    org_type,
    count(distinct snid)                                as people,
    /*  ⭐ ror_types VALUES ARE LOWERCASE - `education`, `healthcare`,
        `facility`. The first version of this CASE compared against
        'Education' and reported all 106,050 qualifying people as REFUSED,
        which is a wrong answer that looked like a finding. upper() on both
        sides, which is what int_employment_scored already does on its own
        join to this seed.  */
    case upper(org_type)
        when 'EDUCATION'  then '1 QUALIFIES'
        when 'HEALTHCARE' then '2 REFUSED - and these are real students'
        when 'FACILITY'   then '2 REFUSED - and these are real students'
        when 'COMPANY'    then '3 REFUSED - intended, the graduate trainees'
        when 'UNKNOWN'    then '4 REFUSED BY NAME - unresolved organisation'
        else '5 REFUSED - intended'
    end                                                 as verdict
from typed
group by org_type, verdict
order by people desc
;

-- 1d-ii. The two refused populations that are real students, with their
--        titles, so the decision to let them back in or not is made on what
--        the people actually wrote rather than on the ROR type alone.
with student_records as (
    select s.snid, s.role_title, s.organisation, s.org_id
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
         on s.title_key = t.title_key
        and t.is_assigned
        and (t.title_group = 'student' or t.title_group_2 = 'student')
    where s.is_current
),
typed as (
    select
        r.*,
        coalesce(o.ror_types[safe_offset(0)], 'UNKNOWN')    as org_type
    from student_records r
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.int_org_resolved` o
           on r.organisation = o.organisation
          and r.org_id is not distinct from o.org_id
)
select
    org_type,
    role_title,
    count(*)                                            as records,
    count(distinct snid)                                as people
from typed
where upper(org_type) in ('HEALTHCARE', 'FACILITY')  -- lowercase in the data
group by org_type, role_title
order by records desc
limit 50
;


-- 1d-iii. THE FIVE TYPES I LABELLED "REFUSED - intended" WITHOUT READING THEM.
--
--         1d-ii read facility and healthcare because those are the two I had
--         flagged as real students. The other five carry a note in
--         org_type_scores.csv that says the refusal is intended, and that note
--         is MY CLAIM, not a measurement - I wrote it from the shape of the
--         ROR type name. One of them is bigger than healthcare:
--
--           funder      3,138 people   <- larger than healthcare's 2,370
--           government    283
--           nonprofit     241
--           other         161
--           archive       105
--
--         funder is the one that needs reading. A doctoral student's employer
--         being typed `funder` is not obviously wrong: ROR types CNRS, INSERM,
--         several research councils and some national agencies as funders, and
--         those bodies host thousands of doctoral candidates. If these titles
--         read like 1d-ii's did, the note is wrong and 3,138 people are being
--         refused on a word I chose rather than on evidence.
--
--         company is deliberately NOT in this list. It was read in 1c-iii and
--         it is the one refusal with a measured reason behind it.
--
--         RAN 2026-11-12, AND MY NOTE WAS WRONG FOR ALL FIVE. The titles are
--         the same titles 1d-ii returned:
--
--           funder      phd student 718, phd candidate 517, student 215,
--                       phd 166, graduate student 122, md phd 90,
--                       medical student 89, research scholar 74 ...
--           government  phd student 54, student 29, phd 17,
--                       research scholar 17, phd candidate 12
--           nonprofit   phd student 64, student 25, phd candidate 23
--           other       phd student 37, student 18
--           archive     phd student 25, phd candidate 13, student 11
--
--         Every one of those is a student saying so in their own words. The
--         note beside these rows in org_type_scores.csv claimed the refusal
--         was intended; it was intended by me, from the word, and the data
--         does not support it for a single one of the five.
--
--         ONE REAL NON-STUDENT IN THE WHOLE LIST: archive `academic editor`,
--         16 people. That is a title in the `student` group that should not
--         be there at all, and it is independent of the org rule - fixing the
--         org score would simply deliver it. Small, but it is a defect in the
--         group rather than in the employer, so it gets its own look.
-- ----------------------------------------------------------------------------
with student_records as (
    select s.snid, s.role_title, s.organisation, s.org_id
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
         on s.title_key = t.title_key
        and t.is_assigned
        and (t.title_group = 'student' or t.title_group_2 = 'student')
    where s.is_current
),
typed as (
    select
        r.*,
        coalesce(o.ror_types[safe_offset(0)], 'UNKNOWN')    as org_type
    from student_records r
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.int_org_resolved` o
           on r.organisation = o.organisation
          and r.org_id is not distinct from o.org_id
)
select
    org_type,
    role_title,
    count(*)                                            as records,
    count(distinct snid)                                as people
from typed
where upper(org_type) in ('FUNDER', 'GOVERNMENT', 'NONPROFIT', 'OTHER', 'ARCHIVE')
group by org_type, role_title
order by records desc
limit 50
;


-- ----------------------------------------------------------------------------
-- 3. AFTER - the audience, beside the other nine so it can be read in scale.
--
--    TWO THINGS WRONG IN THE FIRST VERSION OF THIS QUERY, both mine, both
--    worth leaving written down because they are easy to repeat:
--
--    `is_reachable` DOES NOT EXIST. Nothing in the project has a column by
--    that name. Reachability is four consent flags OR-ed together, and the
--    canonical expression is in fct_role_audience_summary:
--
--        is_marketable or is_advertisable
--          or is_legitimate_interest or is_book_author
--
--    Book-author consent is the fourth and was a decision of Merve's against
--    a column that was in the source and simply not selected - so an
--    expression with only the first three silently under-reports.
--
--    AND fct_researcher_roles IS IN THE SCORING DATASET, not presentation.
--    models/scoring/fct_researcher_roles.sql, despite being the model the
--    whole presentation layer is built from. Presentation holds
--    fct_role_audience, which is that table joined to the CDP contact rows -
--    so it is the only place the consent flags exist, and this query has to
--    read it rather than the fact table.
--
--    The reachable figure is the one marketing is given, so an audience
--    stated without it is not a deliverable size.
-- ----------------------------------------------------------------------------
select
    role_key,
    role_label,
    count(distinct snid)                                as people,
    count(distinct if(is_marketable or is_advertisable
                      or is_legitimate_interest or is_book_author,
                      snid, null))                      as reachable_people,
    count(distinct if(in_cdp, snid, null))              as in_cdp_people
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
group by role_key, role_label
order by role_key, role_label
;


-- ----------------------------------------------------------------------------
-- 4. AFTER - which route each student arrived by, because the three routes
--    have different error rates and only one of them is a guess.
-- ----------------------------------------------------------------------------
select
    f.role_label,
    e.title_group                                       as group_that_carried_them,
    case
        when e.title_group_2 = 'student' and e.title_group = 'student'
             then 'second group - a title naming two jobs'
        else 'primary group'
    end                                                 as route,
    count(distinct f.snid)                              as people,
    round(avg(f.role_final_score), 3)                   as avg_score
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` f
join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` e
     on e.snid = f.snid
    and e.role_key = f.role_key
    and e.role_score > 0
where f.role_key = 'students'
group by f.role_label, group_that_carried_them, route
order by people desc
;


-- ----------------------------------------------------------------------------
-- 5. AFTER - THE ONE ORG SCORE THAT WAS FLAGGED FOR MEASUREMENT.
--
--    org_type_scores for this role was inherited from researcher value for
--    value, because nothing about where students work had been measured and a
--    bespoke curve would have been a number argued from the shape of the
--    problem. Company at 0.60 is the row that does not transfer cleanly: for a
--    researcher it means industrial R&D, for a student it means an intern or a
--    Werkstudent. This says how many people that score is deciding.
-- ----------------------------------------------------------------------------
select
    coalesce(org_type, 'UNRESOLVED')                    as org_type,
    role_label,
    count(distinct snid)                                as people,
    round(avg(role_final_score), 3)                     as avg_score,
    string_agg(distinct evidence_title order by evidence_title limit 6) as example_titles
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
where role_key = 'students'
group by org_type, role_label
order by people desc
;


-- ----------------------------------------------------------------------------
-- 6. AFTER - WHO IS IN TWO PLACES AT ONCE, which is the point of the second
--    group and also the thing marketing has to understand before using this.
--
--    A doctoral researcher is a student AND a researcher. Both are true and
--    both audiences contain them, so a campaign that targets Researchers and
--    a campaign that targets Students will reach some of the same people.
--    This is the size of that overlap.
-- ----------------------------------------------------------------------------
with confirmed as (
    select snid, role_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_label = 'CONFIRMED'
),
students as (select snid from confirmed where role_key = 'students')
select
    c.role_key                                          as also_in,
    count(distinct c.snid)                              as people_shared
from confirmed c
join students s using (snid)
where c.role_key != 'students'
group by also_in
order by people_shared desc
;


-- ----------------------------------------------------------------------------
-- 7. AFTER - 100 people to read, so this audience gets a measured accuracy
--    like the other nine rather than an assumed one.
--
--    400 PEOPLE, IN ONE DRAW, because that is what the other audiences got.
--    docs/open-questions.md 2.12: "400 CONFIRMED people at random per
--    audience (seed val_2026_11)". It was a single sample, not four rounds of
--    100 - analyses/48's round mechanism is a later instrument and the
--    published accuracies do not come from it. Merve, 2026-11-13: "biz
--    digerlerini de 4 round calistirmamistik ki ... 400 row bakmistik sanki
--    tekte dimi?" Correct, and this query said otherwise until now.
--
--    row_number over farm_fingerprint(cast(snid as string)) is random with
--    respect to the data and REPEATABLE with respect to the person, so the
--    same positions return the same people after a rebuild and a reading can
--    be re-run to ask whether those same people are still in the audience.
--    rand() would throw that away.
--
--    THE RANGE IS EXPLICIT so the 100 already read are not read twice.
--    Positions 1-100 were read on 2026-11-12: 88 correct, 2 wrong, 10 unsure.
--    Set from_position := 101 and to_position := 400 for the remaining 300,
--    and the union of the two is one random sample of 400 - the blocks are
--    consecutive slices of a single hash order, so concatenating them is the
--    same thing as having drawn 400 at once.
-- ----------------------------------------------------------------------------
declare from_position int64 default 101;
declare to_position   int64 default 400;

with ranked as (
    select
        snid,
        evidence_title                                  as job_title,
        evidence_org                                    as organisation,
        evidence_dept                                   as department,
        country_code,
        is_current,
        title_group,
        round(role_final_score, 3)                      as score,
        role_detail,
        row_number() over (order by farm_fingerprint(cast(snid as string)))
                                                        as hash_position
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_key = 'students'
      and role_label = 'CONFIRMED'
)
select * except (hash_position)
from ranked
where hash_position between from_position and to_position
order by hash_position
;


-- ----------------------------------------------------------------------------
-- 8. WHAT ROUND 1 OF THE HAND-READ FOUND, COUNTED EXACTLY RATHER THAN
--    EXTRAPOLATED FROM 100 ROWS.
--
--    Round 1 read 100 CONFIRMED students: 88 correct, 2 wrong, 10 unsure, so
--    97.8% of the decided. Nine of the ten unsure rows were ONE problem and
--    both wrong rows were nameable, so none of it needs estimating - these
--    are patterns, and a pattern can be counted.
--
--    THE BARE DEGREE. `PhD`, `Ph.D`, `Ph. D.`, `Master`, `Master's in
--    Marketing` as the whole job title. A degree is a CREDENTIAL, not a
--    status: the person may be studying for it or may have held it for twenty
--    years, and the title does not say which. This is 1.17's finding restated
--    - the same reason the doctoral second-group rule vetoes the senior words
--    - and it is the single largest source of doubt in this audience.
--
--    `DOCTORAL SUPERVISOR`, which is the inverse of a student and reached the
--    group anyway. A supervisor word next to a doctoral word is a faculty
--    post, and this is 2.8a's lesson in a new place: a MODIFIER can reverse a
--    title, and the embedding reads the subject rather than the role.
--
--    `EMPLOYEE`, which names no student at all and arrived at 0.835.
--
--    Why extrapolation would have been wrong: 9 of 100 reads as 9% and would
--    put ~9,500 people on the bare degree, but the sample was drawn from
--    CONFIRMED rows and the bare-degree titles cluster in a narrow score band
--    - so the real share is whatever this query says it is.
-- ----------------------------------------------------------------------------
with confirmed as (
    select
        snid,
        evidence_title,
        regexp_replace(lower(evidence_title), r'[^a-z0-9]', '')  as squashed,
        role_final_score
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_key = 'students'
      and role_label = 'CONFIRMED'
)
select
    case
        when regexp_contains(squashed, r'^(phd|phds|dphil|doctorate|doctor|dr)$')
            then '1 BARE DOCTORATE - credential, not status'
        when regexp_contains(squashed, r'^(master|masters|msc|mscs|ms|ma|mba|mtech|meng|me)$')
            then '2 BARE MASTER - credential, not status'
        when regexp_contains(squashed, r'supervisor|promotor|promoter|advisor|adviser')
            then '3 SUPERVISOR WORD - the inverse of a student'
        when regexp_contains(squashed, r'^employee[s]?$|^staff$|^personnel$')
            then '4 NAMES NO STUDENT AT ALL'
        when regexp_contains(squashed, r'^(academiceditor|editor|editorinchief)$')
            then '5 EDITOR - not a student either'
        else '0 names a student'
    end                                                 as bucket,
    count(*)                                            as records,
    count(distinct snid)                                as people,
    round(min(role_final_score), 3)                     as min_score,
    round(max(role_final_score), 3)                     as max_score
from confirmed
group by bucket
order by bucket
;


-- 8b. The exact strings behind buckets 1 to 5, so a pattern is written from
--     what people typed rather than from what I guessed they typed. Every
--     veto this project has got wrong was written from a guessed spelling -
--     the 1.17 veto failed three times running because the name pattern was
--     multilingual and the veto was English only.
with confirmed as (
    select
        snid,
        evidence_title,
        regexp_replace(lower(evidence_title), r'[^a-z0-9]', '')  as squashed,
        role_final_score
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_key = 'students'
      and role_label = 'CONFIRMED'
)
select
    lower(evidence_title)                               as title,
    count(*)                                            as records,
    count(distinct snid)                                as people,
    round(max(role_final_score), 3)                     as score
from confirmed
where regexp_contains(squashed, r'^(phd|phds|dphil|doctorate|doctor|dr)$')
   or regexp_contains(squashed, r'^(master|masters|msc|mscs|ms|ma|mba|mtech|meng|me)$')
   or regexp_contains(squashed, r'supervisor|promotor|promoter|advisor|adviser')
   or regexp_contains(squashed, r'^employee[s]?$|^staff$|^personnel$')
   or regexp_contains(squashed, r'^(academiceditor|editor|editorinchief)$')
group by title
order by records desc
limit 60
;


-- 8c. HOW BIG THE RISKY BAND IS, which is the finding I am least willing to
--     state from 100 rows and so will not.
--
--     In round 1 the split was total: 63 rows at score 1.0 with ZERO errors
--     and ZERO unsures, and 37 rows below 1.0 carrying all 12 problems -
--     32.4% of them. A score of exactly 1.0 means PATTERN or HUMAN, which is
--     a literal match or a person's own decision; anything below it is the
--     embedding's graded answer.
--
--     That is a clean story and 100 rows is not enough to tell it. What this
--     query does is size the two bands over the whole audience, so round 2
--     can be drawn to TEST the split rather than re-measure the average: if
--     the vector band really runs at ~32% doubtful, it deserves its own
--     sample rather than being averaged into a headline.
--
--     NO THRESHOLD IS PROPOSED HERE. The bare-degree titles in round 1 all
--     sat at or below 0.927, and that is exactly the kind of number this
--     project has twice turned into a rule it had to take back out again.
with confirmed as (
    select snid, role_final_score, title_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_key = 'students'
      and role_label = 'CONFIRMED'
)
select
    case
        when role_final_score >= 0.9999 then '1 score 1.0  - PATTERN or HUMAN, a literal match'
        when role_final_score >= 0.95   then '2 0.95-0.99  - vector, confident'
        when role_final_score >= 0.90   then '3 0.90-0.95  - vector'
        when role_final_score >= 0.85   then '4 0.85-0.90  - vector'
        else                                 '5 below 0.85 - vector, least confident'
    end                                                 as band,
    count(*)                                            as records,
    count(distinct snid)                                as people,
    round(100 * count(*) / sum(count(*)) over (), 1)     as pct_of_audience
from confirmed
group by band
order by band
;
