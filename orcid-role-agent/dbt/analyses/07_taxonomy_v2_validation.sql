/*
    ============================================================================
    TAXONOMY v2 - VALIDATION
    ============================================================================
    Anchors rewritten from the REAL department list, not from guesses.
    Fixes carried in from test 06:
      - radiology, pathology, ophthalmology, urology, neurology, psychiatry,
        neurosurgery, cardiology, oncology now named explicitly under
        health_clinical (radiology was landing in earth_environment because
        it rhymes with geology)
      - epidemiology and public health moved to health_clinical
      - librarian dropped from the discipline axis entirely and detected
        from the TITLE instead - librarians do not write a department,
        their unit is the organisation
      - 18 discipline groups merged down to 12

    TWO AXES
      TITLE GROUP   from employments[].role            9 groups
      DISCIPLINE    from employments[].department_name 12 groups

    FIVE QUERIES
      1  discipline assignment + margins        (did radiology move?)
      2  samples per discipline                 (eyeball test)
      3  title group assignment + margins       (does librarian appear?)
      4  samples per title group                (eyeball test)
      5  THE PAYOFF - simulate the five roles and count real people
    ============================================================================
*/


-- ###########################################################################
-- QUERY 1 - DISCIPLINE from department, v2 anchors
-- ###########################################################################
WITH top_depts AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.department_name, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))  AS department,
      COUNT(*)                                         AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.department_name IS NOT NULL AND TRIM(e.department_name) != ''
  GROUP BY department ORDER BY records DESC LIMIT 500
),
discipline_anchors AS (
  SELECT * FROM UNNEST([
    -- health_clinical : every clinical specialty seen in the real list,
    -- named explicitly so none of them drift to a neighbour
    STRUCT('health_clinical' AS grp, 'medicine' AS example),
    ('health_clinical','internal medicine'),('health_clinical','surgery'),
    ('health_clinical','general surgery'),('health_clinical','pediatrics'),
    ('health_clinical','psychiatry'),('health_clinical','radiology'),
    ('health_clinical','cardiology'),('health_clinical','neurology'),
    ('health_clinical','neurosurgery'),('health_clinical','pathology'),
    ('health_clinical','ophthalmology'),('health_clinical','urology'),
    ('health_clinical','dermatology'),('health_clinical','anesthesiology'),
    ('health_clinical','obstetrics and gynecology'),('health_clinical','orthopedics'),
    ('health_clinical','emergency medicine'),('health_clinical','family medicine'),
    ('health_clinical','medical oncology'),('health_clinical','nursing'),
    ('health_clinical','dentistry'),('health_clinical','school of medicine'),
    ('health_clinical','faculty of medicine'),('health_clinical','clinical sciences'),
    ('health_clinical','public health'),('health_clinical','epidemiology'),
    ('health_clinical','klinik fur innere medizin'),

    ('pharmacy','pharmacy'),('pharmacy','pharmacology'),
    ('pharmacy','school of pharmacy'),('pharmacy','faculty of pharmacy'),
    ('pharmacy','pharmaceutical sciences'),('pharmacy','clinical pharmacy'),
    ('pharmacy','pharmaceutics'),

    ('life_biomedical','biology'),('life_biomedical','biological sciences'),
    ('life_biomedical','biochemistry'),('life_biomedical','microbiology'),
    ('life_biomedical','biotechnology'),('life_biomedical','physiology'),
    ('life_biomedical','molecular biology'),('life_biomedical','genetics'),
    ('life_biomedical','cell biology'),('life_biomedical','immunology'),
    ('life_biomedical','neuroscience'),('life_biomedical','zoology'),
    ('life_biomedical','botany'),('life_biomedical','veterinary medicine'),
    ('life_biomedical','animal science'),('life_biomedical','life sciences'),

    ('physical_chemistry','chemistry'),('physical_chemistry','physics'),
    ('physical_chemistry','materials science'),('physical_chemistry','astronomy'),
    ('physical_chemistry','applied physics'),('physical_chemistry','organic chemistry'),
    ('physical_chemistry','analytical chemistry'),('physical_chemistry','physical sciences'),

    ('engineering','mechanical engineering'),('engineering','civil engineering'),
    ('engineering','electrical engineering'),('engineering','chemical engineering'),
    ('engineering','biomedical engineering'),('engineering','industrial engineering'),
    ('engineering','civil and environmental engineering'),
    ('engineering','electrical and computer engineering'),
    ('engineering','electronics and communication engineering'),
    ('engineering','materials science and engineering'),
    ('engineering','aerospace engineering'),('engineering','engineering'),
    ('engineering','school of engineering'),('engineering','faculty of engineering'),

    ('computing_data','computer science'),('computing_data','computer engineering'),
    ('computing_data','computer science and engineering'),('computing_data','informatics'),
    ('computing_data','information technology'),('computing_data','software engineering'),
    ('computing_data','data science'),('computing_data','artificial intelligence'),

    ('mathematics_statistics','mathematics'),('mathematics_statistics','statistics'),
    ('mathematics_statistics','applied mathematics'),
    ('mathematics_statistics','mathematical sciences'),
    ('mathematics_statistics','actuarial science'),

    ('social_behavioural','psychology'),('social_behavioural','economics'),
    ('social_behavioural','sociology'),('social_behavioural','political science'),
    ('social_behavioural','anthropology'),('social_behavioural','social sciences'),
    ('social_behavioural','social work'),('social_behavioural','communication'),

    ('earth_agriculture','geography'),('earth_agriculture','geology'),
    ('earth_agriculture','earth sciences'),('earth_agriculture','environmental science'),
    ('earth_agriculture','agronomy'),('earth_agriculture','agriculture'),
    ('earth_agriculture','food science'),('earth_agriculture','food engineering'),
    ('earth_agriculture','horticulture'),('earth_agriculture','forestry'),
    ('earth_agriculture','soil science'),('earth_agriculture','marine science'),
    ('earth_agriculture','atmospheric science'),

    ('business_public','business administration'),('business_public','business school'),
    ('business_public','school of management'),('business_public','finance'),
    ('business_public','accounting'),('business_public','marketing'),
    ('business_public','public policy'),('business_public','public administration'),
    ('business_public','management'),

    ('humanities_law_edu','philosophy'),('humanities_law_edu','history'),
    ('humanities_law_edu','law'),('humanities_law_edu','faculty of law'),
    ('humanities_law_edu','education'),('humanities_law_edu','school of education'),
    ('humanities_law_edu','linguistics'),('humanities_law_edu','literature'),
    ('humanities_law_edu','english'),('humanities_law_edu','foreign languages'),
    ('humanities_law_edu','arts'),('humanities_law_edu','music'),
    ('humanities_law_edu','theology'),('humanities_law_edu','archaeology'),

    ('non_academic','research'),('non_academic','research and development'),
    ('non_academic','administration'),('non_academic','human resources'),
    ('non_academic','information technology services'),('non_academic','finance office'),
    ('non_academic','library'),('non_academic','university library')
  ])
),
dept_emb AS (
  SELECT department, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT department, records, department AS content FROM top_depts))
),
anchor_emb AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM discipline_anchors))
),
per_group AS (
  SELECT d.department, d.records, a.grp,
         MAX(1 - ML.DISTANCE(d.v, a.v, 'COSINE')) AS sim
  FROM dept_emb d CROSS JOIN anchor_emb a GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY department ORDER BY sim DESC) AS rnk
  FROM per_group
),
assigned AS (
  SELECT r1.department, r1.records, r1.grp AS discipline,
         ROUND(r1.sim,3) AS sim, ROUND(r1.sim - r2.sim,3) AS margin
  FROM ranked r1 LEFT JOIN ranked r2 ON r1.department=r2.department AND r2.rnk=2
  WHERE r1.rnk = 1
)
SELECT
    discipline,
    COUNT(*)                                            AS departments,
    SUM(records)                                        AS records,
    ROUND(SUM(records) / SUM(SUM(records)) OVER (), 4)  AS share_of_records,
    ROUND(AVG(margin), 3)                               AS avg_margin,
    COUNTIF(margin < 0.03)                              AS weak_margin_depts,
    STRING_AGG(department, ' | ' ORDER BY records DESC LIMIT 5) AS sample_departments
