/*
    ============================================================================
    18. TWO DECISIONS THAT NEED EYES, NOT ARITHMETIC
    ============================================================================
    A. lecturer and researcher confirm 99.7% of what they find. Is that the
       threshold being useless, or the role genuinely being that clean?
       Queries 1a-1c. Look at the evidence and decide.

    B. Which dictionary values are decided by a coin flip, and does the flip
       change which role a person lands in? Queries 2a-2c. This is the real
       review queue, and what role_title_overrides.csv is for.

    Plain SQL throughout - paste into BigQuery, no dbt compile needed.
    ============================================================================
*/


-- ###########################################################################
-- 1a. WHERE IS THE MASS? Score distribution for the two single-axis roles.
--
--     CORRECTED 2026-10-09: these three read fct_researcher_roles, not
--     int_employment_scored. role_final_score is computed in fct and does
--     not exist in int, so the first version of 1a-1c could not run as
--     written against the table they named.
--
--     Both score 0.75 * title + 0.25 * organisation, confirming at 0.60. If
--     the mass sits far above 0.60 then the threshold is not discriminating -
--     it is just passing everything, and "CONFIRMED" tells marketing less
--     than they think.
-- ###########################################################################
SELECT
    role_key,
    CASE
      WHEN role_final_score < 0.60 THEN '1. below 0.60 - PROBABLE'
      WHEN role_final_score < 0.65 THEN '2. 0.60 - 0.65  <- the bottom of CONFIRMED'
      WHEN role_final_score < 0.75 THEN '3. 0.65 - 0.75'
      WHEN role_final_score < 0.85 THEN '4. 0.75 - 0.85'
      WHEN role_final_score < 0.95 THEN '5. 0.85 - 0.95'
      ELSE                              '6. 0.95 and above'
    END                                             AS band,
    COUNT(*)                                        AS people,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY role_key), 4) AS share,
    ROUND(AVG(role_score), 3)                       AS avg_title_score,
    ROUND(AVG(org_score), 3)                        AS avg_org_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_key IN ('lecturer', 'researcher')
GROUP BY role_key, band
ORDER BY role_key, band;


-- ###########################################################################
-- 1b. THE BOTTOM OF CONFIRMED - the people the threshold only just let in.
--
--     THIS IS THE DECIDING QUERY. If these look like real lecturers and
--     researchers, the threshold is fine where it is and the 0.70 group_score
--     floor is doing no harm. If they look wrong, the floor is too generous
--     and either it comes down or the threshold goes up.
--
--     evidence_* are the raw ORCID fields, untouched.
-- ###########################################################################
SELECT
    role_key,
    ROUND(role_final_score, 3)      AS score,
    ROUND(role_score, 3)            AS title_score,
    ROUND(org_score, 3)             AS org_score,
    title_group,
    evidence_title                  AS orcid_role,
    evidence_org                    AS orcid_organisation,
    evidence_dept                   AS orcid_department,
    org_type,
    is_current
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_key IN ('lecturer', 'researcher')
  AND role_final_score BETWEEN 0.60 AND 0.66   -- just inside CONFIRMED
ORDER BY role_key, role_final_score
LIMIT 120;


-- ###########################################################################
-- 1c. AND THE ONES JUST OUTSIDE IT, for comparison.
--     If 1b and 1c look like the same kind of person, the threshold is
--     drawing a line through the middle of one population, which means it is
--     not measuring anything.
-- ###########################################################################
SELECT
    role_key,
    ROUND(role_final_score, 3)      AS score,
    ROUND(role_score, 3)            AS title_score,
    ROUND(org_score, 3)             AS org_score,
    title_group,
    evidence_title                  AS orcid_role,
    evidence_org                    AS orcid_organisation,
    evidence_dept                   AS orcid_department,
    org_type
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_key IN ('lecturer', 'researcher')
  AND role_final_score < 0.60
ORDER BY role_key, role_final_score DESC
LIMIT 80;


-- ###########################################################################
-- 2a. THE REAL REVIEW QUEUE - coin flips with consequences.
--
--     A tiny margin only matters if the two candidate groups lead to
--     DIFFERENT roles. "researcher_early vs researcher_established" is a
--     coin flip with no consequence; both are the researcher role. "fellow"
--     choosing between trainee_clinical and researcher_early decides whether
--     48,777 records feed HCP or Researcher, and it won by 0.001.
--
--     The group-to-role map below is the registry, written out so this runs
--     as plain SQL. Keep it in step with vars.roles in dbt_project.yml.
-- ###########################################################################
WITH group_roles AS (
  SELECT 'practitioner'           AS grp, 'hcp_broad + hcp_practitioner' AS roles UNION ALL
  SELECT 'trainee_clinical',           'hcp_broad + hcp_practitioner'    UNION ALL
  SELECT 'researcher_early',           'researcher + hcp_researcher'     UNION ALL
  SELECT 'researcher_established',     'researcher + hcp_researcher'     UNION ALL
  SELECT 'leadership',                 'faculty_head + hcp_administrator' UNION ALL
  SELECT 'teaching_academic',          'lecturer'                        UNION ALL
  SELECT 'pharmacist',                 'pharmacist'                      UNION ALL
  SELECT 'student',                    '(no role)'                       UNION ALL
  SELECT 'support_technical',          '(no role)'
)
SELECT
    t.title,
    t.frequency,
    ROUND(t.margin, 3)                      AS margin,
    t.title_group                           AS won,
    t.runner_up                             AS nearly_won,
    w.roles                                 AS roles_if_won,
    r.roles                                 AS roles_if_runner_up,
    IF(w.roles = r.roles, 'no consequence', 'CHANGES THE ROLE') AS consequence
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
LEFT JOIN group_roles w ON w.grp = t.title_group
LEFT JOIN group_roles r ON r.grp = t.runner_up
WHERE t.is_assigned
  AND t.margin < 0.02        -- the genuinely ambiguous tail, measured
  AND t.frequency >= 5000    -- and big enough to be worth a human decision
