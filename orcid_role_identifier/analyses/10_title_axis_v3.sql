/*
    ============================================================================
    TITLE AXIS v3 - THREE FIXES
    ============================================================================
    v2 results were good on eight of nine groups. What broke:

    1. LIBRARIAN COLLAPSED - RESOLVED, see analyses/12
       Query 1 below searched the whole corpus and found the answer:
       1,154 people, 258 of them marketable. Librarians are too rare in
       ORCID to compete for anchor space against 9.4M professors, and a
       plain regex finds them perfectly well. Librarian is therefore
       OFF this axis entirely and handled in analyses/12.

    2. THE TEST WAS NOT RUNNING PRODUCTION'S NORMALISATION
       Production expands abbreviations; these tests did not. So:
         pi    (17,223 records) landed in leadership
                     -> production expands to "principal investigator"
         pdra  ( 6,449)         landed in leadership
                     -> production expands to "postdoctoral research associate"
       Both are correct in production and wrong only in the test.

    3. A MARGIN FLOOR IS MISSING
       Several titles were assigned on coin-flip margins:
         resident physician  35,206 records   margin 0.002
         dr                  96,439           margin 0.024
         psychologist         7,352           margin 0.009
         analyst              5,280           margin 0.016
       "Dr" is the clearest case - a courtesy title, not a role, and
       unresolvable from the title alone. Such titles should get NO title
       group and let the department decide. That is what two axes are for.

    NOTE ON THE SQL
    The abbreviation expansion below is GENERATED, not hand-written. The
    first version nested 14 REGEXP_REPLACE pairs inside 13 open calls and
    failed with "Unexpected keyword AS" - a miscount that is invisible by
    eye and cost a query run. Deeply nested calls get generated from now on.
    ============================================================================
*/


