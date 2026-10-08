-- ###########################################################################
-- 17. DIAGNOSTICS - the two questions the baseline could not answer, plus a
--     dry run of the changes made on 2026-10-08.
--
--     Queries 1 and 2 are about faculty_head. Queries 3 and 4 are about the
--     99,000 people Phase-1 found and we do not have. Query 5 sizes the new
--     HCP sub-roles BEFORE a rebuild, so the audience is known in advance.
--
--     WHEN TO RUN: all five after the rebuild. Nothing here needs to be
--     captured first.
--
--     Every input these queries depend on either survives the rebuild
--     untouched - role_score, org_type, the ORCID source, the Phase-1
--     table - or is already written down in docs/BASELINE_2026-10-08.md.
--     Query 2 spells both scoring scales out in full for that reason, so
--     it compares old against new on whichever build it is run against.
--
--     Queries 1 and 5 are strictly better afterwards: query 1 compares
--     against the top-20 titles recorded in the baseline, and query 5 is a
--     simulation that the rebuild replaces with the real audiences.
--
--     Replace TODO_phase1_table in queries 3 and 4 the same way as in
--     analyses/14.
-- ###########################################################################


-- ###########################################################################
-- 1. IS faculty_head STILL COLLECTING EXECUTIVES?
--
--    Group by the TITLE ONLY. This is the whole point of the query.
--    analyses/16 query 10 grouped by title AND organisation, which splits
--    corporate titles across hundreds of distinct company names while
--    concentrating academic ones under a handful of universities - so
--    executives vanish from a top-50 even when thousands are present. That
--    reading was wrong, and this query is what settles it.
--
--    Run this AFTER the rebuild. The "before" is already recorded, so
--    there is nothing to capture first:
--      Director 876, Founder 303, President 290, Executive Director 169,
--      Managing Director 137, CEO 78  ...  Dean 32
-- ###########################################################################
SELECT
    lower(evidence_title)                   AS title,
    COUNT(*)                                AS people,
    COUNTIF(role_label = 'CONFIRMED')       AS confirmed,
    ROUND(AVG(role_final_score), 3)         AS avg_score,
    COUNT(DISTINCT evidence_org)            AS distinct_orgs
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_key = 'faculty_head'
GROUP BY title
ORDER BY people DESC
LIMIT 40;


-- ###########################################################################
-- 2. WHAT THE NEW faculty_head RULES COST
--
--    REWRITTEN 2026-10-08 after the first run returned confirmed_new = 0
--    for every single title, with avg_old exactly 0.680 and avg_new
--    exactly 0.500 across 21 titles of wildly different sizes. Identical
--    averages like that are not a result, they are a symptom: every row
--    the query could see had org_type = 'UNKNOWN' and role_score = 1.0.
--
--      0.60 * 1.00 + 0.40 * 0.20 = 0.68
--      0.50 * 1.00 + 0.50 * 0.00 = 0.50
--
--    And it contradicted query 1, which has dean averaging 0.907 - only
--    reachable with a resolved academic organisation. Two readings of the
--    same data disagreeing means the reconstruction was wrong, not the
--    stored value, so 2a asks what org_type actually holds before 2b
--    trusts it, and 2b now reads the stored org_score for the old scale
--    instead of rebuilding it from org_type.
--
--    Run 2a first. If almost everything is UNKNOWN then organisation
--    resolution is the headline problem in this role and no amount of
--    weight tuning will fix it.
-- ###########################################################################

-- 2a. WHAT DOES org_type ACTUALLY HOLD FOR THIS ROLE?
SELECT
    COALESCE(org_type, '(null)')                        AS org_type,
    COUNT(*)                                            AS records,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4)          AS share,
    ROUND(AVG(org_score), 3)                            AS avg_org_score,
    ROUND(AVG(role_score), 3)                           AS avg_role_score,
    COUNT(DISTINCT org_resolution_method)               AS methods
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
WHERE role_key = 'faculty_head'
GROUP BY org_type
ORDER BY records DESC;


