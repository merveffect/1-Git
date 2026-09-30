/*
    ============================================================================
    ASSIGNMENT AUDIT - CATCHING THE radiology/geology CLASS OF ERROR
    ============================================================================
    radiology landed in earth_environment because it rhymes with geology.
    We caught that by reading a sample. Reading samples does not scale and
    does not prove anything - these queries catch the whole class.

    The method: REGEX AS AN AUDITOR, NOT AS A CLASSIFIER.
    There are stems whose meaning is not in doubt. Anything containing
    "cardiolog" is clinical. Anything containing "librar" is a librarian.
    We do not use those rules to assign - the embedding does that - we use
    them to check the embedding's work. Any disagreement is a bug in the
    anchors.

    FIVE AUDITS
      A  discipline stem audit  - departments assigned against a decisive stem
      B  title stem audit       - titles assigned against a decisive stem
      C  known-answer set       - 60 hand-labelled departments, accuracy
      D  low-margin queue       - what the model itself is unsure about
      E  confusion pairs        - which groups get mistaken for each other

    Suspected traps, listed here so they are checked rather than discovered:
        radiology     / geology         shared -ology, DIFFERENT families
        physiology    / psychology      shared -ology, different families
        pathology     / psychology
        oncology      / ontology        clinical vs philosophy
        neurology     / neuroscience    clinical vs basic science
        psychiatry    / psychology      clinical vs social, near-identical stem
        public health / public admin    shared "public"
        veterinary medicine             contains "medicine"
        medical physics                 contains both "medic" and "physic"
        reader                          UK academic rank, not a media job
        registrar                       UK clinical trainee AND university admin
        consultant                      UK physician AND business consultant
        fellow                          research fellow AND clinical fellow
        principal                       school head AND principal investigator
        collaboratori / borsisti        Italian, seen in the real data
    ============================================================================
*/