-- ###########################################################################
-- QUERY 2 - TITLE AXIS WITH PRODUCTION NORMALISATION
--   Librarian removed from the axis - it has its own path now.
-- ###########################################################################
WITH top_titles AS (
  SELECT
      TRIM(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)), r'[^\p{L}\p{N}\s&/+-]', ' '), r'\bprof\b', 'professor'), r'\bassoc\b', 'associate'), r'\basst\b', 'assistant'), r'\bsr\b', 'senior'), r'\bjr\b', 'junior'), r'\bdir\b', 'director'), r'\bres\b', 'research'), r'\bsci\b', 'scientist'), r'\bpi\b', 'principal investigator'), r'\bpdra\b', 'postdoctoral research associate'), r'\bpost doc\b', 'postdoc'), r'\bmed\b', 'medical'), r'\s+', ' ')) AS title,
      COUNT(*) AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
  GROUP BY title
  HAVING LENGTH(title) BETWEEN 2 AND 200
  ORDER BY records DESC LIMIT 500
),
title_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('teaching_academic' AS grp, 'professor' AS example),
    ('teaching_academic','assistant professor'),('teaching_academic','associate professor'),
    ('teaching_academic','full professor'),('teaching_academic','adjunct professor'),
    ('teaching_academic','visiting professor'),('teaching_academic','lecturer'),
    ('teaching_academic','senior lecturer'),('teaching_academic','assistant lecturer'),
    ('teaching_academic','instructor'),('teaching_academic','teacher'),
    ('teaching_academic','docente'),('teaching_academic','dozent'),
    ('teaching_academic','faculty member'),('teaching_academic','reader'),

    ('researcher_early','postdoctoral researcher'),('researcher_early','postdoc'),
    ('researcher_early','postdoctoral research associate'),
    ('researcher_early','research fellow'),('researcher_early','research assistant'),
    ('researcher_early','research associate'),('researcher_early','researcher'),
    ('researcher_early','postdoctoral fellow'),('researcher_early','post doctor'),
    ('researcher_early','wissenschaftlicher mitarbeiter'),
    ('researcher_early','assegnisti'),('researcher_early','borsisti'),
    ('researcher_early','collaboratori'),

    ('researcher_established','senior researcher'),('researcher_established','senior scientist'),
    ('researcher_established','research scientist'),
    ('researcher_established','principal investigator'),
    ('researcher_established','group leader'),('researcher_established','staff scientist'),
    ('researcher_established','scientist'),('researcher_established','head of laboratory'),
    ('researcher_established','scientific director'),

    ('student','phd student'),('student','phd candidate'),('student','doctoral candidate'),
    ('student','graduate student'),('student','student'),('student','doktorand'),
    ('student','phd scholar'),('student','research scholar'),('student','master student'),

    ('trainee_clinical','resident'),('trainee_clinical','resident physician'),
    ('trainee_clinical','senior resident'),('trainee_clinical','specialist registrar'),
    ('trainee_clinical','clinical fellow'),('trainee_clinical','intern'),
    ('trainee_clinical','house officer'),('trainee_clinical','medical resident'),

    ('leadership','dean'),('leadership','vice dean'),('leadership','head of department'),
    ('leadership','department head'),('leadership','department chair'),
    ('leadership','director'),('leadership','deputy director'),
    ('leadership','executive director'),('leadership','managing director'),
    ('leadership','chief'),('leadership','chair'),('leadership','chairman'),
    ('leadership','vice chancellor'),('leadership','provost'),('leadership','rector'),
    ('leadership','president'),('leadership','vice president'),
    ('leadership','chief executive officer'),('leadership','founder'),

    ('practitioner','consultant'),('practitioner','physician'),
    ('practitioner','medical doctor'),('practitioner','general practitioner'),
    ('practitioner','attending physician'),('practitioner','staff physician'),
    ('practitioner','chief physician'),('practitioner','surgeon'),
    ('practitioner','neurosurgeon'),('practitioner','cardiologist'),
    ('practitioner','radiologist'),('practitioner','neurologist'),
    ('practitioner','psychiatrist'),('practitioner','nurse'),
    ('practitioner','registered nurse'),('practitioner','physiotherapist'),
    ('practitioner','pharmacist'),('practitioner','dentist'),
    ('practitioner','medical officer'),('practitioner','dirigente medico'),

    ('support_technical','laboratory technician'),('support_technical','technician'),
    ('support_technical','research technician'),('support_technical','project manager'),
    ('support_technical','research officer'),('support_technical','research manager'),
    ('support_technical','administrator'),('support_technical','coordinator'),
    ('support_technical','administrative assistant'),('support_technical','analyst'),
    ('support_technical','data analyst'),('support_technical','engineer'),
    ('support_technical','supervisor')
  ])
),
te AS (
  SELECT title, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT title, records, title AS content FROM top_titles))
  WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
),
ae AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM title_anchors))
  WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
),
scored AS (
  SELECT t.title, t.records, a.grp,
         MAX(1 - ML.DISTANCE(t.v, a.v, 'COSINE')) AS sim
  FROM te t CROSS JOIN ae a GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY title ORDER BY sim DESC) AS rnk
  FROM scored
),
assigned AS (
  SELECT r1.title, r1.records, r1.grp AS title_group,
         ROUND(r1.sim,3) AS sim, ROUND(r1.sim - r2.sim,3) AS margin
  FROM ranked r1 LEFT JOIN ranked r2 ON r1.title=r2.title AND r2.rnk=2
  WHERE r1.rnk = 1
)
SELECT
    title_group,
    COUNT(*)                                            AS titles,
    SUM(records)                                        AS records,
    ROUND(SUM(records) / SUM(SUM(records)) OVER (), 4)  AS share_of_records,
    ROUND(AVG(margin), 3)                               AS avg_margin,
    COUNTIF(margin < 0.05)                              AS below_floor,
    STRING_AGG(title, ' | ' ORDER BY records DESC LIMIT 6) AS sample_titles
FROM assigned
GROUP BY title_group
ORDER BY records DESC;

-- CHECK: pi and pdra gone from leadership, post doctor in researcher_early,
-- analyst in support_technical.


