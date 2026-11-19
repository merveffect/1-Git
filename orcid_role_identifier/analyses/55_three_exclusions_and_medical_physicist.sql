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
    built; queries 4 and 5 are the same questions after.

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
--    RESULT 2026-11-19 (before the build):
--      [paste here]
-- ----------------------------------------------------------------------------
select
    role_key,
    count(distinct snid)                                as people,
    count(*)                                            as records
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
--     RESULT 2026-11-19 (before the build):
--       [paste here]
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
--    RESULT 2026-11-19 (before the build):
--      [paste here]
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
--     hcp_researcher accepts; anything else means the healthcare audiences
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


-- ----------------------------------------------------------------------------
-- 4. AFTER THE BUILD. THE SAME TEN AUDIENCES.
--
--    Subtract query 1. The audiences none of these four decisions touches -
--    hcp_administrator, faculty_head, pharmacist, librarian - give the growth
--    rate for the hours between the two runs, which should be near zero if
--    both are run on the same day. That is the whole point of running query 1
--    first: the cost is then a subtraction rather than an estimate.
--
--    RESULT 2026-11-19 (after the build):
--      [paste here]
-- ----------------------------------------------------------------------------
select
    role_key,
    count(distinct snid)                                as people,
    count(*)                                            as records
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
--    RESULT 2026-11-19 (after the build):
--      [paste here]
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