FROM assigned
GROUP BY discipline
ORDER BY records DESC;

-- CHECK: radiology, pathology, ophthalmology, urology must now sit under
-- health_clinical. Every group should be populated and avg_margin should
-- stay in the 0.08 - 0.20 band seen in test 06.


-- ###########################################################################
-- QUERY 2 - Where did the previously misassigned departments land?
--           Targeted check rather than a full sample dump.
-- ###########################################################################
WITH top_depts AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.department_name, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS department,
      COUNT(*) AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.department_name IS NOT NULL AND TRIM(e.department_name) != ''
  GROUP BY department ORDER BY records DESC LIMIT 500
),
discipline_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('health_clinical' AS grp, 'medicine' AS example),
    ('health_clinical','internal medicine'),('health_clinical','surgery'),
    ('health_clinical','pediatrics'),('health_clinical','psychiatry'),
    ('health_clinical','radiology'),('health_clinical','cardiology'),
    ('health_clinical','neurology'),('health_clinical','neurosurgery'),
    ('health_clinical','pathology'),('health_clinical','ophthalmology'),
    ('health_clinical','urology'),('health_clinical','medical oncology'),
    ('health_clinical','nursing'),('health_clinical','public health'),
    ('health_clinical','epidemiology'),('health_clinical','school of medicine'),
    ('pharmacy','pharmacy'),('pharmacy','pharmacology'),('pharmacy','school of pharmacy'),
    ('pharmacy','pharmaceutical sciences'),
    ('life_biomedical','biology'),('life_biomedical','biochemistry'),
    ('life_biomedical','microbiology'),('life_biomedical','biotechnology'),
    ('life_biomedical','physiology'),('life_biomedical','genetics'),
    ('life_biomedical','neuroscience'),('life_biomedical','veterinary medicine'),
    ('physical_chemistry','chemistry'),('physical_chemistry','physics'),
    ('physical_chemistry','materials science'),('physical_chemistry','astronomy'),
    ('engineering','mechanical engineering'),('engineering','civil engineering'),
    ('engineering','electrical engineering'),('engineering','chemical engineering'),
    ('engineering','biomedical engineering'),('engineering','engineering'),
    ('computing_data','computer science'),('computing_data','computer engineering'),
    ('computing_data','informatics'),('computing_data','information technology'),
    ('mathematics_statistics','mathematics'),('mathematics_statistics','statistics'),
    ('mathematics_statistics','applied mathematics'),
    ('social_behavioural','psychology'),('social_behavioural','economics'),
    ('social_behavioural','sociology'),('social_behavioural','political science'),
    ('earth_agriculture','geography'),('earth_agriculture','geology'),
    ('earth_agriculture','environmental science'),('earth_agriculture','agronomy'),
    ('earth_agriculture','food science'),
    ('business_public','business administration'),('business_public','management'),
    ('business_public','finance'),('business_public','public administration'),
    ('humanities_law_edu','philosophy'),('humanities_law_edu','history'),
    ('humanities_law_edu','law'),('humanities_law_edu','education'),
    ('humanities_law_edu','linguistics'),('humanities_law_edu','english'),
    ('non_academic','research'),('non_academic','research and development'),
    ('non_academic','administration'),('non_academic','library')
  ])
),
dept_emb AS (
  SELECT department, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT department, records, department AS content FROM top_depts))
),
anchor_emb AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM discipline_anchors))
),
per_group AS (
  SELECT d.department, d.records, a.grp,
         MAX(1 - ML.DISTANCE(d.v, a.v, 'COSINE')) AS sim
  FROM dept_emb d CROSS JOIN anchor_emb a GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY department ORDER BY sim DESC) AS rnk
  FROM per_group
)
SELECT
    r1.department,
    r1.records,
    r1.grp                      AS assigned_discipline,
    ROUND(r1.sim, 3)            AS sim,
    ROUND(r1.sim - r2.sim, 3)   AS margin