-- ###########################################################################
-- QUERY 3 - WHAT DOES A MARGIN FLOOR COST?
--   Titles below the floor get no group and fall back to the department.
-- ###########################################################################
WITH top_titles AS (
  SELECT
      TRIM(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)), r'[^\p{L}\p{N}\s&/+-]', ' '), r'\bprof\b', 'professor'), r'\bassoc\b', 'associate'), r'\basst\b', 'assistant'), r'\bsr\b', 'senior'), r'\bjr\b', 'junior'), r'\bdir\b', 'director'), r'\bres\b', 'research'), r'\bsci\b', 'scientist'), r'\bpi\b', 'principal investigator'), r'\bpdra\b', 'postdoctoral research associate'), r'\bpost doc\b', 'postdoc'), r'\bmed\b', 'medical'), r'\s+', ' ')) AS title,
      COUNT(*) AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
  GROUP BY title
  HAVING LENGTH(title) BETWEEN 2 AND 200
  ORDER BY records DESC LIMIT 500
),
title_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('teaching_academic' AS grp, 'professor' AS example),
    ('teaching_academic','assistant professor'),('teaching_academic','associate professor'),
    ('teaching_academic','lecturer'),('teaching_academic','senior lecturer'),
    ('teaching_academic','instructor'),('teaching_academic','docente'),
    ('teaching_academic','reader'),('teaching_academic','faculty member'),
    ('researcher_early','postdoctoral researcher'),('researcher_early','postdoc'),
    ('researcher_early','research fellow'),('researcher_early','research assistant'),
    ('researcher_early','research associate'),('researcher_early','researcher'),
    ('researcher_early','post doctor'),('researcher_early','assegnisti'),
    ('researcher_early','postdoctoral research associate'),
    ('researcher_established','senior researcher'),('researcher_established','research scientist'),
    ('researcher_established','principal investigator'),('researcher_established','group leader'),
    ('researcher_established','scientist'),('researcher_established','head of laboratory'),
    ('student','phd student'),('student','phd candidate'),('student','graduate student'),
    ('student','student'),('student','doktorand'),('student','research scholar'),
    ('trainee_clinical','resident'),('trainee_clinical','resident physician'),
    ('trainee_clinical','specialist registrar'),('trainee_clinical','clinical fellow'),
    ('trainee_clinical','intern'),
    ('leadership','dean'),('leadership','head of department'),('leadership','director'),
    ('leadership','chief'),('leadership','chair'),('leadership','president'),
    ('leadership','provost'),('leadership','founder'),
    ('practitioner','consultant'),('practitioner','physician'),
    ('practitioner','medical doctor'),('practitioner','surgeon'),
    ('practitioner','nurse'),('practitioner','general practitioner'),
    ('practitioner','cardiologist'),('practitioner','psychiatrist'),
    ('support_technical','laboratory technician'),('support_technical','technician'),
    ('support_technical','project manager'),('support_technical','analyst'),
    ('support_technical','coordinator'),('support_technical','engineer')
  ])
),
te AS (
  SELECT title, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT title, records, title AS content FROM top_titles))
  WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
),
ae AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM title_anchors))
  WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
),
scored AS (
  SELECT t.title, t.records, a.grp,
         MAX(1 - ML.DISTANCE(t.v, a.v, 'COSINE')) AS sim
  FROM te t CROSS JOIN ae a GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY title ORDER BY sim DESC) AS rnk
  FROM scored
),
assigned AS (
  SELECT r1.title, r1.records, r1.grp AS title_group,
         r1.sim - r2.sim AS margin
  FROM ranked r1 LEFT JOIN ranked r2 ON r1.title=r2.title AND r2.rnk=2
  WHERE r1.rnk = 1
)
SELECT
    floor_value,
    SUM(IF(margin >= floor_value, records, 0))  AS records_kept,
    SUM(IF(margin <  floor_value, records, 0))  AS records_dropped,
    ROUND(SUM(IF(margin >= floor_value, records, 0)) / SUM(records), 4) AS share_kept,
    COUNTIF(margin < floor_value)               AS titles_dropped,
    STRING_AGG(IF(margin < floor_value, title, NULL), ' | '
               ORDER BY records DESC LIMIT 8)   AS largest_dropped
FROM assigned, UNNEST([0.00, 0.02, 0.03, 0.05, 0.08, 0.10, 0.15]) AS floor_value
GROUP BY floor_value
ORDER BY floor_value;