-- 2b. PER TITLE: what the change keeps, loses, and drops
--     Old score uses the org_score STORED on the row, so this must run
--     BEFORE the rebuild overwrites it. New score is the only thing
--     reconstructed, and only from org_type.
WITH both AS (
  SELECT
      LOWER(role_title_raw)                             AS title,
      0.60 * role_score + 0.40 * org_score              AS score_old,
      -- org_type is LOWERCASE for everything ROR resolves - 'education',
      -- 'healthcare', 'company' - and only 'UNKNOWN' is upper case. The
      -- capitalised seed spellings matched nothing but UNKNOWN, which is
      -- what made the first run of this query unreadable.
      0.60 * role_score + 0.40 * CASE LOWER(org_type)
        WHEN 'education'  THEN 1.00
        WHEN 'facility'   THEN 0.60
        WHEN 'healthcare' THEN 0.50
        WHEN 'nonprofit'  THEN 0.40
        WHEN 'government' THEN 0.30
        WHEN 'archive'    THEN 0.20
        ELSE 0.00   -- company, other, funder, UNKNOWN and NULL
      END                                               AS score_new
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
  WHERE role_key = 'faculty_head'
)
SELECT
    title,
    COUNT(*)                                                AS people,
    COUNTIF(score_old >= 0.65)                              AS confirmed_old,
    COUNTIF(score_new >= 0.65)                              AS confirmed_new,
    COUNTIF(score_old >= 0.65) - COUNTIF(score_new >= 0.65) AS lost,
    COUNTIF(score_new <  0.40)                              AS dropped_entirely,
    ROUND(AVG(score_old), 3)                                AS avg_old,
    ROUND(AVG(score_new), 3)                                AS avg_new
FROM both
GROUP BY title
HAVING people >= 20
ORDER BY confirmed_old DESC
LIMIT 60;


-- ###########################################################################
-- 3. THE 99,000 - WHERE DO THEY ACTUALLY GO MISSING?
--
--    CHECK THE DENOMINATOR FIRST. The first run of this totalled
--    1,831,819 people, which is the whole ORCID population rather than
--    the 99,000 it was meant to split - so the phase1_missing CTE was not
--    filtering. Run query 3a and do not read 3b until it returns 99,000.
--
--    The baseline said these people fail to clear a threshold. The
--    arithmetic says otherwise: hcp_broad weights the department at 0.40,
--    so an empty title still leaves a ceiling of 0.40 + 0.25 * org, and
--    PROBABLE starts at 0.30. They should all be in the output at some
--    label. They are in it at none.
--
--    So the loss happens upstream, and this query says where. Each stage is
--    a different kind of problem with a different kind of fix:
--
--      A  not in the ORCID source at all        -> Phase-1 read another source
--      B  in the source but no SNID             -> our population filter
--      C  has a SNID but no PUBLIC employment   -> the visibility filter
--      D  has PUBLIC employments, no clinical   -> dictionary or anchors
--      E  clinical signal present, still absent -> genuinely a scoring bug
--
--    Only E is a scoring problem. The hypothesis under test is C.
-- ###########################################################################
-- 3a. Does phase1_missing actually hold 99,000 people?
SELECT
    COUNT(*)                                        AS phase1_rows,
    COUNT(DISTINCT p.snid)                          AS phase1_people,
    COUNTIF(n.snid IS NULL)                         AS missing_rows,
    COUNT(DISTINCT IF(n.snid IS NULL, p.snid, NULL)) AS missing_people
FROM `researcher-360-prod-e7fd74be.researcher_profiles.TODO_phase1_table` p
LEFT JOIN (
    SELECT DISTINCT snid
    FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    WHERE role_key IN ('hcp', 'hcp_broad')
) n USING (snid)
WHERE p.phase1_label IN ('CONFIRMED_HCP_CANDIDATE', 'PROBABLE_HCP');


