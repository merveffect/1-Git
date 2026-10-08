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


-- 2b. [RETIRED 2026-10-08 - read query 1 instead]
--
--     This compares the stored org_score against a CASE rebuilt from
--     org_type. That CASE cannot see the organisation-name fallback, and
--     the fallback is not a detail - for an unresolved organisation the
--     real pipeline computes
--
--       greatest(seed score for UNKNOWN,
--                best matching row in org_name_patterns)
--
--     and faculty_head's first pattern awards 1.00 to any name containing
--     universit / college / academy / faculty / institut. So a dean at a
--     university ROR cannot place is still confirmed on the name alone,
--     which is the point of having the fallback.
--
--     That means 2b's 'lost' column is not the cost of the configured
--     change. It is the cost of ALSO deleting the name-pattern rescue,
--     which nobody proposed. Query 1 reads the real table and is the
--     honest answer; 9c confirms UNKNOWN now averages 0.118, which is the
--     pattern firing on about 12% of unresolved rows and zero on the rest.
--
-- 2b. PER TITLE: what the change keeps, loses, and drops
--     Old score uses the org_score STORED on the row, so this must run
--     BEFORE the rebuild overwrites it. New score is the only thing
--     reconstructed, and only from org_type.
WITH both AS (
  SELECT
      LOWER(evidence_title)                             AS title,
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
-- The raw ORCID source, BEFORE our two filters.
--
-- AGGREGATED BY SNID, which is not cosmetic. The source holds 25,132,641
-- rows against 1,781,624 distinct snids (query 6), so joining to it
-- un-aggregated multiplies every person by about 16 - which is exactly
-- what made the first two runs of this query total 1.8M people instead
-- of the 118,664 it is meant to split.
source_all AS (
  SELECT
      snid,
      SUM(ARRAY_LENGTH(employments))                              AS n_employments,
      SUM((SELECT COUNT(*) FROM UNNEST(employments) e
            WHERE UPPER(e.visibility) = 'PUBLIC'))                AS n_public
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`
  WHERE snid IS NOT NULL
  GROUP BY snid
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
      -- note: D only tests the DEPARTMENT. But anyone here is also absent
      -- from hcp_broad, which admits a clinical TITLE on its own, so D
      -- means neither axis carried a clinical signal. Query 8 opens it up.
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


-- ###########################################################################
-- 7. WHY DOES THE SOURCE HOLD 25.1M ROWS FOR 1.78M PEOPLE?
--
--    Query 6 found 25,132,641 rows, no NULL and no empty snid, and only
--    1,781,624 distinct snids - about 14 rows per snid. "snid is not null"
--    in raw_orcid_researchers therefore filters nothing, and the 1.76M in
--    the baseline is a distinct count, not the row count the pipeline
--    actually processes.
--
--    Two very different causes, needing two very different fixes:
--
--      PLACEHOLDER   one sentinel value on tens of millions of unmatched
--                    profiles. Then ~23M junk rows collapse into a single
--                    fake person, and every title they carry is inflating
--                    the dictionary. The filter needs to exclude it.
--
--      SNAPSHOT      a history table with one row per person per load.
--                    Then the pipeline is processing ~14 copies of
--                    everyone and raw should keep only the latest.
--
--    7a tells you which. If the top row is one snid with millions of rows,
--    it is a placeholder. If the counts are flat at around 14, it is a
--    snapshot.
-- ###########################################################################

-- 7a. The shape of the duplication.
--     Reads the snid column only. Do not add ARRAY_LENGTH(employments)
--     here - that forces a scan of the nested array across all 25.1M
--     rows, which is the expensive column in this table.
SELECT
    snid,
    COUNT(*)    AS rows_for_this_snid
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`
GROUP BY snid
ORDER BY rows_for_this_snid DESC
LIMIT 20;


-- 7b. The distribution, so one outlier does not hide the pattern.
--     Also snid-only, so run this one first if you want the answer for
--     the price of a single column.
WITH per_snid AS (
  SELECT snid, COUNT(*) AS n
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`
  GROUP BY snid
)
SELECT
    CASE
      WHEN n = 1            THEN '1 row'
      WHEN n BETWEEN 2 AND 5    THEN '2-5 rows'
      WHEN n BETWEEN 6 AND 20   THEN '6-20 rows'
      WHEN n BETWEEN 21 AND 100 THEN '21-100 rows'
      ELSE                           'over 100 rows'
    END                                 AS bucket,
    COUNT(*)                            AS snids,
    SUM(n)                              AS rows_total,
    ROUND(SUM(n) / (SELECT SUM(n) FROM per_snid), 4) AS share_of_rows
FROM per_snid
GROUP BY bucket
ORDER BY rows_total DESC;


-- ###########################################################################
-- 7c. IS THE GRAIN (snid, orcid_id) OR (orcid_id, version)?
--
--     Query 7b ruled out both of the causes query 7 proposed. There is no
--     placeholder snid - no single value carries millions of rows - and it
--     is not a flat snapshot either, because the counts run from 1 to over
--     100 in a smooth curve:
--
--       1 row         185,557 snids    185,557 rows    0.7%
--       2-5 rows      558,944 snids  2,107,081 rows    8.4%
--       6-20 rows     699,168 snids  7,519,793 rows   29.9%
--       21-100 rows   318,713 snids 12,591,948 rows   50.1%
--       over 100      19,242 snids  2,728,262 rows   10.9%
--
--     _sources.yml claims "One row per person" for this table. It is not.
--     The two readings left differ enormously in what they imply:
--
--       VERSIONS - many rows per ORCID profile, one per load. Harmless
--         data-wise, but raw should keep the latest per snid: 14x less to
--         scan, honest dictionary frequencies, and no risk of scoring an
--         employment the person has since deleted.
--
--       MANY ORCID IDS PER SNID - the snid to ORCID match is overmatched.
--         Then fct_researcher_roles, which is grained on snid, is
--         assigning one marketing contact the roles of up to a hundred
--         different people. That is a correctness bug, it is upstream of
--         us, and no dedup here fixes it.
--
--     If distinct_orcid equals source_rows, it is the second one.
-- ###########################################################################
SELECT
    COUNT(*)                                                AS source_rows,
    COUNT(DISTINCT orcid_id)                                AS distinct_orcid,
    COUNT(DISTINCT snid)                                    AS distinct_snid,
    ROUND(COUNT(*) / COUNT(DISTINCT orcid_id), 2)           AS rows_per_orcid,
    ROUND(COUNT(DISTINCT orcid_id) / COUNT(DISTINCT snid), 2) AS orcid_per_snid
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`;


-- 7d. The worst offenders: versions of one profile, or many profiles?
SELECT
    snid,
    COUNT(*)                    AS rows_for_this_snid,
    COUNT(DISTINCT orcid_id)    AS distinct_orcid_ids,
    MIN(last_updated_at)        AS first_seen,
    MAX(last_updated_at)        AS last_seen
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`
GROUP BY snid
ORDER BY rows_for_this_snid DESC
LIMIT 20;


-- ###########################################################################
-- 8. INSIDE STAGE D - WHAT DO WE SAY ABOUT THESE PEOPLE INSTEAD?
--
--     Query 3b settled where the 118,664 go missing, and it is not where I
--     said. Stages B and C are EMPTY: every one of them has employment
--     records and every one has at least one PUBLIC record, so the
--     visibility filter explains none of it. E2 is 1 person, so scoring
--     explains none of it either.
--
--     99.86% simply carry no clinical signal in our copy - no department
--     we read as health_clinical and no title we read as a clinician.
--     Phase-1 recorded clinical departments for thousands of them
--     (neurology 422, radiology 348, urology 298 in analyses/14 query 2),
--     so either it read a field we do not, or it read a record we do not
--     have.
--
--     8a asks what we assign them instead. If they come back as
--     teaching_academic over life_biomedical, that is a discipline-anchor
--     problem and it is fixable in a seed. If they come back with nothing
--     at all, the data is not reaching us and the fix is upstream.
-- ###########################################################################

-- 8a. Where do they land instead?
WITH missing AS (
  SELECT DISTINCT p.snid
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.TODO_phase1_table` p
  LEFT JOIN (
      SELECT DISTINCT snid
      FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
      WHERE role_key IN ('hcp', 'hcp_broad')
  ) n USING (snid)
  WHERE p.phase1_label IN ('CONFIRMED_HCP_CANDIDATE', 'PROBABLE_HCP')
    AND n.snid IS NULL
)
SELECT
    COALESCE(t.title_group, '(no title group)')      AS title_group,
    COALESCE(d.discipline,  '(no discipline)')       AS discipline,
    COUNT(DISTINCT r.snid)                           AS people,
    COUNT(*)                                         AS records
FROM missing m
JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
  ON r.snid = m.snid
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` t
  ON t.title_key = r.title_key AND t.is_assigned
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_department_discipline` d
  ON d.department = r.department AND d.is_assigned
GROUP BY title_group, discipline
ORDER BY people DESC
LIMIT 40;


-- 8b. Side by side: what Phase-1 recorded against what we hold.
--     Thirty people is enough to see whether the record is missing or
--     merely unrecognised.
WITH missing AS (
  SELECT p.snid, p.orcid_role, p.orcid_organisation, p.orcid_department
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.TODO_phase1_table` p
  LEFT JOIN (
      SELECT DISTINCT snid
      FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
      WHERE role_key IN ('hcp', 'hcp_broad')
  ) n USING (snid)
  WHERE p.phase1_label IN ('CONFIRMED_HCP_CANDIDATE', 'PROBABLE_HCP')
    AND n.snid IS NULL
    AND p.orcid_department IS NOT NULL
  LIMIT 30
)
SELECT
    m.snid,
    m.orcid_role                AS phase1_title,
    m.orcid_department          AS phase1_department,
    r.role_title_raw            AS our_title,
    r.department_raw            AS our_department,
    r.organisation_raw          AS our_org,
    r.is_current
FROM missing m
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
  ON r.snid = m.snid
ORDER BY m.snid, r.is_current DESC;


-- ###########################################################################
-- 7e / 7f. THE VERSION KEY
--
--     ANSWERED by 7c: orcid_per_snid is exactly 1.00 and rows_per_orcid is
--     14.11, so the snid to ORCID match is clean and the duplication is
--     pure versioning. raw_orcid_researchers now keeps the newest row per
--     snid, ordered by last_updated_at.
--
--     That ordering rests on one assumption: rows sharing the maximum
--     last_updated_at are the same profile unchanged between loads, so
--     picking any of them gives the same answer. 7f checks it. If
--     distinct_employment_counts comes back above 1 for the newest
--     version, the assumption is wrong and the ordering needs a real
--     ingestion timestamp - which 7e is for.
-- ###########################################################################

-- 7e. What columns could carry a load timestamp?
SELECT column_name, data_type
FROM `researcher-360-prod-e7fd74be.researcher_profiles.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'orcid_researchers'
ORDER BY ordinal_position;


-- 7f. Do the rows sharing the newest last_updated_at agree with each other?
WITH ranked AS (
  SELECT
      snid,
      last_updated_at,
      ARRAY_LENGTH(employments) AS n_emp,
      DENSE_RANK() OVER (PARTITION BY snid ORDER BY last_updated_at DESC) AS version_rank
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`
  WHERE snid IN (
      SELECT snid
      FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`
      GROUP BY snid
      HAVING COUNT(*) BETWEEN 20 AND 40
      LIMIT 200
  )
)
SELECT
    version_rank,
    COUNT(*)                                        AS rows_at_this_rank,
    COUNT(DISTINCT snid)                            AS people,
    ROUND(COUNT(*) / COUNT(DISTINCT snid), 2)       AS rows_per_person,
    COUNT(DISTINCT FORMAT('%t|%t', snid, n_emp))    AS distinct_snid_empcount_pairs
FROM ranked
WHERE version_rank <= 3
GROUP BY version_rank
ORDER BY version_rank;


-- ###########################################################################
-- 9. POST-REBUILD SANITY CHECK - run this after every dbt run
--
--     Three things that have silently gone wrong at least once each, in
--     one place. Read it top to bottom; if any block is wrong, nothing
--     downstream of it is worth reading.
-- ###########################################################################

-- 9a. Did the dedup land, and did the seeds load?
--     raw should now hold 1,781,624 rows, not 25,132,641. If it still
--     holds 25M the qualify is not in the build.
SELECT
    'raw rows'        AS check_name,
    CAST(COUNT(*) AS STRING)           AS value,
    '1,781,624 expected'               AS expected
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_orcid_researchers`
UNION ALL
SELECT
    'distinct snid',
    CAST(COUNT(DISTINCT snid) AS STRING),
    'same as raw rows - one row per person'
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.raw_orcid_researchers`
UNION ALL
SELECT
    'org_type_scores rows',
    CAST(COUNT(*) AS STRING),
    '80 - includes the four hcp_* keys; 50 means the seed did not reload'
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.org_type_scores`;


-- 9b. Which roles exist, and did each get an organisation scale?
--     A role with avg_org_score of 0 across every org_type has no rows in
--     org_type_scores, which means dbt seed was skipped. The new hcp_*
--     roles are the ones at risk.
SELECT
    role_key,
    COUNT(*)                                        AS records,
    COUNT(DISTINCT snid)                            AS people,
    ROUND(AVG(org_score), 3)                        AS avg_org_score,
    ROUND(AVG(role_score), 3)                       AS avg_role_score,
    ROUND(AVG(dept_score), 3)                       AS avg_dept_score,
    COUNTIF(org_score IS NULL)                      AS null_org_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
GROUP BY role_key
ORDER BY people DESC;


-- 9c. Is faculty_head on the new organisation scale?
--     UNKNOWN averaged 0.117 on the old seed. On the new one it should be
--     at or near 0.000 - the regex fallback can still lift a few rows, so
--     a small positive number is fine, but 0.117 means the seed is stale.
SELECT
    COALESCE(org_type, '(null)')                    AS org_type,
    COUNT(*)                                        AS records,
    ROUND(AVG(org_score), 3)                        AS avg_org_score
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
WHERE role_key = 'faculty_head'
GROUP BY org_type
ORDER BY records DESC;


-- ###########################################################################
-- 10. PHARMACIST: WHAT WOULD "match: all" ACTUALLY COST?
--
--     Query 9b showed pharmacist with avg_role_score 0.135 against
--     0.88-0.95 for every other role. The role is 'match: any', so a
--     record enters on the pharmacist TITLE or the pharmacy DEPARTMENT,
--     and that 0.135 says roughly 86% of the population arrives on the
--     department alone - pharmacy academics and students, not pharmacists.
--
--     Weights are 0.40 title / 0.20 org / 0.40 dept, confirming at 0.60:
--
--       both axes      0.40*role + 0.20*org + 0.40*dept   ~0.85  CONFIRMED
--       title only     0.40*role + 0.20*org               <=0.60 borderline
--       dept only                  0.20*org + 0.40*dept   <=0.60 borderline
--
--     The two single-axis routes cap at exactly 0.60, so they confirm only
--     when the organisation is perfect and sit in PROBABLE otherwise. That
--     is the 2,719 CONFIRMED against 27,789 PROBABLE in the baseline.
--
--     THE HIDDEN COST. pharmacist rolls up into hcp_broad, and a pharmacy
--     department resolves to 'pharmacy', NOT 'health_clinical'. So a
--     dept-only pharmacist is not in hcp_broad on their own merit - they
--     are there purely through the roll-up. Dropping them from pharmacist
--     drops them from hcp_broad too, unless they independently hold a
--     practitioner title or a clinical department. The last column counts
--     exactly who would survive.
--
--     Compare the two options before choosing:
--       match: all        removes routes 2 and 3 from the role entirely
--       confirmed: 0.70   keeps them in the role as PROBABLE, and only
--                         both-axes cases ship, since only CONFIRMED does
-- ###########################################################################
WITH p AS (
  SELECT
      e.snid,
      CASE
        WHEN e.role_score > 0 AND COALESCE(e.dept_score, 0) > 0
                                 THEN '1. both axes - survives match:all'
        WHEN e.role_score > 0    THEN '2. pharmacist title only'
        ELSE                          '3. pharmacy department only'
      END                                                   AS route,
      e.org_score,
      0.40 * e.role_score + 0.20 * e.org_score
           + 0.40 * COALESCE(e.dept_score, 0)               AS score
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored` e
  WHERE e.role_key = 'pharmacist'
),
-- hcp_broad rows a person earns WITHOUT the pharmacist roll-up
hcp_own AS (
  SELECT DISTINCT snid
  FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.int_employment_scored`
  WHERE role_key = 'hcp_broad'
)
SELECT
    p.route,
    COUNT(*)                                        AS people,
    ROUND(AVG(p.org_score), 3)                      AS avg_org_score,
    ROUND(AVG(p.score), 3)                          AS avg_score,
    COUNTIF(p.score >= 0.60)                        AS confirmed_now,
    COUNTIF(p.score >= 0.70)                        AS confirmed_if_070,
    COUNTIF(p.score >= 0.30 AND p.score < 0.60)     AS probable_now,
    COUNTIF(h.snid IS NOT NULL)                     AS also_in_hcp_on_own_merit
FROM p
LEFT JOIN hcp_own h USING (snid)
GROUP BY p.route
ORDER BY p.route;
