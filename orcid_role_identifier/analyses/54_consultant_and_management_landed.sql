/*
    ============================================================================
    54. WHAT THE 19 NOVEMBER BUILD ACTUALLY DID
    ============================================================================
    fec7941 (21 overrides + the consultant pattern) and 48f98ce (the librarian
    veto that unblocked it) were pushed unbuilt. This file is the verification,
    run on the clean build of 19 November 2026 - PASS=54, ERROR=0, SKIP=0.

    WHY IT EXISTS AS A FILE. The decision it verifies was taken from a 400-row
    reading, and the 400 rows were a `limit`, not the population. Three of the
    four answers below differ from what was on screen when the call was made,
    and one of them differs by a factor of ten. None of that changes the
    decision - it was reaffirmed and it stands - but a reader a month from now
    should be able to see the size that was actually paid.

    ⭐ THE ONE THING TO FIX NEXT TIME. Query 1 compares against a baseline that
    is SEVEN DAYS OLD, because nobody ran it before the build. ORCID grows
    continuously, so the comparison carries a week of growth inside it and the
    cost of the change had to be estimated rather than read. Run query 1 BEFORE
    a seed change lands, not only after.
*/


-- ----------------------------------------------------------------------------
-- 1. THE TEN AUDIENCES AFTER THE BUILD.
--
--    RESULT 2026-11-19, CONFIRMED only, against the one-pager's 12 November
--    column:
--
--      lecturer          423,668 -> 427,256   +3,588   +0.85%
--      researcher        340,705 -> 343,716   +3,011   +0.88%
--      hcp_broad         181,295 -> 177,645   -3,650   -2.01%
--      hcp_researcher    108,805 -> 109,486     +681   +0.63%
--      students          105,658 -> 107,091   +1,433   +1.36%
--      hcp_practitioner   62,141 ->  57,297   -4,844   -7.80%
--      faculty_head       17,218 ->  17,305      +87   +0.51%
--      hcp_administrator   8,258 ->   8,377     +119   +1.44%
--      pharmacist          2,064 ->   2,083      +19   +0.92%
--      librarian             700 ->     708       +8   +1.14%
--
--    THE SIX AUDIENCES THIS COMMIT DID NOT TOUCH all grew, between 0.63% and
--    1.36%, median 0.92%. That is the week of ORCID growth, and it is also the
--    only estimate of it we have. Applying it to practitioner gives an expected
--    62,713 against an actual 57,297, so the consultant removal cost about
--    5,400 PEOPLE. hcp_broad lost about 5,300 the same way, almost all of it
--    the practitioner roll-up.
--
--    5,400 is an ESTIMATE AND IS LABELLED ONE. The honest bracket is query 3's.
-- ----------------------------------------------------------------------------
select role_key, role_label, count(distinct snid) as people
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
group by 1, 2
order by role_key, role_label
;


-- ----------------------------------------------------------------------------
-- 2. WHERE THE CONSULTANT TITLES WENT.
--
--    RESULT 2026-11-19:
--
--      support_technical  PATTERN   6,386 titles   17,360 records   <- the rule
--      support_technical  VECTOR      414             961
--      researcher         VECTOR      541             645
--      teaching_academic  VECTOR      457             601
--      support_technical  HUMAN         6             384
--      trainee_clinical   VECTOR      156             219
--      leadership         VECTOR       74              79
--      librarian          PATTERN       3               3   <- the veto, working
--      ... tail
--
--    ⭐ 17,360 RECORDS, NOT THE ~9,600 THE READING IMPLIED. analyses/35 query 3
--    stopped at 400 rows and frequency 15; 6,386 distinct titles carry the word
--    and the tail below that cut is most of them. The decision was taken on a
--    view of roughly half the population. It was reaffirmed after the size was
--    raised once, and it stands - this line records the price, it does not
--    reopen it.
--
--    THE SCOPE HELD. researcher, teaching_academic, trainee_clinical and
--    leadership consultants are all still VECTOR - the pattern never saw them,
--    because it is scoped to practitioner. That is what the scope is for.
--
--    THE VETO HELD. The three titles that failed
--    assert_title_patterns_do_not_collide on the first build now resolve to
--    librarian by PATTERN, not to support_technical. `library services
--    consultant` is a librarian.
-- ----------------------------------------------------------------------------
select title_group, decision_source,
       count(*) as titles, sum(frequency) as records
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
where regexp_contains(title, r'\b(consultant|consultor)')
group by 1, 2
order by records desc
;