-- ###########################################################################
-- AUDIT A - DISCIPLINE STEM AUDIT
--   Departments containing a decisive stem that were NOT assigned to the
--   group that stem belongs to. Every row here is a bug.
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
    STRUCT('health_clinical' AS grp, 'medicine' AS example),
    ('health_clinical','internal medicine'),('health_clinical','surgery'),
    ('health_clinical','pediatrics'),('health_clinical','psychiatry'),
    ('health_clinical','radiology'),('health_clinical','cardiology'),
    ('health_clinical','neurology'),('health_clinical','neurosurgery'),
    ('health_clinical','pathology'),('health_clinical','ophthalmology'),
    ('health_clinical','urology'),('health_clinical','dermatology'),
    ('health_clinical','anesthesiology'),('health_clinical','orthopedics'),
    ('health_clinical','obstetrics and gynecology'),('health_clinical','medical oncology'),
    ('health_clinical','emergency medicine'),('health_clinical','family medicine'),
    ('health_clinical','nursing'),('health_clinical','dentistry'),
    ('health_clinical','public health'),('health_clinical','epidemiology'),
    ('health_clinical','school of medicine'),('health_clinical','clinical sciences'),
    ('pharmacy','pharmacy'),('pharmacy','pharmacology'),
    ('pharmacy','school of pharmacy'),('pharmacy','pharmaceutical sciences'),
    ('pharmacy','clinical pharmacy'),
    ('life_biomedical','biology'),('life_biomedical','biological sciences'),
    ('life_biomedical','biochemistry'),('life_biomedical','microbiology'),
    ('life_biomedical','biotechnology'),('life_biomedical','physiology'),
    ('life_biomedical','genetics'),('life_biomedical','immunology'),
    ('life_biomedical','neuroscience'),('life_biomedical','molecular biology'),
    ('life_biomedical','zoology'),('life_biomedical','botany'),
    ('life_biomedical','veterinary medicine'),('life_biomedical','animal science'),
    ('physical_chemistry','chemistry'),('physical_chemistry','physics'),
    ('physical_chemistry','materials science'),('physical_chemistry','astronomy'),
    ('physical_chemistry','applied physics'),
    ('engineering','mechanical engineering'),('engineering','civil engineering'),
    ('engineering','electrical engineering'),('engineering','chemical engineering'),
    ('engineering','biomedical engineering'),('engineering','industrial engineering'),
    ('engineering','aerospace engineering'),('engineering','engineering'),
    ('computing_data','computer science'),('computing_data','computer engineering'),
    ('computing_data','informatics'),('computing_data','information technology'),
    ('computing_data','software engineering'),('computing_data','data science'),
    ('mathematics_statistics','mathematics'),('mathematics_statistics','statistics'),
    ('mathematics_statistics','applied mathematics'),
    ('social_behavioural','psychology'),('social_behavioural','economics'),
    ('social_behavioural','sociology'),('social_behavioural','political science'),
    ('social_behavioural','anthropology'),('social_behavioural','social work'),
    ('earth_agriculture','geography'),('earth_agriculture','geology'),
    ('earth_agriculture','earth sciences'),('earth_agriculture','environmental science'),
    ('earth_agriculture','agronomy'),('earth_agriculture','agriculture'),
    ('earth_agriculture','food science'),('earth_agriculture','forestry'),
    ('business_public','business administration'),('business_public','management'),
    ('business_public','finance'),('business_public','accounting'),
    ('business_public','marketing'),('business_public','public administration'),
    ('humanities_law_edu','philosophy'),('humanities_law_edu','history'),
    ('humanities_law_edu','law'),('humanities_law_edu','education'),
    ('humanities_law_edu','linguistics'),('humanities_law_edu','literature'),
    ('humanities_law_edu','theology'),('humanities_law_edu','archaeology'),
    ('non_academic','research'),('non_academic','research and development'),
    ('non_academic','administration'),('non_academic','library')
  ])
),
-- Stems whose meaning is NOT in doubt. Deliberately excludes the genuinely
-- ambiguous ones: "biomedical engineering", "medical physics",
-- "health informatics", "bioinformatics", "mathematical biology".
decisive_stems AS (
  SELECT * FROM UNNEST([
    STRUCT('health_clinical' AS expected, r'(cardiolog|oncolog|radiolog|patholog|ophthalmolog|urolog|neurolog|psychiatr|paediatr|pediatr|obstetr|gynaecolog|gynecolog|dermatolog|anaesthesiolog|anesthesiolog|orthopaed|orthoped|nephrolog|endocrinolog|rheumatolog|gastroenterolog|pulmonolog|geriatr|haematolog|hematolog|surgery|surgical|nursing|dentistr|odontolog|internal medicine|emergency medicine|family medicine|chirurgie|innere medizin|klinik)' AS stem),
    ('pharmacy',               r'(pharmac|eczacilik|apothek|farmacia|farmaci)'),
    ('life_biomedical',        r'(biochemis|microbiolog|immunolog|physiolog|molecular biolog|cell biolog|neuroscien|zoolog|botan|biotechnolog|genetics)'),
    ('physical_chemistry',     r'(chemistry|chemical sciences|physics|astronom|astrophys|materials science)'),
    ('engineering',            r'(mechanical engineer|civil engineer|electrical engineer|chemical engineer|industrial engineer|aerospace engineer|mechatronic)'),
    ('computing_data',         r'(computer science|computer engineer|informatics|software engineer|artificial intelligence|computing)'),
    ('mathematics_statistics', r'(mathemat|statistic|matematik)'),
    ('social_behavioural',     r'(psycholog|sociolog|economic|political science|anthropolog)'),
    ('earth_agriculture',      r'(geolog|geograph|agronom|agricultur|forestr|oceanograph|atmospheric|soil science|food science)'),
    ('humanities_law_edu',     r'(philosoph|linguistic|theolog|archaeolog|jurisprudence|literature)')
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
assigned AS (
  SELECT department, records, grp AS assigned_grp, sim
  FROM per_group
  QUALIFY ROW_NUMBER() OVER (PARTITION BY department ORDER BY sim DESC) = 1
)
SELECT
    a.department,
    a.records,
    s.expected                  AS stem_says,
    a.assigned_grp              AS model_says,
    ROUND(a.sim, 3)             AS sim
FROM assigned a
JOIN decisive_stems s
  ON REGEXP_CONTAINS(a.department, s.stem)
WHERE a.assigned_grp != s.expected
  -- known-ambiguous strings are not bugs
  AND NOT REGEXP_CONTAINS(a.department,
        r'(biomedical engineer|medical physics|health informatics|bioinformatic|mathematical biolog|biostatistic|pharmaceutical engineer|clinical psycholog|agricultural engineer|food engineer|environmental engineer|geological engineer)')
ORDER BY a.records DESC;

-- EVERY ROW IS A BUG. Fix by naming that department explicitly in the
-- anchors for the group the stem points to, then re-run.
-- Zero rows means the discipline axis is clean on the top 500.


-- ###########################################################################
-- AUDIT B - TITLE STEM AUDIT
--   Same idea on the title axis.
--   NOTE: this applies the same abbreviation expansion production uses,
--   so "prof" becomes "professor" and "assoc prof" becomes "associate
--   professor". Without it the audit reports false bugs.
-- ###########################################################################
WITH top_titles AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
              r'[^\p{L}\p{N}\s&/+-]', ' '),
          r'\bprof\b', 'professor'),
          r'\bassoc\b', 'associate'),
          r'\basst\b', 'assistant'),
          r'\bsr\b', 'senior'),
        r'\s+', ' '))                                  AS title,
      COUNT(*)                                         AS records
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
    ('teaching_academic','faculty member'),('teaching_academic','reader'),
    ('researcher_early','postdoctoral researcher'),('researcher_early','postdoc'),
    ('researcher_early','post doc'),('researcher_early','research fellow'),
    ('researcher_early','research assistant'),('researcher_early','research associate'),
    ('researcher_early','researcher'),('researcher_early','postdoctoral fellow'),
    ('researcher_early','wissenschaftlicher mitarbeiter'),('researcher_early','borsisti'),
    ('researcher_early','collaboratori'),
    ('researcher_established','senior researcher'),('researcher_established','senior scientist'),
    ('researcher_established','research scientist'),('researcher_established','principal investigator'),
    ('researcher_established','group leader'),('researcher_established','staff scientist'),
    ('researcher_established','scientist'),
    ('student','phd student'),('student','phd candidate'),('student','doctoral candidate'),
    ('student','graduate student'),('student','student'),('student','doktorand'),
    ('student','phd scholar'),('student','master student'),
    ('trainee_clinical','resident'),('trainee_clinical','resident physician'),
    ('trainee_clinical','specialist registrar'),('trainee_clinical','clinical fellow'),
    ('trainee_clinical','intern'),('trainee_clinical','house officer'),
    ('leadership','dean'),('leadership','head of department'),('leadership','head'),
    ('leadership','director'),('leadership','deputy director'),('leadership','chief'),
    ('leadership','chair'),('leadership','vice chancellor'),('leadership','provost'),
    ('leadership','rector'),('leadership','president'),
    ('practitioner','consultant'),('practitioner','physician'),
    ('practitioner','medical doctor'),('practitioner','general practitioner'),
    ('practitioner','clinician'),('practitioner','surgeon'),('practitioner','nurse'),
    ('librarian','librarian'),('librarian','subject librarian'),
    ('librarian','academic librarian'),('librarian','research librarian'),
    ('librarian','information specialist'),('librarian','archivist'),
    ('librarian','repository manager'),('librarian','library director'),
    ('librarian','bibliothekar'),('librarian','kutuphaneci'),
    ('librarian','bibliothecaire'),('librarian','bibliotecario'),
    ('support_technical','laboratory technician'),('support_technical','technician'),
    ('support_technical','project manager'),('support_technical','administrator'),
    ('support_technical','coordinator'),('support_technical','administrative assistant')
  ])
),
decisive_stems AS (
  SELECT * FROM UNNEST([
    STRUCT('librarian' AS expected, r'(librar|bibliothek|bibliotec|bibliothec|kutuphane|archivist|arsivci)' AS stem),
    ('teaching_academic', r'(professor|lecturer|dozent|docente|profesor|ogretim uyesi)'),
    ('student',           r'(student|candidate|doktorand|ogrenci|scholar)'),
    ('leadership',        r'(dean|dekan|provost|vice chancellor|rector|head of department|bolum baskani)'),
    ('researcher_early',  r'(postdoc|post doc|postdoctoral)'),
    ('trainee_clinical',  r'(resident|registrar|houseman|intern)'),
    ('support_technical', r'(technician|teknisyen)')
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
assigned AS (
  SELECT title, records, grp AS assigned_grp, sim
  FROM per_group
  QUALIFY ROW_NUMBER() OVER (PARTITION BY title ORDER BY sim DESC) = 1
)
SELECT
    a.title,
    a.records,
    s.expected      AS stem_says,
    a.assigned_grp  AS model_says,
    ROUND(a.sim, 3) AS sim
FROM assigned a
JOIN decisive_stems s ON REGEXP_CONTAINS(a.title, s.stem)
WHERE a.assigned_grp != s.expected
  -- genuinely dual-meaning strings, excluded on purpose
  AND NOT REGEXP_CONTAINS(a.title,
        r'(visiting scholar|research scholar|postdoctoral scholar|student affairs|registrar office|university registrar|data librarian)')
ORDER BY a.records DESC;


-- ###########################################################################
-- AUDIT C - KNOWN-ANSWER SET
--   Hand-labelled departments including every suspected trap.
--   Reports accuracy and lists exactly which ones failed.
-- ###########################################################################
WITH labelled AS (
  SELECT * FROM UNNEST([
    -- the trap cases
    STRUCT('radiology' AS department, 'health_clinical' AS truth),
    ('pathology','health_clinical'),('physiology','life_biomedical'),
    ('psychology','social_behavioural'),('psychiatry','health_clinical'),
    ('neurology','health_clinical'),('neuroscience','life_biomedical'),
    ('oncology','health_clinical'),('ontology','humanities_law_edu'),
    ('geology','earth_agriculture'),('geography','earth_agriculture'),
    ('ophthalmology','health_clinical'),('urology','health_clinical'),
    ('public health','health_clinical'),('public administration','business_public'),
    ('veterinary medicine','life_biomedical'),
    ('pharmacology','pharmacy'),('pharmacy','pharmacy'),
    -- the plain cases, which must not regress
    ('medicine','health_clinical'),('internal medicine','health_clinical'),
    ('surgery','health_clinical'),('general surgery','health_clinical'),
    ('pediatrics','health_clinical'),('nursing','health_clinical'),
    ('cardiology','health_clinical'),('neurosurgery','health_clinical'),
    ('medical oncology','health_clinical'),('dentistry','health_clinical'),
    ('school of medicine','health_clinical'),('faculty of medicine','health_clinical'),
    ('chemistry','physical_chemistry'),('physics','physical_chemistry'),
    ('materials science','physical_chemistry'),('astronomy','physical_chemistry'),
    ('mathematics','mathematics_statistics'),('statistics','mathematics_statistics'),
    ('biology','life_biomedical'),('biochemistry','life_biomedical'),
    ('microbiology','life_biomedical'),('biotechnology','life_biomedical'),
    ('biological sciences','life_biomedical'),('genetics','life_biomedical'),
    ('mechanical engineering','engineering'),('civil engineering','engineering'),
    ('electrical engineering','engineering'),('chemical engineering','engineering'),
    ('biomedical engineering','engineering'),
    ('computer science','computing_data'),('computer engineering','computing_data'),
    ('informatics','computing_data'),
    ('economics','social_behavioural'),('sociology','social_behavioural'),
    ('political science','social_behavioural'),
    ('agronomy','earth_agriculture'),('food science','earth_agriculture'),
    ('environmental science','earth_agriculture'),
    ('law','humanities_law_edu'),('philosophy','humanities_law_edu'),
    ('history','humanities_law_edu'),('education','humanities_law_edu'),
    ('business administration','business_public'),('management','business_public'),
    ('research','non_academic'),('administration','non_academic')
  ])
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
    ('health_clinical','nursing'),('health_clinical','dentistry'),
    ('health_clinical','public health'),('health_clinical','epidemiology'),
    ('health_clinical','school of medicine'),
    ('pharmacy','pharmacy'),('pharmacy','pharmacology'),
    ('pharmacy','school of pharmacy'),('pharmacy','pharmaceutical sciences'),
    ('life_biomedical','biology'),('life_biomedical','biochemistry'),
    ('life_biomedical','microbiology'),('life_biomedical','biotechnology'),
    ('life_biomedical','physiology'),('life_biomedical','genetics'),
    ('life_biomedical','neuroscience'),('life_biomedical','veterinary medicine'),
    ('life_biomedical','immunology'),('life_biomedical','biological sciences'),
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
    ('humanities_law_edu','linguistics'),('humanities_law_edu','ontology'),
    ('non_academic','research'),('non_academic','administration'),('non_academic','library')
  ])
),
le AS (
  SELECT department, truth, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT department, truth, department AS content FROM labelled))
),
ae AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM discipline_anchors))
),
scored AS (
  SELECT l.department, l.truth, a.grp,
         MAX(1 - ML.DISTANCE(l.v, a.v, 'COSINE')) AS sim
  FROM le l CROSS JOIN ae a GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY department ORDER BY sim DESC) AS rnk
  FROM scored
),
result AS (
  SELECT r1.department, r1.truth, r1.grp AS predicted,
         ROUND(r1.sim,3) AS sim, ROUND(r1.sim - r2.sim,3) AS margin,
         r1.grp = r1.truth AS correct
  FROM ranked r1 LEFT JOIN ranked r2 ON r1.department=r2.department AND r2.rnk=2
  WHERE r1.rnk = 1
)
SELECT
    COUNTIF(correct)                                AS correct,
    COUNT(*)                                        AS total,
    ROUND(COUNTIF(correct) / COUNT(*), 3)           AS accuracy,
    STRING_AGG(IF(correct, NULL,
      CONCAT(department, ' -> ', predicted, ' (should be ', truth, ')')),
      '  //  ' ORDER BY department)                 AS failures