-- 3b. The five stages
WITH phase1_missing AS (
  SELECT DISTINCT p.snid
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.TODO_phase1_table` p
  LEFT JOIN (
      SELECT DISTINCT snid
      FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
      -- tolerate either name: 'hcp' before the 2026-10-08 rebuild,
      -- 'hcp_broad' after. Pinning it to one makes every person look
      -- missing when run against the other build.
      WHERE role_key IN ('hcp', 'hcp_broad')
  ) n USING (snid)
  WHERE p.phase1_label IN ('CONFIRMED_HCP_CANDIDATE', 'PROBABLE_HCP')
    AND n.snid IS NULL
),
-- the raw ORCID source, BEFORE our two filters
source_all AS (
  SELECT
      snid,
      ARRAY_LENGTH(employments)                                   AS n_employments,
      (SELECT COUNT(*) FROM UNNEST(employments) e
        WHERE UPPER(e.visibility) = 'PUBLIC')                     AS n_public
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`
  WHERE snid IS NOT NULL
),
-- anyone we scored at all, under any role
scored_any AS (
  SELECT DISTINCT snid
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
),
-- anyone whose department resolved to a clinical discipline
has_clinical AS (
  SELECT DISTINCT r.snid
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
  JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline` d
    ON d.department = r.department
  WHERE d.discipline = 'health_clinical'
    AND d.is_assigned
)
SELECT
    CASE
      WHEN s.snid IS NULL              THEN 'A. not in the ORCID source with a SNID'
      WHEN s.n_employments = 0         THEN 'B. in the source, no employment records at all'
      WHEN s.n_public = 0              THEN 'C. employments exist but NONE are PUBLIC'
      WHEN c.snid IS NULL              THEN 'D. public employments, no clinical department'
      WHEN a.snid IS NULL              THEN 'E1. clinical department, never entered scoring'
      ELSE                                  'E2. entered scoring, produced no hcp_broad row'
    END                                                   AS stage,
    COUNT(*)                                              AS people,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4)            AS share
FROM phase1_missing m
LEFT JOIN source_all   s USING (snid)
LEFT JOIN has_clinical c USING (snid)
LEFT JOIN scored_any   a USING (snid)
GROUP BY stage
ORDER BY stage;


-- ###########################################################################
-- 4. HOW MUCH DOES THE VISIBILITY FILTER COST, ACROSS THE WHOLE SOURCE?
--
--    Independent of Phase-1. If stage C above is large, this is the size of
--    the decision behind it - and it is a data-access decision, not a
--    modelling one. Marketing consent is a separate question from ORCID
--    visibility, so whether a LIMITED employment record may be used is a
--    question for whoever owns that call.
-- ###########################################################################
SELECT
    CASE
      WHEN n_public > 0                       THEN '1. has at least one PUBLIC employment'
      WHEN n_employments > 0                  THEN '2. has employments, none PUBLIC  <- lost by the filter'
      ELSE                                         '3. no employment records at all'
    END                                                   AS visibility_bucket,
    COUNT(*)                                              AS people,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4)            AS share,
    SUM(n_employments)                                    AS employment_records,
    SUM(n_employments) - SUM(n_public)                     AS records_discarded
FROM (
  SELECT
      snid,
      ARRAY_LENGTH(employments) AS n_employments,
      (SELECT COUNT(*) FROM UNNEST(employments) e
        WHERE UPPER(e.visibility) = 'PUBLIC') AS n_public
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`
  WHERE snid IS NOT NULL
)
GROUP BY visibility_bucket
ORDER BY visibility_bucket;


