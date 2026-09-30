/*
    ============================================================================
    TITLE AXIS v3 - THREE FIXES
    ============================================================================
    v2 results were good on eight of nine groups. What broke:

    1. LIBRARIAN COLLAPSED
       Only 2 titles landed in it, both wrong: "assegnisti" (Italian for
       grant holders) and "reader" (a UK academic rank). Margin 0.020.
       Cause: the test only looks at the top 500 titles, and librarian
       titles do not reach that cutoff. The test cannot see them.
       Query 1 searches the WHOLE corpus instead.

    2. THE TEST WAS NOT RUNNING PRODUCTION'S NORMALISATION
       Production expands abbreviations; these tests did not. So:
         pi    (17,223 records) landed in leadership
                     -> production expands to "principal investigator"
         pdra  ( 6,449)         landed in leadership
                     -> production expands to "postdoctoral research associate"
       Both are correct in production and wrong only in the test.
       Query 2 applies the full production expansion.

    3. A MARGIN FLOOR IS MISSING
       Several titles were assigned on coin-flip margins:
         resident physician  35,206 records   margin 0.002
         dr                  96,439           margin 0.024
         analyst              5,280           margin 0.016
         psychologist         7,352           margin 0.009
       These should get NO title group and let the department decide the
       role instead. That is the whole point of having two axes.
       Query 3 sizes what a floor would cost and save.
    ============================================================================
*/


-- ###########################################################################
-- QUERY 1 - WHERE ARE THE LIBRARIANS?
--   Whole corpus, no top-N cutoff. Regex first to find them at all,
--   then we can judge whether the group is worth having.
-- ###########################################################################
WITH titles AS (
  SELECT
      r.snid,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))  AS title
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
)
SELECT
    title,
    COUNT(*)                AS records,
    COUNT(DISTINCT snid)    AS people
FROM titles
WHERE REGEXP_CONTAINS(title,
  r'(librar|bibliothek|bibliotec|bibliothec|biblioteka|kutuphane|archivist|archiviste|arsivci|repository manager|scholarly communication|information specialist|information officer|open access officer)')
GROUP BY title
ORDER BY records DESC
LIMIT 80;

-- Then the size of the whole population:
WITH titles AS (
  SELECT
      r.snid,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))  AS title
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
)
SELECT
    COUNT(DISTINCT title)                                       AS distinct_librarian_titles,
    COUNT(*)                                                    AS records,
    COUNT(DISTINCT t.snid)                                      AS people,
    COUNT(DISTINCT IF(c.snid IS NOT NULL, t.snid, NULL))        AS in_cdp,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in, t.snid, NULL))         AS marketable
FROM titles t
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON t.snid = c.snid
WHERE REGEXP_CONTAINS(t.title,
  r'(librar|bibliothek|bibliotec|bibliothec|biblioteka|kutuphane|archivist|archiviste|arsivci|repository manager|scholarly communication|information specialist|information officer|open access officer)');

/*
    If this returns a few thousand people, librarian deserves its own
    detection path and does not belong on the shared title axis at all -
    it is too rare to compete with 9.4M professors for anchor space.
    A dedicated regex plus a small embedding pass over just those titles
    would be both cheaper and more accurate.
*/


-- ###########################################################################
-- QUERY 2 - TITLE AXIS WITH PRODUCTION NORMALISATION
--   Same as v2 but with the full abbreviation expansion from
--   dbt_project.yml, so pi / pdra / prof / assoc behave as they will live.
--   Librarian removed from the axis - handled separately per query 1.
-- ###########################################################################
WITH top_titles AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
        REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
        REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
          REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
            r'[^\p{L}\p{N}\s&/+-]', ' '),
          r'\bprof\b', 'professor'),   r'\bassoc\b', 'associate'),
          r'\basst\b', 'assistant'),   r'\bsr\b', 'senior'),
          r'\bjr\b', 'junior'),        r'\bdir\b', 'director'),
          r'\bres\b', 'research'),     r'\bsci\b', 'scientist'),
          r'\bpi\b', 'principal investigator'),
          r'\bpdra\b', 'postdoctoral research associate'),
          r'\bpost doc\b', 'postdoc'), r'\bmed\b', 'medical'),
        r'\s+', ' '))                                  AS title,
      COUNT(*)                                         AS records
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

-- CHECK: pi and pdra should now be gone from leadership. post doctor
-- should be researcher_early. analyst should be support_technical.


-- ###########################################################################
-- QUERY 3 - WHAT DOES A MARGIN FLOOR COST?
--   Titles below the floor get no group and fall back to the department.
--   Find the floor that removes the coin-flip assignments without
--   throwing away real volume.
-- ###########################################################################
WITH top_titles AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
        REGEXP_REPLACE(REGEXP_REPLACE(
          REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
            r'[^\p{L}\p{N}\s&/+-]', ' '),
          r'\bprof\b', 'professor'),  r'\bassoc\b', 'associate'),
          r'\basst\b', 'assistant'),  r'\bsr\b', 'senior'),
          r'\bpi\b', 'principal investigator'),
          r'\bpdra\b', 'postdoctoral research associate'),
        r'\s+', ' '))                                  AS title,
      COUNT(*)                                         AS records
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
    SUM(IF(margin >= floor_value, records, 0))                      AS records_kept,
    SUM(IF(margin <  floor_value, records, 0))                      AS records_dropped,
    ROUND(SUM(IF(margin >= floor_value, records, 0))
          / SUM(records), 4)                                        AS share_kept,
    COUNTIF(margin < floor_value)                                   AS titles_dropped
FROM assigned, UNNEST([0.00, 0.02, 0.03, 0.05, 0.08, 0.10, 0.15]) AS floor_value
GROUP BY floor_value
ORDER BY floor_value;

-- Then look at exactly which titles a 0.05 floor would drop, largest first:
-- if those are the coin-flips we want removed, the floor is right.
