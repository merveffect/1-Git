/*
    ============================================================================
    23. THE GROUPS NOBODY HAS LOOKED AT
    ============================================================================
    Two of the ten title groups have been reviewed properly: practitioner, over
    2026-10-20, and librarian, which was rebuilt from nothing. The other eight
    have never been read.

    That is worth saying plainly, because the review we HAVE done found a
    great deal - 2,684 veterinarians matched to DENTIST, epidemiologists
    classified as clinicians, a lawyer matched to dentist - and there is no
    reason the unreviewed groups are cleaner. We simply do not know.

    Ranked by how dirty they are, against what they feed:

      support_technical       36.64%   feeds nothing, and gets dirtier by
                                       design - it is where rejected titles
                                       are parked
      practitioner            33.80%   PARTLY reviewed 2026-10-20, from
                                       40.64% - see analyses/24, the reading
                                       covered a fraction of it
      pharmacist              31.71%   the pharmacist audience, 2,335 people
      leadership              27.76%   faculty_head + hcp_administrator, and
                                       it received 2,271 records from the
                                       researcher review without having been
                                       read itself
      trainee_clinical        18.40%   the hcp roles
      researcher_established  15.61%   PARTLY reviewed 2026-10-21, from
                                       16.29% - ~3.6% of its records were
                                       actually read, see analyses/24
      student                  8.94%   feeds nothing
      researcher_early         6.94%   researcher + hcp_researcher
      teaching_academic        6.74%   lecturer, 400,445 people - the LOWEST
                                       share anywhere and the LARGEST
                                       absolute count of low-confidence
                                       records, 813,682

    Two of the ten have been READ IN PART, which is not the same as
    reviewed, and the difference is measured in analyses/24. For
    researcher_established the hand-reading covered about 150 of 27,963
    titles - roughly 23% of the records below 0.75 and 3.6% of the group -
    and every query was filtered `similarity < 0.75`, so 84% of it was never
    looked at in any form.

    What IS established for that group is narrower and still worth something:
    the largest offenders by frequency are handled, and the remaining
    low-confidence records are substantially explained by long titles scoring
    lower against short anchors and by the sciences leaning correctly on the
    single anchor `scientist`. What is NOT established is that nothing is
    wrong above the threshold, and `business consultant` at 0.843 is the
    standing reminder that wrong answers live up there too.

    THIS FILE DELIBERATELY SKIPS support_technical AND student. They are the
    dirtiest and the second cleanest, and both feed no audience, so reviewing
    them now would be work spent on nobody. They become urgent the day
    marketing asks for a support-staff or student audience, which is question
    1.7 in docs/open-questions.md.

    Query 2 is the one I would start with. researcher_established is 2.3x
    dirtier than researcher_early for no obvious reason, and it feeds the
    second-largest audience in the project.

    No build is needed for any of this.
    ============================================================================
*/


-- ###########################################################################
-- 1. FACULTY_HEAD — IS THE COMPANY VETO STILL DOING ANYTHING?
--
--    A promise from 2026-10-16 that was never kept. org_name_patterns holds
--    three faculty_head rows with org_score 0.00, which veto a leadership
--    title at a company. They were written to stop corporate executives
--    arriving in the audience.
--
--    But we now know WHY they were arriving: int_anchor_embeddings was
--    incremental, so removing 'chief executive officer', 'founder' and
--    'president' from the leadership anchors had never taken effect. The
--    veto was built to contain a bug, and the bug is fixed.
--
--    So the veto may now be dead weight. This asks. A large count means it
--    is still load-bearing and stays. A tiny one means it is belt and braces
--    and can be retired - and retiring a rule nobody needs is worth doing,
--    because every rule left in place is a thing the next person has to
--    understand.
-- ###########################################################################
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.org_name_patterns` p
            WHERE p.role_key = 'faculty_head'
              AND p.org_score = 0.0
              AND REGEXP_CONTAINS(COALESCE(f.evidence_org, ''), p.name_pattern)
        ) THEN '1. organisation matches a veto pattern'
        ELSE '2. no veto'
    END                                             AS veto,
    role_label,
    COUNT(DISTINCT snid)                            AS people,
    ROUND(AVG(org_score), 3)                        AS avg_org_score,
    ROUND(AVG(role_final_score), 3)                 AS avg_final_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` f
WHERE role_key = 'faculty_head'
GROUP BY veto, role_label
ORDER BY veto, role_label;


-- ###########################################################################
-- 2. RESEARCHER_ESTABLISHED — THE WEAKEST END, NEVER READ
--
--    16.29% of its records sit below 0.75, against 6.94% for
--    researcher_early. Both groups feed exactly the same two roles, so the
--    difference is not design - it is that one group's nine anchors are
--    doing more work than the other's thirteen.
--
--    Nine anchors for this group: senior researcher, senior scientist,
--    research scientist, principal investigator, group leader, staff
--    scientist, scientist, head of laboratory, scientific director.
--
--    Sort what you read into the same three piles that worked on
--    practitioner: WRONG, which needs an override; RIGHT BUT UNCONFIDENT,
--    which needs an anchor and is usually the larger pile; and AMBIGUOUS,
--    which is a marketing question.
-- ###########################################################################
SELECT
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    runner_up,
    ROUND(margin, 3)            AS margin,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'researcher_established'
  AND is_assigned
  AND similarity < 0.75