FROM ranked r1 LEFT JOIN ranked r2 ON r1.department = r2.department AND r2.rnk = 2
WHERE r1.rnk = 1
  AND r1.department IN (
    'radiology','pathology','ophthalmology','urology','neurology','psychiatry',
    'neurosurgery','cardiology','medical oncology','public health','physiology',
    'biotechnology','biomedical engineering','management','research',
    'materials science and engineering','geography','education'
  )
ORDER BY r1.records DESC;


-- ###########################################################################
-- QUERY 3 - TITLE GROUP, v2. Nine groups: eight positions + librarian.
--           Librarian is a profession, but it is recognisable from the
--           title, which is why it lives on this axis.
-- ###########################################################################
WITH top_titles AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS title,
      COUNT(*) AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
  GROUP BY title ORDER BY records DESC LIMIT 500
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
    ('teaching_academic','faculty member'),

    ('researcher_early','postdoctoral researcher'),('researcher_early','postdoc'),
    ('researcher_early','post doc'),('researcher_early','research fellow'),
    ('researcher_early','research assistant'),('researcher_early','research associate'),
    ('researcher_early','researcher'),('researcher_early','postdoctoral fellow'),
    ('researcher_early','wissenschaftlicher mitarbeiter'),

    ('researcher_established','senior researcher'),('researcher_established','senior scientist'),
    ('researcher_established','research scientist'),('researcher_established','principal investigator'),
    ('researcher_established','group leader'),('researcher_established','staff scientist'),
    ('researcher_established','senior research fellow'),('researcher_established','scientist'),

    ('student','phd student'),('student','phd candidate'),
    ('student','doctoral candidate'),('student','doctoral student'),
    ('student','graduate student'),('student','student'),
    ('student','doktorand'),('student','phd scholar'),
    ('student','master student'),('student','undergraduate student'),

    ('trainee_clinical','resident'),('trainee_clinical','resident physician'),
    ('trainee_clinical','medical resident'),('trainee_clinical','specialist registrar'),
    ('trainee_clinical','clinical fellow'),('trainee_clinical','intern'),
    ('trainee_clinical','house officer'),('trainee_clinical','registrar'),

    ('leadership','dean'),('leadership','head of department'),
    ('leadership','head'),('leadership','director'),
    ('leadership','deputy director'),('leadership','chief'),
    ('leadership','chair'),('leadership','vice chancellor'),
    ('leadership','provost'),('leadership','rector'),
    ('leadership','institute director'),('leadership','chief executive officer'),

    ('practitioner','consultant'),('practitioner','physician'),
    ('practitioner','medical doctor'),('practitioner','general practitioner'),
    ('practitioner','clinician'),('practitioner','attending physician'),
    ('practitioner','surgeon'),('practitioner','dentist'),('practitioner','nurse'),

    -- librarian detected from the TITLE, because librarians do not write
    -- a department - their unit is the organisation
    ('librarian','librarian'),('librarian','subject librarian'),
    ('librarian','academic librarian'),('librarian','research librarian'),
    ('librarian','information specialist'),('librarian','archivist'),
    ('librarian','repository manager'),('librarian','scholarly communications librarian'),
    ('librarian','library director'),('librarian','head of library services'),
    ('librarian','bibliothekar'),('librarian','kutuphaneci'),
    ('librarian','bibliothecaire'),('librarian','bibliotecario'),

    ('support_technical','laboratory technician'),('support_technical','technician'),
    ('support_technical','research technician'),('support_technical','project manager'),
    ('support_technical','administrator'),('support_technical','coordinator'),
    ('support_technical','administrative assistant'),('support_technical','research manager')
  ])
),
title_emb AS (
  SELECT title, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT title, records, title AS content FROM top_titles))
),
anchor_emb AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM title_anchors))
),
per_group AS (
  SELECT t.title, t.records, a.grp,
         MAX(1 - ML.DISTANCE(t.v, a.v, 'COSINE')) AS sim
  FROM title_emb t CROSS JOIN anchor_emb a GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY title ORDER BY sim DESC) AS rnk
  FROM per_group
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
    COUNTIF(margin < 0.03)                              AS weak_margin_titles,
    STRING_AGG(title, ' | ' ORDER BY records DESC LIMIT 6) AS sample_titles