ORDER BY t.frequency DESC
LIMIT 60;


-- ###########################################################################
-- 2b. DO THE SUSPECTS ACTUALLY REACH ANYONE?
--
--     frequency counts RECORDS, and scoring keeps one record per person per
--     role - so a title with 96,676 records may represent very few people in
--     the final output. This is the query that says whether a value is worth
--     an override at all.
--
--     'dr' is the one I overstated. It matched practitioner at 0.741, but
--     hcp_practitioner needs a clinical department as well, so "Dr" in
--     Cardiology is probably a physician and "Dr" in Physics never enters
--     the role. Check the numbers before fixing anything.
-- ###########################################################################
SELECT
    LOWER(TRIM(evidence_title))             AS orcid_role,
    role_key,
    role_label,
    COUNT(DISTINCT snid)                    AS people,
    ROUND(AVG(role_final_score), 3)         AS avg_score,
    COUNT(DISTINCT evidence_dept)           AS distinct_departments
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE LOWER(TRIM(evidence_title)) IN (
        'dr', 'dr.', 'fellow', 'member', 'assistant', 'md',
        'research assistant professor', 'medical student',
        'senior research associate', 'research engineer', 'research professor'
      )
GROUP BY orcid_role, role_key, role_label
ORDER BY people DESC
LIMIT 80;


-- ###########################################################################
-- 2c. WHAT DEPARTMENTS SIT BEHIND THE AMBIGUOUS TITLES?
--
--     Decides whether a value is a false positive or merely ambiguous. If
--     'dr' appears overwhelmingly with clinical departments, practitioner is
--     the right call and no override is needed. If it is spread evenly
--     across physics, law and medicine, it carries no occupational meaning
--     and should be rejected rather than reassigned.
-- ###########################################################################
SELECT
    LOWER(TRIM(e.evidence_title))           AS orcid_role,
    COALESCE(e.discipline, '(no field)')    AS field,
    COUNT(*)                                AS records,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY LOWER(TRIM(e.evidence_title))), 3) AS share_of_that_title
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` e
WHERE LOWER(TRIM(e.evidence_title)) IN ('dr', 'dr.', 'fellow', 'member', 'assistant', 'md')
GROUP BY orcid_role, field
HAVING records >= 50
ORDER BY orcid_role, records DESC
LIMIT 100;


-- ###########################################################################
-- 1d. SETTLE THE SCORE RANGE. Two of my readings disagree and one is wrong.
--
--     analyses/15 query 2 reported lecturer PROBABLE at 684 people with a
--     minimum of 0.575, and researcher PROBABLE at 1,330 from 0.575. But 1a
--     returned NO rows below 0.65 for either role, and 1b and 1c came back
--     empty. Both cannot be true of the same table.
--
--     This prints the range directly, with the null count, so whichever
--     reading is wrong stops being a guess.
-- ###########################################################################
SELECT
    role_key,
    role_label,
    COUNT(*)                                        AS people,
    ROUND(MIN(role_final_score), 4)                 AS min_score,
    ROUND(MAX(role_final_score), 4)                 AS max_score,
    COUNTIF(role_final_score IS NULL)               AS null_scores,
    COUNTIF(role_final_score < 0.60)                AS below_060,
    COUNTIF(role_final_score < 0.65)                AS below_065
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
GROUP BY role_key, role_label
ORDER BY role_key, role_label;


-- ###########################################################################
-- 2d. ROWS WHOSE LABEL ITS SCORE CANNOT JUSTIFY.
--
--     Query 2b returned 'medical student' as hcp_broad CONFIRMED with an
--     average score of 0.0, and the same for 'assistant' and 'member'. That
--     is impossible: fct keeps only CONFIRMED and PROBABLE, and hcp_broad
--     confirms at 0.60.
--
--     Two candidate causes, and derived_from_role separates them. If these
--     rows carry a child role name then the parent roll-up handed them a
--     label computed against the CHILD's thresholds - a known bug, since
--     parent_rollup_union copies role_label verbatim and the children
--     confirm at 0.70 while hcp_broad confirms at 0.60. If
--     derived_from_role is null the score itself is wrong.
-- ###########################################################################
SELECT
    role_key,
    role_label,
    ROUND(role_final_score, 4)      AS score,
    ROUND(role_score, 3)            AS title_score,
    ROUND(org_score, 3)             AS org_score,
    ROUND(dept_score, 3)            AS dept_score,
    title_group,
    discipline,
    derived_from_role,
    evidence_title                  AS orcid_role,
    evidence_dept                   AS orcid_department,
    COUNT(*)                        AS rows_like_this
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_final_score IS NULL
   OR role_final_score = 0
   OR (role_label = 'CONFIRMED' AND role_final_score < 0.60)
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
ORDER BY rows_like_this DESC
LIMIT 60;