ORDER BY frequency DESC
LIMIT 60;

-- 2a. The same per anchor, which is the diagnostic that worked on
--     practitioner: an anchor carrying a high share below 0.75 is the
--     signature of a MISSING anchor, not a bad one.
SELECT
    matched_anchors[OFFSET(0)]                      AS nearest_anchor,
    COUNT(*)                                        AS distinct_titles,
    SUM(frequency)                                  AS records,
    ROUND(AVG(similarity), 3)                       AS avg_similarity,
    ROUND(SAFE_DIVIDE(SUM(IF(similarity < 0.75, frequency, 0)),
                      SUM(frequency)), 4)           AS share_records_below_075
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'researcher_established'
  AND is_assigned
GROUP BY nearest_anchor
ORDER BY records DESC;


-- ###########################################################################
-- 3. LEADERSHIP — 27.76%, AND IT FEEDS TWO AUDIENCES
--
--    Read alongside analyses/17 query 1, which lists this group's biggest
--    titles and how many of each confirm. That query already showed the
--    corporate titles mostly failing as intended - ceo 879 people with 55
--    confirmed, founder 411 with 31, owner 188 with 2 - so this is the
--    weakest end rather than the known-bad end.
-- ###########################################################################
SELECT
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'leadership'
  AND is_assigned
  AND similarity < 0.75
ORDER BY frequency DESC
LIMIT 50;


-- ###########################################################################
-- 4. PHARMACIST — 31.71%, AND IT IS A STANDALONE AUDIENCE
--
--    Only 2,335 confirmed people, so the absolute numbers are small, but it
--    is the one audience where a single title group is the whole thing. Ten
--    anchors carry it.
-- ###########################################################################
SELECT
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'pharmacist'
  AND is_assigned
  AND similarity < 0.75
ORDER BY frequency DESC
LIMIT 40;


-- ###########################################################################
-- 2b. THE TWO ANCHORS WHOSE DAMAGE IS IN THE LONG TAIL
--
--    Query 2a on 2026-10-21, after 37 overrides had cleared the obvious
--    cases, left two anchors untouched and they are the worst in the group:
--
--      scientific director   3,123 titles   84,691 records   39.65% below 0.75
--      head of laboratory    5,203 titles  128,050 records   37.19% below 0.75
--
--    Query 2 cannot show why. Ordered by frequency it surfaces about 2,583
--    of their records, because ~47,600 records below 0.75 on 'head of
--    laboratory' alone are spread across thousands of small titles. 5,203
--    distinct titles leaning on one anchor is the signal: 'head of' and
--    'director' are generic heads, the same failure as 'library manager'
--    attracting 'manager' and 'senior scientist' attracting every senior X.
--
--    So this reads them per anchor instead, 30 each, which is the shape that
--    worked on dentist, gynaecologist and pathologist in analyses/22 query
--    10.
--
--    DECIDE WHAT YOU ARE LOOKING AT BEFORE ACTING. A head of a real
--    laboratory arriving unconfidently needs nothing - the assignment is
--    right and 'researcher' confirms at 0.60, so even the weakest match
--    clears it once the organisation resolves. A head of something that is
--    not a laboratory needs an override. There is no anchor to add here:
--    unlike the dental specialties, 'head of laboratory' is not missing a
--    word, it is holding one that is too general.
--
--    AND LEAVE THE SCIENCES ALONE. microbiologist 2,559 records,
--    geophysicist 1,498, computational biologist 1,331, ecologist 1,101,
--    archaeologist 878 and a dozen more are all CORRECT and all leaning on
--    the single word 'scientist'. Giving each its own anchor would lift the
--    metric and change nobody's audience, while risking exactly what
--    'pathologist' did three times over. A high share below 0.75 can be
--    honest low confidence rather than error - the same as 'dr' and 'md'
--    carrying 146,865 records in the clinical group.
-- ###########################################################################
SELECT
    matched_anchors[OFFSET(0)]  AS nearest_anchor,
    title,
    frequency,
    ROUND(similarity, 3)        AS similarity,
    runner_up,
    needs_human_review
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE title_group = 'researcher_established'
  AND is_assigned
  AND similarity < 0.75
  AND matched_anchors[OFFSET(0)] IN ('head of laboratory', 'scientific director')
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY matched_anchors[OFFSET(0)] ORDER BY frequency DESC
) <= 30
ORDER BY matched_anchors[OFFSET(0)], frequency DESC;