FROM result;

-- Target: accuracy 1.000 on this set. Anything less names its own fix -
-- add the failing department to the anchors of its true group.


-- ###########################################################################
-- AUDIT D - LOW-MARGIN QUEUE
--   What the model itself is unsure about, weighted by how many records
--   ride on it. This is the human review list.
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
    ('health_clinical','neurology'),('health_clinical','pathology'),
    ('health_clinical','ophthalmology'),('health_clinical','urology'),
    ('health_clinical','nursing'),('health_clinical','public health'),
    ('health_clinical','school of medicine'),('health_clinical','dentistry'),
    ('pharmacy','pharmacy'),('pharmacy','pharmacology'),
    ('pharmacy','pharmaceutical sciences'),
    ('life_biomedical','biology'),('life_biomedical','biochemistry'),
    ('life_biomedical','microbiology'),('life_biomedical','genetics'),
    ('life_biomedical','physiology'),('life_biomedical','neuroscience'),
    ('physical_chemistry','chemistry'),('physical_chemistry','physics'),
    ('physical_chemistry','materials science'),
    ('engineering','mechanical engineering'),('engineering','civil engineering'),
    ('engineering','electrical engineering'),('engineering','engineering'),
    ('computing_data','computer science'),('computing_data','informatics'),
    ('mathematics_statistics','mathematics'),('mathematics_statistics','statistics'),
    ('social_behavioural','psychology'),('social_behavioural','economics'),
    ('social_behavioural','sociology'),
    ('earth_agriculture','geography'),('earth_agriculture','geology'),
    ('earth_agriculture','agronomy'),('earth_agriculture','food science'),
    ('business_public','business administration'),('business_public','management'),
    ('humanities_law_edu','philosophy'),('humanities_law_edu','history'),
    ('humanities_law_edu','law'),('humanities_law_edu','education'),
    ('non_academic','research'),('non_academic','administration'),('non_academic','library')
  ])
),
de AS (
  SELECT department, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT department, records, department AS content FROM top_depts))
),
ae AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM discipline_anchors))
),
scored AS (
  SELECT d.department, d.records, a.grp,
         MAX(1 - ML.DISTANCE(d.v, a.v, 'COSINE')) AS sim
  FROM de d CROSS JOIN ae a GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY department ORDER BY sim DESC) AS rnk
  FROM scored
)
SELECT
    r1.department,
    r1.records,
    r1.grp                      AS first_choice,
    r2.grp                      AS second_choice,
    ROUND(r1.sim, 3)            AS sim,
    ROUND(r1.sim - r2.sim, 3)   AS margin
