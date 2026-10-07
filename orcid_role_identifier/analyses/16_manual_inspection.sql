/*
    ============================================================================
    MANUAL INSPECTION — look at the raw ORCID data behind the decisions
    ============================================================================
    Five queries for reading with your own eyes rather than aggregating.
    Swap dev_ for prod_ when the time comes.
    ============================================================================
*/

-- ###########################################################################
-- 1. THE HCP SOFT MIDDLE
--    Department says health, but the person did not reach CONFIRMED.
--    108,280 people sit here. Read the titles: if they are clinical, the
--    title anchors have a gap. If they are not, the threshold is right.
-- ###########################################################################
SELECT
    e.evidence_title        AS orcid_role,
    e.evidence_dept         AS orcid_department,
    e.evidence_org          AS orcid_organisation,
    e.title_group,
    e.discipline,
    e.org_type,
    e.org_resolution_method,
    ROUND(e.role_score, 2)  AS title_score,
    ROUND(e.dept_score, 2)  AS dept_score,
    ROUND(e.org_score, 2)   AS org_score,
    ROUND(r.role_final_score, 3) AS final_score,
    r.role_label,
    COUNT(*)                AS people
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` e
JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
  ON e.snid = r.snid AND e.role_key = r.role_key
WHERE e.role_key = 'hcp'
  AND e.discipline = 'health_clinical'
  AND r.role_label != 'CONFIRMED'
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
ORDER BY people DESC
LIMIT 150;

-- The same, collapsed to just the titles, so the pattern is obvious:
SELECT
    e.evidence_title        AS orcid_role,
    e.title_group,
    COUNT(*)                AS people,
    ROUND(AVG(e.role_score), 2)  AS avg_title_score,
    ROUND(AVG(r.role_final_score), 3) AS avg_final_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` e
JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
  ON e.snid = r.snid AND e.role_key = r.role_key
WHERE e.role_key = 'hcp'
  AND e.discipline = 'health_clinical'
  AND r.role_label != 'CONFIRMED'
GROUP BY 1,2
ORDER BY people DESC
LIMIT 100;


-- ###########################################################################
-- 2. PROBABLE PHARMACISTS
--    12,980 people, against only 802 confirmed. Read the raw data and
--    decide whether the threshold or the weights are wrong.
-- ###########################################################################
SELECT
    e.evidence_title        AS orcid_role,
    e.evidence_dept         AS orcid_department,
    e.evidence_org          AS orcid_organisation,
    e.title_group,
    e.discipline,
    e.org_type,
    ROUND(e.role_score, 2)  AS title_score,
    ROUND(e.dept_score, 2)  AS dept_score,
    ROUND(e.org_score, 2)   AS org_score,
    ROUND(r.role_final_score, 3) AS final_score,
    COUNT(*)                AS people
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` e
JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
  ON e.snid = r.snid AND e.role_key = r.role_key
WHERE e.role_key = 'pharmacist'
  AND r.role_label = 'PROBABLE'
GROUP BY 1,2,3,4,5,6,7,8,9,10
ORDER BY people DESC
LIMIT 150;


-- ###########################################################################
-- 3. THE 44 PEOPLE WITH ALL FIVE ROLES
--    Every employment record they have, so you can judge whether five
--    roles is right or whether something is over-firing.
-- ###########################################################################
WITH five_role_people AS (
  SELECT snid
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.dim_researcher_role_flags`
  WHERE role_count = 5
)
SELECT
    s.snid,
    s.role_title_raw        AS orcid_role,
    s.department_raw        AS orcid_department,
    s.organisation_raw      AS orcid_organisation,
    s.country_code,
    s.is_current,
    s.start_date,
    s.end_date,
    s.recency_rank
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` s
JOIN five_role_people f USING (snid)
ORDER BY s.snid, s.recency_rank;

-- And which role each of them got, with the score and the evidence used:
WITH five_role_people AS (
  SELECT snid
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.dim_researcher_role_flags`
  WHERE role_count = 5
)
SELECT
    r.snid,
    r.role_key,
    r.role_label,
    ROUND(r.role_final_score, 3) AS score,
    r.role_detail,
    r.evidence_title,
    r.evidence_dept,
    r.evidence_org
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
JOIN five_role_people f USING (snid)
ORDER BY r.snid, r.role_key;


-- ###########################################################################
-- 4. THE 1,873 PEOPLE WITH FOUR ROLES
--    Grouped, so the pattern shows without reading 1,873 rows.
-- ###########################################################################
SELECT
    ARRAY_TO_STRING(roles, ' + ')   AS combination,
    COUNT(*)                        AS people
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.dim_researcher_role_flags`
WHERE role_count = 4
GROUP BY combination
ORDER BY people DESC;

-- The evidence behind them, by combination of title and department:
WITH four_role_people AS (
  SELECT snid
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.dim_researcher_role_flags`
  WHERE role_count = 4
)
SELECT
    r.evidence_title,
    r.evidence_dept,
    r.evidence_org,
    STRING_AGG(DISTINCT r.role_key ORDER BY r.role_key) AS roles_assigned,
    COUNT(DISTINCT r.snid)          AS people
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
JOIN four_role_people f USING (snid)
GROUP BY 1,2,3
ORDER BY people DESC
LIMIT 100;


