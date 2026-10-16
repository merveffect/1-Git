/*
    ============================================================================
    21. LIBRARIAN — THE FIRST BUILD OF A ROLE THAT HAD NEVER RUN
    ============================================================================
    librarian was enabled on 2026-10-16 having been disabled since the first
    build. The recorded reason was size - 1,154 people, 258 marketable - but
    that came from a regex query in analyses/archive/12, and the title group
    the role points at did not exist. Zero anchors. So the role had never
    produced a person and the number it was rejected on was not a measurement
    of it.

    It now has 25 title anchors and a new library_information discipline with
    16, two of which were MOVED off non_academic.

    WHAT THIS FILE IS FOR. Two questions, and only one of them is about
    librarian:

      1. Did the role produce anybody, and is what it produced actually
         librarians? Queries 1-4.

      2. Did adding a 22nd group damage the other 21? Queries 5-6. Adding a
         group changes the competition for EVERY value, not just library
         ones, because the non-target groups are what a value competes
         against.

    A CAVEAT ON QUESTION 2, STATED UP FRONT. There is no before/after
    snapshot of the dictionary - nothing captured dim_title_group as it stood
    before this build - so drift cannot be measured directly. Query 6 uses
    runner_up as a proxy: for a value now sitting in librarian, runner_up is
    the group it beat, which is the closest thing we have to where it would
    otherwise have gone. That is weaker than a diff and should not be quoted
    as one.

    If this role turns out to be genuinely tiny, that is a fine answer. It was
    asked for on the grounds that a publisher sells to libraries, not on the
    grounds that it would be large. What would NOT be fine is it being tiny
    for a reason we have not noticed.
    ============================================================================
*/


-- ###########################################################################
-- 1. DID IT PRODUCE ANYBODY? And how does that compare to the rejection?
--    The 1,154 is printed here only so the two can be told apart - it is
--    not a baseline, it was measured a different way on different data.
-- ###########################################################################
SELECT
    role_label,
    COUNT(DISTINCT snid)                AS people,
    ROUND(AVG(role_final_score), 3)     AS avg_score,
    ROUND(MIN(role_final_score), 3)     AS min_score,
    ROUND(MAX(role_final_score), 3)     AS max_score,
    ROUND(AVG(role_score), 3)           AS avg_title_axis,
    ROUND(AVG(org_score), 3)            AS avg_org_axis,
    ROUND(AVG(dept_score), 3)           AS avg_dept_axis
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_key = 'librarian'
GROUP BY role_label
ORDER BY role_label;


-- ###########################################################################
-- 2. THE EYEBALL TEST — what job titles actually landed in the group?
--    Read the whole list. The weights are 0.70 title-led, so a wrong title
--    here is a wrong person, and the department cannot rescue it.
-- ###########################################################################
SELECT
    title,
    frequency,
    ROUND(similarity, 3)    AS similarity,
    matched_anchors,
    runner_up,
    ROUND(margin, 3)        AS margin,
    decision_source
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'librarian'
  AND is_assigned
ORDER BY frequency DESC
LIMIT 60;


-- ###########################################################################
-- 3. THE WEAK END — where leakage shows up first.
--    The collision risk named when the anchors were written was
--    support_technical: administrator, coordinator, analyst, research
--    officer. If 'information professional' or 'archivist' dragged any of
--    those in, it is at the bottom of the similarity range, not the top.
-- ###########################################################################
SELECT
    title,
    frequency,
    ROUND(similarity, 3)    AS similarity,
    matched_anchors,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'librarian'
  AND is_assigned
ORDER BY similarity ASC
LIMIT 40;


-- ###########################################################################
-- 4. DID THE NON-ENGLISH ANCHORS EARN THEIR PLACE?
--    11 of the 25 anchors are translations. That was a deliberate call -
--    'librarian' means one thing in every language, so widening the region
--    costs nothing - but it is a call, so it should be checked. If no
--    non-English title ever lands here, the translations are dead weight
--    and the next role should not get them by default.
-- ###########################################################################
SELECT
    title,
    frequency,
    ROUND(similarity, 3)    AS similarity,
    matched_anchors
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'librarian'
  AND is_assigned
  AND NOT REGEXP_CONTAINS(title, r'^[\x00-\x7F]*$')
ORDER BY frequency DESC
LIMIT 40;


-- ###########################################################################
-- 5. THE NEW DISCIPLINE, AND WHAT non_academic GAVE UP
--    'library' and 'university library' were moved off non_academic, which
--    supports no role. Anything leaving non_academic for library_information
--    is a gain. The case to watch is the opposite one: a department that
--    used to sit in non_academic and has now landed in a discipline that
--    DOES feed a role, because that is noise entering a scored audience.
-- ###########################################################################
SELECT
    discipline,
    COUNT(*)                        AS distinct_departments,
    SUM(frequency)                  AS records,
    ROUND(AVG(similarity), 3)       AS avg_similarity,
    ROUND(MIN(similarity), 3)       AS min_similarity
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
WHERE is_assigned
  AND discipline IN ('library_information', 'non_academic')
GROUP BY discipline;

-- 5a. The library_information members themselves, weakest first.
SELECT
    department,
    frequency,
    ROUND(similarity, 3)    AS similarity,
    matched_anchors,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
WHERE discipline = 'library_information'
  AND is_assigned
ORDER BY similarity ASC
LIMIT 40;


-- ###########################################################################
-- 6. WHAT DID THE 22ND GROUP TAKE FROM THE OTHER 21?
--    runner_up as a proxy for where a value would otherwise have gone - see
--    the caveat in the header. Read it as "librarian is competing with
--    these groups", not as "librarian took this many values from them".
--
--    A large count against support_technical or non_academic is the intended
--    effect: neither feeds an audience. A large count against
--    teaching_academic or either researcher group deserves a look, because
--    those are real audiences losing records.
-- ###########################################################################
SELECT
    runner_up                           AS competed_against,
    COUNT(*)                            AS distinct_titles,
    SUM(frequency)                      AS records,
    ROUND(AVG(margin), 3)               AS avg_margin,
    ROUND(AVG(similarity), 3)           AS avg_similarity,
    COUNTIF(margin < 0.05)              AS titles_won_narrowly
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'librarian'
  AND is_assigned
GROUP BY runner_up
ORDER BY records DESC;