FROM assigned
GROUP BY title_group
ORDER BY records DESC;

-- CHECK: does a librarian group appear at all, and do its sample titles
-- read like librarians?


-- ###########################################################################
-- QUERY 4 - Every title that lands in librarian, practitioner or leadership.
--           These three decide three of our roles, so read them closely.
-- ###########################################################################
WITH top_titles AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS title,
      COUNT(*) AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
  GROUP BY title ORDER BY records DESC LIMIT 500
),
title_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('teaching_academic' AS grp, 'professor' AS example),
    ('teaching_academic','assistant professor'),('teaching_academic','associate professor'),
    ('teaching_academic','lecturer'),('teaching_academic','senior lecturer'),
    ('teaching_academic','instructor'),('teaching_academic','teacher'),
    ('teaching_academic','docente'),('teaching_academic','faculty member'),
    ('researcher_early','postdoctoral researcher'),('researcher_early','postdoc'),
    ('researcher_early','research fellow'),('researcher_early','research assistant'),
    ('researcher_early','research associate'),('researcher_early','researcher'),
    ('researcher_early','wissenschaftlicher mitarbeiter'),
    ('researcher_established','senior researcher'),('researcher_established','senior scientist'),
    ('researcher_established','research scientist'),('researcher_established','principal investigator'),
    ('researcher_established','group leader'),('researcher_established','scientist'),
    ('student','phd student'),('student','phd candidate'),('student','graduate student'),
    ('student','student'),('student','doktorand'),
    ('trainee_clinical','resident'),('trainee_clinical','specialist registrar'),
    ('trainee_clinical','clinical fellow'),('trainee_clinical','intern'),
    ('trainee_clinical','registrar'),
    ('leadership','dean'),('leadership','head of department'),('leadership','head'),
    ('leadership','director'),('leadership','deputy director'),('leadership','chief'),
    ('leadership','chair'),('leadership','provost'),
    ('practitioner','consultant'),('practitioner','physician'),
    ('practitioner','medical doctor'),('practitioner','general practitioner'),
    ('practitioner','clinician'),('practitioner','surgeon'),('practitioner','nurse'),
    ('librarian','librarian'),('librarian','subject librarian'),
    ('librarian','academic librarian'),('librarian','information specialist'),
    ('librarian','archivist'),('librarian','repository manager'),
    ('librarian','library director'),('librarian','bibliothekar'),
    ('librarian','kutuphaneci'),('librarian','bibliothecaire'),
    ('support_technical','laboratory technician'),('support_technical','technician'),
    ('support_technical','project manager'),('support_technical','administrator'),
    ('support_technical','coordinator')
  ])
),
title_emb AS (
  SELECT title, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT title, records, title AS content FROM top_titles))
),
anchor_emb AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM title_anchors))
),
per_group AS (
  SELECT t.title, t.records, a.grp,
         MAX(1 - ML.DISTANCE(t.v, a.v, 'COSINE')) AS sim
  FROM title_emb t CROSS JOIN anchor_emb a GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY title ORDER BY sim DESC) AS rnk
  FROM per_group
)
SELECT
    r1.grp                      AS title_group,
    r1.title,
    r1.records,
    ROUND(r1.sim, 3)            AS sim,
    ROUND(r1.sim - r2.sim, 3)   AS margin