-- ###########################################################################
-- 5. WHAT THE DICTIONARY THREW AWAY
--    42.5% of employment records carry a title the dictionary rejected.
--    These are the biggest ones. Anything clinical or academic in here is
--    a gap in the anchors, not noise.
-- ###########################################################################
SELECT
    title,
    frequency               AS records,
    title_group             AS nearest_group,
    runner_up,
    ROUND(similarity, 3)    AS similarity,
    ROUND(margin, 3)        AS margin,
    matched_anchors,
    CASE
      WHEN similarity < 0.65 THEN 'too far from every group'
      ELSE 'close to two groups at once'
    END                     AS why_rejected
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE NOT is_assigned
ORDER BY frequency DESC
LIMIT 150;

-- Same for departments:
SELECT
    department,
    frequency               AS records,
    discipline              AS nearest_group,
    runner_up,
    ROUND(similarity, 3)    AS similarity,
    ROUND(margin, 3)        AS margin,
    matched_anchors
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
WHERE NOT is_assigned
ORDER BY frequency DESC
LIMIT 150;


-- ###########################################################################
-- 6. THE DECISION FUNNEL — every distinct value, and where it ended up
--    Answers: how many titles are there, how many matched anything, how
--    many were rejected and for which of the two reasons.
-- ###########################################################################
WITH t AS (
  SELECT
      CASE
        WHEN is_assigned                                   THEN '1. assigned'
        ELSE                                                    '2. rejected - too far from every group'
      END                             AS outcome,
      frequency
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
)
SELECT
    'title'                                             AS axis,
    outcome,
    COUNT(*)                                            AS distinct_values,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4)          AS share_of_values,
    SUM(frequency)                                      AS records,
    ROUND(SUM(frequency) / SUM(SUM(frequency)) OVER (), 4) AS share_of_records
FROM t
GROUP BY outcome

UNION ALL

SELECT
    'discipline',
    CASE
      WHEN is_assigned THEN '1. assigned'
      ELSE                  '2. rejected - too far from every group'
    END,
    COUNT(*),
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4),
    SUM(frequency),
    ROUND(SUM(frequency) / SUM(SUM(frequency)) OVER (), 4)
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
GROUP BY 2
ORDER BY axis, outcome;


-- ###########################################################################
-- 7. [SUPERSEDED] The margin is no longer a gate, so nothing is rejected
--    for it any more. Kept only to show what the old threshold had been
--    costing - run it against a build from before the change.
-- 7. HOW MUCH WOULD A LOWER MARGIN RECOVER?
--    The margin threshold is currently 0.13. These were rejected only for
--    that reason - their similarity is fine. Shows what each candidate
--    threshold would bring back.
-- ###########################################################################
WITH rejected_on_margin AS (
  SELECT title, frequency, margin, title_group, runner_up
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
  WHERE NOT is_assigned AND similarity >= 0.65
)
SELECT
    candidate_threshold,
    COUNTIF(margin >= candidate_threshold)              AS titles_recovered,
    SUM(IF(margin >= candidate_threshold, frequency, 0)) AS records_recovered
FROM rejected_on_margin, UNNEST([0.02, 0.04, 0.06, 0.08, 0.10, 0.12]) AS candidate_threshold
GROUP BY candidate_threshold
ORDER BY candidate_threshold;


-- ###########################################################################
-- 8. [SUPERSEDED] This was the argument for dropping the margin gate.
--    It has been dropped. Same note as query 7.
-- 8. WHEN THE TOP TWO GROUPS LEAD TO THE SAME ROLE, THE MARGIN IS MOOT
--    "medical oncologist" is close to both practitioner and
--    trainee_clinical. Both of those support hcp, so whichever wins, the
--    person is an hcp. Rejecting it on margin loses them for nothing.
-- ###########################################################################
SELECT
    title_group,
    runner_up,
    CASE
      WHEN title_group IN ('practitioner','trainee_clinical')
       AND runner_up  IN ('practitioner','trainee_clinical')          THEN 'same role (hcp)'
      WHEN title_group IN ('researcher_early','researcher_established')
       AND runner_up  IN ('researcher_early','researcher_established') THEN 'same role (researcher)'
      ELSE                                                                 'different roles'
    END                                 AS consequence,
    COUNT(*)                            AS titles,
    SUM(frequency)                      AS records
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE NOT is_assigned AND similarity >= 0.65
GROUP BY title_group, runner_up, consequence
ORDER BY records DESC
LIMIT 40;


-- ###########################################################################
-- 9. AFTER THE CHANGE — did the rejection rate move, and where?
--    Compare against the previous build: 47,502 assigned titles carrying
--    57.5% of records, 261,498 rejected carrying 42.5%.
-- ###########################################################################
SELECT
    'title' AS axis, is_assigned,
    COUNT(*)                                            AS distinct_values,
    SUM(frequency)                                      AS records,
    ROUND(SUM(frequency) / SUM(SUM(frequency)) OVER (), 4) AS share_of_records
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
GROUP BY is_assigned
UNION ALL
SELECT
    'discipline', is_assigned, COUNT(*), SUM(frequency),
    ROUND(SUM(frequency) / SUM(SUM(frequency)) OVER (), 4)
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline`
GROUP BY is_assigned
ORDER BY axis, is_assigned DESC;


-- ###########################################################################
-- 10. DID faculty_head STOP COLLECTING COMPANY EXECUTIVES?
--     The first run had Director, CEO, President and Founder as the top
--     four, with Dean sixteenth on 33 people.
-- ###########################################################################
SELECT
    evidence_title,
    evidence_org,
    role_label,
    COUNT(*)                        AS people,
    ROUND(AVG(role_final_score), 2) AS avg_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_key = 'faculty_head'
GROUP BY 1,2,3
ORDER BY people DESC
LIMIT 60;