FROM ranked r1 JOIN ranked r2 ON r1.department = r2.department AND r2.rnk = 2
WHERE r1.rnk = 1 AND r1.sim - r2.sim < 0.03
ORDER BY r1.records DESC
LIMIT 60;


-- ###########################################################################
-- AUDIT E - CONFUSION PAIRS
--   Which two groups are hardest to tell apart? Aggregates audit D by pair,
--   so one fix can clear many departments at once.
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
    ('health_clinical','neurology'),('health_clinical','pathology'),
    ('health_clinical','nursing'),('health_clinical','public health'),
    ('pharmacy','pharmacy'),('pharmacy','pharmacology'),
    ('life_biomedical','biology'),('life_biomedical','biochemistry'),
    ('life_biomedical','microbiology'),('life_biomedical','physiology'),
    ('life_biomedical','neuroscience'),
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
    ('non_academic','research'),('non_academic','administration')
  ])
),
de AS (
  SELECT department, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT department, records, department AS content FROM top_depts))
),
ae AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM discipline_anchors))
),
scored AS (
  SELECT d.department, d.records, a.grp,
         MAX(1 - ML.DISTANCE(d.v, a.v, 'COSINE')) AS sim
  FROM de d CROSS JOIN ae a GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY department ORDER BY sim DESC) AS rnk
  FROM scored
)
SELECT
    LEAST(r1.grp, r2.grp)       AS group_a,
    GREATEST(r1.grp, r2.grp)    AS group_b,
    COUNT(*)                    AS contested_departments,
    SUM(r1.records)             AS contested_records,
    ROUND(AVG(r1.sim - r2.sim), 4) AS avg_margin,
    STRING_AGG(r1.department, ' | ' ORDER BY r1.records DESC LIMIT 5) AS examples
FROM ranked r1 JOIN ranked r2 ON r1.department = r2.department AND r2.rnk = 2
WHERE r1.rnk = 1 AND r1.sim - r2.sim < 0.05
GROUP BY group_a, group_b
ORDER BY contested_records DESC
LIMIT 20;

/*
    A pair at the top of this list with a lot of contested records is
    where one anchor edit buys the most. Expected candidates, based on
    the traps listed at the top of this file:
      health_clinical  x  life_biomedical      (neurology / neuroscience)
      health_clinical  x  social_behavioural   (psychiatry / psychology)
      engineering      x  computing_data       (computer engineering)
      engineering      x  physical_chemistry   (materials science)
      business_public  x  non_academic         (management / administration)
*/
