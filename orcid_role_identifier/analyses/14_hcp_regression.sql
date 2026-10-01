/*
    ============================================================================
    HCP REGRESSION TEST — THE GATE
    ============================================================================
    The existing Phase-1 pipeline is this project's benchmark. If the new
    two-axis design cannot reproduce its labels on the same population,
    nothing gets built on top of it.

    Run this AFTER `dbt build` has produced fct_researcher_roles.

    !! Fill in the Phase-1 table name below. It is the output of the
       existing pipeline - hcp_identified_phase1 or hcp_unified.

    Phase-1 for reference:
        candidates   204,130
        final list    94,139
        in CDP        93,177  (99.0%)
        marketable    21,040  (22.4%)

    WHAT A GOOD RESULT LOOKS LIKE
    Not 100% agreement. The new pipeline is expected to FIND people
    Phase-1 missed - German, Turkish and French job titles that the
    English regex could not match. Those appear as "new only" and are an
    improvement, not an error.
    What would be a real failure is a large "Phase-1 only" group: people
    the old pipeline caught and the new one lost.
    ============================================================================
*/

-- ---------------------------------------------------------------------------
-- 1. HEADLINE AGREEMENT
-- ---------------------------------------------------------------------------
WITH phase1 AS (
  SELECT DISTINCT snid
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.TODO_phase1_table`
  WHERE phase1_label IN ('CONFIRMED_HCP_CANDIDATE', 'PROBABLE_HCP')
),
new_pipeline AS (
  SELECT DISTINCT snid
  FROM `dat-analytics-eng-ec869189.orcid_role_agent_scoring.fct_researcher_roles`
  WHERE role_key = 'hcp'
    AND role_label IN ('CONFIRMED', 'PROBABLE')
)
SELECT
    CASE
      WHEN p.snid IS NOT NULL AND n.snid IS NOT NULL THEN '1. both agree'
      WHEN p.snid IS NOT NULL                        THEN '2. Phase-1 only  <- the risk'
      ELSE                                                '3. new only  <- expected gain'
    END                                             AS outcome,
    COUNT(*)                                        AS people,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4)      AS share
FROM phase1 p
FULL OUTER JOIN new_pipeline n USING (snid)
GROUP BY outcome
ORDER BY outcome;


-- ---------------------------------------------------------------------------
-- 2. WHAT THE NEW PIPELINE LOST
--    Every row here is a regression. Read the titles: if they are English
--    clinical titles, the title anchors have a gap.
-- ---------------------------------------------------------------------------
WITH phase1 AS (
  SELECT snid, orcid_role, orcid_organisation, orcid_department, hcp_phase1_score
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.TODO_phase1_table`
  WHERE phase1_label IN ('CONFIRMED_HCP_CANDIDATE', 'PROBABLE_HCP')
),
new_pipeline AS (
  SELECT DISTINCT snid
  FROM `dat-analytics-eng-ec869189.orcid_role_agent_scoring.fct_researcher_roles`
  WHERE role_key = 'hcp'
)
SELECT
    p.orcid_role                AS title,
    p.orcid_department          AS department,
    COUNT(*)                    AS people,
    ROUND(AVG(p.hcp_phase1_score), 3) AS avg_phase1_score
FROM phase1 p
LEFT JOIN new_pipeline n USING (snid)
WHERE n.snid IS NULL
GROUP BY title, department
ORDER BY people DESC
LIMIT 60;


-- ---------------------------------------------------------------------------
-- 3. WHAT THE NEW PIPELINE GAINED
--    Expect non-English titles here. If instead they are obviously
--    non-clinical, the anchors are too loose.
-- ---------------------------------------------------------------------------
WITH phase1 AS (
  SELECT DISTINCT snid
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.TODO_phase1_table`
  WHERE phase1_label IN ('CONFIRMED_HCP_CANDIDATE', 'PROBABLE_HCP')
),
new_pipeline AS (
  SELECT snid, evidence_title, evidence_dept, title_group, discipline, role_final_score
  FROM `dat-analytics-eng-ec869189.orcid_role_agent_scoring.fct_researcher_roles`
  WHERE role_key = 'hcp'
    AND role_label IN ('CONFIRMED', 'PROBABLE')
)
SELECT
    n.evidence_title            AS title,
    n.evidence_dept             AS department,
    n.title_group,
    n.discipline,
    COUNT(*)                    AS people,
    ROUND(AVG(n.role_final_score), 3) AS avg_new_score
FROM new_pipeline n
LEFT JOIN phase1 p USING (snid)
WHERE p.snid IS NULL
GROUP BY 1,2,3,4
ORDER BY people DESC
LIMIT 60;


-- ---------------------------------------------------------------------------
-- 4. WHICH ROUTE FOUND THEM
--    Confirms that reading both axes was worth it. Anyone found by the
--    title alone would have been lost in a discipline-only design, and
--    vice versa.
-- ---------------------------------------------------------------------------
SELECT
    CASE
      WHEN role_score > 0 AND dept_score > 0 THEN '1. both axes agree'
      WHEN role_score > 0                    THEN '2. title only'
      WHEN dept_score > 0                    THEN '3. department only'
      ELSE                                        '4. organisation only'
    END                                     AS route,
    COUNT(*)                                AS people,
    ROUND(AVG(role_final_score), 3)         AS avg_score,
    COUNTIF(role_label = 'CONFIRMED')       AS confirmed
FROM `dat-analytics-eng-ec869189.orcid_role_agent_scoring.fct_researcher_roles`
WHERE role_key = 'hcp'
GROUP BY route
ORDER BY route;


-- ---------------------------------------------------------------------------
-- 5. ALL FIVE ROLES, WITH REACH
--    The deliverable, once the gate above has been passed.
-- ---------------------------------------------------------------------------
SELECT
    role_key,
    COUNT(DISTINCT snid)                                        AS people,
    COUNTIF(role_label = 'CONFIRMED')                           AS confirmed,
    COUNT(DISTINCT IF(c.snid IS NOT NULL, f.snid, NULL))        AS in_cdp,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in OR c.advertising_opt_in,
                      f.snid, NULL))                            AS reachable
FROM `dat-analytics-eng-ec869189.orcid_role_agent_scoring.fct_researcher_roles` f
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON f.snid = c.snid
GROUP BY role_key
ORDER BY people DESC;
