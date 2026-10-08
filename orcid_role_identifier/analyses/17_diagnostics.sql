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
-- 2. WHAT THE NEW faculty_head RULES COST, PER TITLE
--
--    Runs on either build. role_score and org_type both survive the
--    rebuild untouched - the anchors did not change and neither did ROR -
--    so both scoring scales can be written out in full and compared
--    side by side whenever this is run.
--
--      old:  0.60 * role + 0.40 * org,  confirm 0.65,  unresolved = 0.20
--      new:  0.50 * role + 0.50 * org,  confirm 0.75,  unresolved = 0.00
--
--    The point is not the totals, which the baseline already records. It
--    is WHICH titles the change drops. A precision-first change fails by
--    over-tightening, and losing deans would be as bad as keeping
--    founders - so read the 'lost' column against the title, not the sum.
-- ###########################################################################
WITH scored AS (
  SELECT
      lower(role_title_raw)       AS title,
      org_type,
      role_score,
      CASE org_type                       -- the scale before 2026-10-08
        WHEN 'Education'  THEN 1.00
        WHEN 'Facility'   THEN 0.60
        WHEN 'Healthcare' THEN 0.50
        WHEN 'Nonprofit'  THEN 0.40
        WHEN 'Government' THEN 0.30
        WHEN 'Archive'    THEN 0.20
        WHEN 'Other'      THEN 0.10
        WHEN 'Funder'     THEN 0.10
        WHEN 'UNKNOWN'    THEN 0.20
        WHEN 'Company'    THEN 0.00
      END                         AS org_score_old,
      CASE org_type                       -- and after: anything we cannot
        WHEN 'Education'  THEN 1.00       -- place as academic scores zero,
        WHEN 'Facility'   THEN 0.60       -- so it cannot carry a title
        WHEN 'Healthcare' THEN 0.50       -- over the line
        WHEN 'Nonprofit'  THEN 0.40
        WHEN 'Government' THEN 0.30
        WHEN 'Archive'    THEN 0.20
        ELSE 0.00   -- Company, Other, Funder, UNKNOWN
      END                         AS org_score_new
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
  WHERE role_key = 'faculty_head'
),
both AS (
  SELECT
      title,
      org_type,
      0.60 * role_score + 0.40 * org_score_old AS score_old,
      0.50 * role_score + 0.50 * org_score_new AS score_new
  FROM scored
)
SELECT
    title,
    COUNT(*)                                                AS people,
    COUNTIF(score_old >= 0.65)                              AS confirmed_old,
    COUNTIF(score_new >= 0.75)                              AS confirmed_new,
    COUNTIF(score_old >= 0.65) - COUNTIF(score_new >= 0.75) AS lost,
    COUNTIF(score_new <  0.50)                              AS dropped_entirely,
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
--    The three new roles declare "match: all" - a matching title AND a
--    clinical department. Every record that could satisfy them is already
--    present in the hcp_broad rows, because hcp_broad admits a record on
--    either axis. So the audiences can be counted now.
--
--    Weights and thresholds as configured:
--      hcp_practitioner   0.45 / 0.15 / 0.40   confirm 0.70
--      hcp_researcher     0.40 / 0.20 / 0.40   confirm 0.70
--      hcp_administrator  0.35 / 0.25 / 0.40   confirm 0.70
--
--    Expect these to be much smaller than hcp_broad's 254,400 and much
--    cleaner. That is the trade being made deliberately.
-- ###########################################################################
WITH candidates AS (
  SELECT
      e.snid,
      e.title_group,
      e.org_score,
      e.dept_score,
      -- e.role_score is masked to 0 for any group outside hcp_broad's own
      -- two, so the real score has to come from the dictionary. Without
      -- this join hcp_researcher and hcp_administrator would both size to
      -- zero.
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
),
simulated AS (
  SELECT
      CASE
        WHEN title_group IN ('practitioner', 'trainee_clinical')
          THEN 'hcp_practitioner'
        WHEN title_group IN ('researcher_early', 'researcher_established')
          THEN 'hcp_researcher'
        WHEN title_group = 'leadership'
          THEN 'hcp_administrator'
      END                                     AS new_role,
      snid,
      CASE
        WHEN title_group IN ('practitioner', 'trainee_clinical')
          THEN 0.45 * title_score + 0.15 * org_score + 0.40 * dept_score
        WHEN title_group IN ('researcher_early', 'researcher_established')
          THEN 0.40 * title_score + 0.20 * org_score + 0.40 * dept_score
        WHEN title_group = 'leadership'
          THEN 0.35 * title_score + 0.25 * org_score + 0.40 * dept_score
      END                                     AS score_new
  FROM candidates
  WHERE title_group IN ('practitioner', 'trainee_clinical', 'researcher_early',
                        'researcher_established', 'leadership')
)
SELECT
    new_role,
    COUNT(DISTINCT snid)                                    AS people,
    COUNTIF(score_new >= 0.70)                              AS confirmed,
    COUNTIF(score_new >= 0.50 AND score_new < 0.70)         AS probable,
    COUNTIF(score_new < 0.50)                               AS below_both,
    ROUND(AVG(score_new), 3)                                AS avg_score,
    ROUND(COUNTIF(score_new >= 0.70) / COUNT(*), 3)         AS confirmed_rate
FROM simulated
GROUP BY new_role
ORDER BY people DESC;