-- ###########################################################################
-- 5. SIZING THE NEW HCP SUB-ROLES BEFORE THE REBUILD
--
--    REWRITTEN 2026-10-08. The first version reported hcp_practitioner as
--    51,018 people with 755,394 confirmed - more confirmed than people,
--    which is impossible. Two bugs compounding:
--
--      - the join to stg_role_records on role_title_raw = evidence_title
--        matches every record of a person that shares that title, so one
--        person fanned out into many rows;
--      - 'people' used COUNT(DISTINCT snid) while confirmed, probable and
--        confirmed_rate used COUNTIF, which counts those fanned-out rows.
--
--    Fixed by collapsing to one row per person per sub-role first, keeping
--    their best score, and counting people everywhere after that.
--
--    Weights and thresholds as configured:
--      hcp_practitioner   0.45 / 0.15 / 0.40   confirm 0.70
--      hcp_researcher     0.40 / 0.20 / 0.40   confirm 0.70
--      hcp_administrator  0.35 / 0.25 / 0.40   confirm 0.70
-- ###########################################################################
WITH candidates AS (
  SELECT
      e.snid,
      e.title_group,
      e.org_score,
      e.dept_score,
      -- e.role_score is masked to 0 for any group outside hcp_broad's own
      -- two, so the real score has to come from the dictionary. Without
      -- this join hcp_researcher and hcp_administrator would size to zero.
      t.group_score                           AS title_score
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` e
  JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    ON  r.snid = e.snid
    AND r.role_title_raw = e.evidence_title
  JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
    ON  t.title_key = r.title_key
    AND t.is_assigned
  WHERE e.role_key IN ('hcp', 'hcp_broad')
    AND e.discipline = 'health_clinical'     -- the AND arm of match:all
    AND e.dept_score > 0
    AND e.title_group IN ('practitioner', 'trainee_clinical', 'researcher_early',
                          'researcher_established', 'leadership')
),
scored AS (
  SELECT
      CASE
        WHEN title_group IN ('practitioner', 'trainee_clinical')
          THEN 'hcp_practitioner'
        WHEN title_group IN ('researcher_early', 'researcher_established')
          THEN 'hcp_researcher'
        ELSE 'hcp_administrator'
      END                                     AS new_role,
      snid,
      CASE
        WHEN title_group IN ('practitioner', 'trainee_clinical')
          THEN 0.45 * title_score + 0.15 * org_score + 0.40 * dept_score
        WHEN title_group IN ('researcher_early', 'researcher_established')
          THEN 0.40 * title_score + 0.20 * org_score + 0.40 * dept_score
        ELSE 0.35 * title_score + 0.25 * org_score + 0.40 * dept_score
      END                                     AS score_new
  FROM candidates
),
-- one row per person per sub-role, carrying their best score, exactly as
-- fct_researcher_roles would. Everything below counts people.
per_person AS (
  SELECT new_role, snid, MAX(score_new) AS score_new
  FROM scored
  GROUP BY new_role, snid
)
SELECT
    new_role,
    COUNT(*)                                                AS people,
    COUNTIF(score_new >= 0.70)                              AS confirmed,
    COUNTIF(score_new >= 0.50 AND score_new < 0.70)         AS probable,
    COUNTIF(score_new < 0.50)                               AS below_both,
    ROUND(AVG(score_new), 3)                                AS avg_score,
    ROUND(COUNTIF(score_new >= 0.70) / COUNT(*), 3)         AS confirmed_rate
FROM per_person
GROUP BY new_role
ORDER BY people DESC;


-- ###########################################################################
-- 6. IS THE SNID FILTER DOING WHAT THE RAW MODEL CLAIMS?
--
--    raw_orcid_researchers says "the table holds 24.8M ORCID profiles but
--    only a fraction carry a SNID", and the baseline records the result as
--    1.76M people. Query 4 ran WHERE snid IS NOT NULL against the same
--    source and counted 25,132,641 - so that filter removes almost
--    nothing, and the 1.76M comes from somewhere else or is wrong.
--
--    The likely cause is an empty string: 'snid IS NOT NULL' keeps '',
--    which then joins to nothing in the CDP. If empty_snid below is large,
--    the raw filter should be "snid is not null and snid != ''" and every
--    population figure in the baseline needs restating.
-- ###########################################################################
SELECT
    COUNT(*)                                            AS source_rows,
    COUNTIF(snid IS NULL)                               AS null_snid,
    COUNTIF(snid IS NOT NULL AND TRIM(snid) = '')       AS empty_snid,
    COUNTIF(snid IS NOT NULL AND TRIM(snid) != '')      AS usable_snid,
    COUNT(DISTINCT IF(TRIM(snid) != '', snid, NULL))    AS distinct_usable_snid
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`;