FROM ranked r1 LEFT JOIN ranked r2 ON r1.title = r2.title AND r2.rnk = 2
WHERE r1.rnk = 1
  AND r1.grp IN ('librarian','practitioner','leadership')
ORDER BY r1.grp, r1.records DESC;


-- ###########################################################################
-- QUERY 5 - THE PAYOFF
--           Apply both axes to real employment records and count people
--           per role. Top 500 titles and top 500 departments only, so
--           these are FLOOR figures, not final ones.
-- ###########################################################################
WITH emp AS (
  SELECT
      r.snid,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))  AS title,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.department_name, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))  AS department
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
),
top_titles AS (
  SELECT title, COUNT(*) n FROM emp GROUP BY title ORDER BY n DESC LIMIT 500
),
top_depts AS (
  SELECT department, COUNT(*) n FROM emp
  WHERE department IS NOT NULL GROUP BY department ORDER BY n DESC LIMIT 500
),
title_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('teaching_academic' AS grp, 'professor' AS example),
    ('teaching_academic','assistant professor'),('teaching_academic','associate professor'),
    ('teaching_academic','lecturer'),('teaching_academic','senior lecturer'),
    ('teaching_academic','instructor'),('teaching_academic','docente'),
    ('researcher_early','postdoctoral researcher'),('researcher_early','postdoc'),
    ('researcher_early','research fellow'),('researcher_early','research assistant'),
    ('researcher_early','researcher'),('researcher_early','wissenschaftlicher mitarbeiter'),
    ('researcher_established','senior researcher'),('researcher_established','research scientist'),
    ('researcher_established','principal investigator'),('researcher_established','group leader'),
    ('student','phd student'),('student','phd candidate'),('student','graduate student'),
    ('student','student'),('student','doktorand'),
    ('trainee_clinical','resident'),('trainee_clinical','clinical fellow'),
    ('trainee_clinical','intern'),('trainee_clinical','registrar'),
    ('leadership','dean'),('leadership','head of department'),('leadership','head'),
    ('leadership','director'),('leadership','chief'),('leadership','chair'),
    ('practitioner','consultant'),('practitioner','physician'),
    ('practitioner','medical doctor'),('practitioner','clinician'),('practitioner','surgeon'),
    ('librarian','librarian'),('librarian','subject librarian'),
    ('librarian','academic librarian'),('librarian','information specialist'),
    ('librarian','archivist'),('librarian','repository manager'),
    ('librarian','bibliothekar'),('librarian','kutuphaneci'),
    ('support_technical','laboratory technician'),('support_technical','technician'),
    ('support_technical','project manager'),('support_technical','coordinator')
  ])
),
discipline_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('health_clinical' AS grp, 'medicine' AS example),
    ('health_clinical','internal medicine'),('health_clinical','surgery'),
    ('health_clinical','pediatrics'),('health_clinical','psychiatry'),
    ('health_clinical','radiology'),('health_clinical','cardiology'),
    ('health_clinical','neurology'),('health_clinical','pathology'),
    ('health_clinical','ophthalmology'),('health_clinical','urology'),
    ('health_clinical','nursing'),('health_clinical','public health'),
    ('health_clinical','school of medicine'),
    ('pharmacy','pharmacy'),('pharmacy','pharmacology'),
    ('pharmacy','school of pharmacy'),('pharmacy','pharmaceutical sciences'),
    ('life_biomedical','biology'),('life_biomedical','biochemistry'),
    ('life_biomedical','microbiology'),('life_biomedical','genetics'),
    ('physical_chemistry','chemistry'),('physical_chemistry','physics'),
    ('physical_chemistry','materials science'),
    ('engineering','mechanical engineering'),('engineering','civil engineering'),
    ('engineering','electrical engineering'),('engineering','engineering'),
    ('computing_data','computer science'),('computing_data','informatics'),
    ('mathematics_statistics','mathematics'),('mathematics_statistics','statistics'),
    ('social_behavioural','psychology'),('social_behavioural','economics'),
    ('social_behavioural','sociology'),
    ('earth_agriculture','geography'),('earth_agriculture','geology'),
    ('earth_agriculture','agronomy'),
    ('business_public','business administration'),('business_public','management'),
    ('humanities_law_edu','philosophy'),('humanities_law_edu','history'),
    ('humanities_law_edu','law'),('humanities_law_edu','education'),
    ('non_academic','research'),('non_academic','administration'),('non_academic','library')
  ])
),
te AS (
  SELECT title, ml_generate_embedding_result AS v FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT title, title AS content FROM top_titles))
),
ta AS (
  SELECT grp, ml_generate_embedding_result AS v FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM title_anchors))
),
de AS (
  SELECT department, ml_generate_embedding_result AS v FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT department, department AS content FROM top_depts))
),
da AS (
  SELECT grp, ml_generate_embedding_result AS v FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM discipline_anchors))
),
title_map AS (
  SELECT title, grp AS title_group FROM (
    SELECT t.title, a.grp, MAX(1 - ML.DISTANCE(t.v, a.v, 'COSINE')) AS sim
    FROM te t CROSS JOIN ta a GROUP BY 1,2
  ) QUALIFY ROW_NUMBER() OVER (PARTITION BY title ORDER BY sim DESC) = 1
),
dept_map AS (
  SELECT department, grp AS discipline FROM (
    SELECT d.department, a.grp, MAX(1 - ML.DISTANCE(d.v, a.v, 'COSINE')) AS sim
    FROM de d CROSS JOIN da a GROUP BY 1,2
  ) QUALIFY ROW_NUMBER() OVER (PARTITION BY department ORDER BY sim DESC) = 1
),
labelled AS (
  SELECT
      e.snid,
      tm.title_group,
      dm.discipline
  FROM emp e
  LEFT JOIN title_map tm USING (title)
  LEFT JOIN dept_map  dm ON e.department = dm.department
),
roles AS (
  SELECT snid, 'researcher'   AS role FROM labelled WHERE title_group IN ('researcher_early','researcher_established')
  UNION ALL
  SELECT snid, 'lecturer'            FROM labelled WHERE title_group = 'teaching_academic'
  UNION ALL
  SELECT snid, 'faculty_head'        FROM labelled WHERE title_group = 'leadership'
  UNION ALL
  SELECT snid, 'librarian'           FROM labelled WHERE title_group = 'librarian'
  UNION ALL
  SELECT snid, 'hcp'                 FROM labelled WHERE discipline = 'health_clinical'
  UNION ALL
  SELECT snid, 'hcp'                 FROM labelled WHERE title_group IN ('practitioner','trainee_clinical')
  UNION ALL
  SELECT snid, 'pharmacist'          FROM labelled WHERE discipline = 'pharmacy'
)
SELECT
    r.role,
    COUNT(DISTINCT r.snid)                                          AS people,
    COUNT(DISTINCT IF(c.snid IS NOT NULL, r.snid, NULL))            AS in_cdp,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in, r.snid, NULL))             AS marketable,
    COUNT(DISTINCT IF(c.advertising_opt_in, r.snid, NULL))          AS advertisable
FROM roles r
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON r.snid = c.snid
GROUP BY r.role
ORDER BY people DESC;

/*
    These are FLOOR figures. Only the top 500 titles and top 500
    departments are mapped here; in production every distinct value is
    mapped, so the real counts will be higher.

    What to judge:
      - are the role sizes plausible next to Phase-1's 94,139 HCPs?
      - does librarian produce a usable number at all?
      - does researcher come out large, as the title distribution predicts?
*/