-- ----------------------------------------------------------------------------
-- 3. HOW MANY PEOPLE ACTUALLY LEFT PRACTITIONER.
--
--    A person has several employment records. Moving one of them out of
--    practitioner removes the person from the audience only if no other record
--    puts them back. Records cannot answer that question; this query can.
--
--    RESULT 2026-11-19:
--
--      people with a consultant record            14,083
--      still in practitioner via another job       2,535
--      not in practitioner now                    11,548
--      still in hcp_broad                          4,139
--
--    ⭐ 11,548 IS AN UPPER BOUND, NOT THE LOSS. hcp_practitioner is
--    `title_and_field`: it needs a human-health department as well as the
--    title. A consultant record with no department never confirmed, so a share
--    of the 11,548 were never in the audience to lose. The bracket is
--    therefore 5,400 (query 1, growth-adjusted) to 11,548 (here), and the low
--    end is the one to quote.
--
--    2,535 people - 18% - kept the audience through a second job. That is the
--    whole reason this query exists and the reason no accuracy figure may be
--    adjusted from a record count.
-- ----------------------------------------------------------------------------
with consultant_titles as (
    select title_key
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
    where title_group = 'support_technical'
      and decision_source = 'PATTERN'
      and regexp_contains(title, r'\b(consultant|consultor)')
),
affected as (
    select distinct r.snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    join consultant_titles c using (title_key)
),
still as (
    select a.snid,
           ifnull(logical_or(f.role_key = 'hcp_practitioner'), false) as in_practitioner,
           ifnull(logical_or(f.role_key = 'hcp_broad'),        false) as in_hcp_broad
    from affected a
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` f
           on f.snid = a.snid and f.role_label = 'CONFIRMED'
    group by a.snid
)
select
    count(*)                     as people_with_a_consultant_record,
    countif(in_practitioner)     as still_in_practitioner_via_another_job,
    countif(not in_practitioner) as actually_left_practitioner,
    countif(in_hcp_broad)        as still_in_hcp_broad
from still
;


-- ----------------------------------------------------------------------------
-- 4. DID THE MANAGEMENT TITLES LAND WHERE WE SENT THEM.
--
--    `leadership` is a TITLE GROUP read by exactly two audiences:
--    hcp_administrator (needs a human-health department) and faculty_head
--    (Education employer only). The intent was hcp_administrator. A university
--    hospital that ROR types as education, or an unresolved employer whose NAME
--    reads academic, lets a clinical title reach faculty_head instead.
--
--    THE INTENDED DESTINATION WORKS. `medical director` -> hcp_administrator
--    CONFIRMED 179 and hcp_broad CONFIRMED 161. `nurse educator` -> lecturer
--    CONFIRMED 20, which is exactly what that override was for.
--
--    ⭐ BUT 52 PEOPLE ARE CONFIRMED IN faculty_head ON A CLINICAL TITLE:
--
--      medical director                                    27   <- NOT new
--      chief medical officer                                4   <- new
--      nurse manager                                        4   <- new
--      hospital director                                    2   <- new
--      deputy medical director                              2
--      director of nursing department                       2
--      director of nursing                                  1   <- new
--      ten titles pairing professor with a clinical post   10
--
--    ONLY 11 OF THE 52 ARE OURS. Bare `medical director` was moved to
--    leadership on 2026-10-29 and its 27 faculty_head members have been sitting
--    there since, unnoticed, because nobody ran this query then. The third
--    instance this month of a decision that was verified in the group it was
--    aimed at and not in the group it could leak into.
--
--    42 of the 52 carry no academic word at all and are simply wrong. The other
--    10 pair a professorship with a clinical directorship - `professor and
--    interim executive director of nursing` may well be real faculty
--    leadership - and are a question, not an error.
--
--    NOT URGENT, AND NOT NOTHING. faculty_head is parked and is not delivered
--    to marketing, so no campaign can reach these 52 today. The moment it ships
--    they are wrong members of an audience already measured at 83.3%.
--    PROBABLE is not delivered either, so the much larger PROBABLE leak -
--    `medical director` 286, `chief medical officer` 100 - costs nothing now
--    but shows how much is waiting behind the threshold.
-- ----------------------------------------------------------------------------
select
    lower(evidence_title)   as title,
    title_group,
    role_key,
    role_label,
    count(distinct snid)    as people
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
where regexp_contains(lower(evidence_title),
        r'\b(medical director|chief medical officer|hospital director|director of nursing|nurse manager|medical manager|nurse educator|medical coordinator)\b')
group by 1, 2, 3, 4
order by title, people desc
;
