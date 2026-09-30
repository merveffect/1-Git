/*
    ============================================================================
    WHERE DOES THE DISCIPLINE ACTUALLY LIVE?
    ============================================================================
    Test 05 produced a clear negative: assigning a DISCIPLINE from the job
    title fails. 73.5% of records were unassignable or ambiguous, and the
    groups that did win, won by noise-level margins (0.005 - 0.021).

    The reason is visible in the data itself. The most frequent ORCID
    titles are:

        assistant professor   2,513,601
        associate professor   1,715,550
        professor             1,480,748
        lecturer                903,050
        researcher              743,113
        research assistant      626,953
        postdoctoral researcher 604,970

    None of these say what FIELD the person works in. They say what rung
    of the academic ladder they are on. The POSITION axis worked for
    exactly this reason (margins 0.05 - 0.14, sensible groups).

    So: if the title carries position, the discipline must come from
    somewhere else. This query tests the obvious candidate - the
    DEPARTMENT field, backed by the ORGANISATION name.

    Self-contained. Paste and run.
    ============================================================================
*/


-- ###########################################################################
-- QUERY 1 - Do departments even look like disciplines?
-- Before embedding anything, just look at the most common values.
-- ###########################################################################
SELECT
    TRIM(REGEXP_REPLACE(
      REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.department_name, NFKC)),
        r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))     AS department,
    COUNT(*)                                            AS records,
    ROUND(SUM(COUNT(*)) OVER (ORDER BY COUNT(*) DESC)
          / SUM(COUNT(*)) OVER (), 4)                   AS cumulative_share
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.employments) e
WHERE r.snid IS NOT NULL
  AND UPPER(e.visibility) = 'PUBLIC'
  AND e.department_name IS NOT NULL AND TRIM(e.department_name) != ''
GROUP BY department
ORDER BY records DESC
LIMIT 60;

/*
    If these read like "department of cardiology", "school of law",
    "faculty of engineering" then the discipline is there and the
    embedding approach will work on this field. If they read like
    "research", "administration", "main campus" then it will not.
*/


-- ###########################################################################
-- QUERY 2 - Assign a DISCIPLINE from the department, the same way test 05
--           tried to do it from the title. Compare the margins.
-- ###########################################################################
WITH top_depts AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.department_name, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))   AS department,
      COUNT(*)                                          AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.department_name IS NOT NULL AND TRIM(e.department_name) != ''
  GROUP BY department ORDER BY records DESC LIMIT 300
),

-- Anchors written as DEPARTMENT names, not job titles. This matters:
-- we are embedding department text, so the anchors must look like
-- department text.
discipline_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('health_clinical' AS grp, 'department of medicine' AS example),
    ('health_clinical','department of cardiology'),('health_clinical','department of surgery'),
    ('health_clinical','school of nursing'),('health_clinical','faculty of medicine'),
    ('health_clinical','department of paediatrics'),('health_clinical','klinik fur innere medizin'),

    ('pharmacy','school of pharmacy'),('pharmacy','department of pharmaceutical sciences'),
    ('pharmacy','faculty of pharmacy'),

    ('veterinary','school of veterinary medicine'),('veterinary','faculty of veterinary science'),

    ('life_biomedical','department of biology'),('life_biomedical','department of biochemistry'),
    ('life_biomedical','department of molecular biology'),('life_biomedical','institute of genetics'),
    ('life_biomedical','department of neuroscience'),('life_biomedical','school of life sciences'),

    ('physical_chemistry','department of physics'),('physical_chemistry','department of chemistry'),
    ('physical_chemistry','institute of astronomy'),('physical_chemistry','school of physical sciences'),
    ('physical_chemistry','department of materials science'),

    ('mathematics_statistics','department of mathematics'),('mathematics_statistics','department of statistics'),
    ('mathematics_statistics','school of mathematical sciences'),

    ('engineering','department of mechanical engineering'),('engineering','department of civil engineering'),
    ('engineering','faculty of engineering'),('engineering','department of electrical engineering'),

    ('computing_data','department of computer science'),('computing_data','school of computing'),
    ('computing_data','department of informatics'),('computing_data','institute of data science'),

    ('earth_environment','department of geology'),('earth_environment','school of environmental sciences'),
    ('earth_environment','department of earth sciences'),('earth_environment','institute of oceanography'),

    ('agriculture_food','faculty of agriculture'),('agriculture_food','department of food science'),
    ('agriculture_food','school of agricultural sciences'),

    ('social_behavioural','department of psychology'),('social_behavioural','department of economics'),
    ('social_behavioural','department of sociology'),('social_behavioural','school of social sciences'),
    ('social_behavioural','department of political science'),

    ('humanities_arts','department of history'),('humanities_arts','department of philosophy'),
    ('humanities_arts','department of linguistics'),('humanities_arts','faculty of arts'),
    ('humanities_arts','school of humanities'),

    ('law','school of law'),('law','faculty of law'),('law','department of legal studies'),

    ('business_management','business school'),('business_management','department of management'),
    ('business_management','school of business administration'),('business_management','department of finance'),

    ('education_teaching','school of education'),('education_teaching','faculty of education'),
    ('education_teaching','department of educational sciences'),

    ('library_information','university library'),('library_information','library services'),
    ('library_information','department of information science'),('library_information','archives'),

    ('public_administration','school of public health'),('public_administration','department of public policy'),
    ('public_administration','institute of public administration'),

    ('non_academic_unit','human resources'),('non_academic_unit','finance department'),
    ('non_academic_unit','it services'),('non_academic_unit','research office'),
    ('non_academic_unit','administration')
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
  FROM dept_emb d CROSS JOIN anchor_emb a
  GROUP BY 1,2,3
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
    ROUND(AVG(sim), 3)                                  AS avg_similarity,
    ROUND(AVG(margin), 3)                               AS avg_margin,
    STRING_AGG(department, ' | ' ORDER BY records DESC LIMIT 4) AS sample_departments
FROM assigned
GROUP BY discipline
ORDER BY records DESC;

/*
    THE COMPARISON THAT MATTERS

    Test 05, discipline from TITLE:
        avg_margin 0.001 - 0.145, most groups under 0.02
        73.5% of records unassignable or ambiguous

    If this query returns margins in the 0.05 - 0.15 range across most
    groups, the discipline lives in the department and the two-axis model
    works - with each axis read from the field that actually carries it.
*/


-- ###########################################################################
-- QUERY 3 - Coverage reality check
--           Department is only populated on 78.5% of records. How many
--           people have NO discipline signal anywhere?
-- ###########################################################################
WITH emp AS (
  SELECT
      r.snid,
      e.department_name,
      e.organisation_name
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
)
SELECT
    COUNT(*)                                                        AS records,
    COUNT(DISTINCT snid)                                            AS people,
    COUNTIF(department_name IS NOT NULL)                            AS has_department,
    COUNTIF(department_name IS NULL)                                AS no_department,
    ROUND(COUNTIF(department_name IS NULL) / COUNT(*), 4)           AS no_department_rate,
    -- organisation is always populated, so it is the last resort
    COUNTIF(department_name IS NULL AND organisation_name IS NOT NULL) AS org_only
FROM emp;


-- ###########################################################################
-- QUERY 4 - The combination that decides the design
--           For each POSITION group from the title, how often is there a
--           usable discipline signal alongside it?
-- ###########################################################################
WITH emp AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))   AS title,
      e.department_name                                 AS dept
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
)
SELECT
    CASE
      WHEN REGEXP_CONTAINS(title, r'\b(professor|prof|lecturer|dozent|docent|docente)\b') THEN 'teaching_academic'
      WHEN REGEXP_CONTAINS(title, r'\b(postdoc|post doc|research fellow|research assistant|research associate|researcher)\b') THEN 'researcher'
      WHEN REGEXP_CONTAINS(title, r'\b(student|candidate|doktorand)\b') THEN 'student'
      WHEN REGEXP_CONTAINS(title, r'\b(dean|head|director|chief|chair)\b') THEN 'leadership'
      WHEN REGEXP_CONTAINS(title, r'\b(resident|registrar|intern|fellow)\b') THEN 'trainee'
      ELSE 'other'
    END                                                             AS position_group,
    COUNT(*)                                                        AS records,
    ROUND(COUNTIF(dept IS NOT NULL) / COUNT(*), 4)                  AS has_department_rate
FROM emp
GROUP BY position_group
ORDER BY records DESC;

/*
    If the big position groups also carry a department most of the time,
    the two-axis model is viable end to end: position from the title,
    discipline from the department, and the five target roles expressed
    as a combination of the two.
*/
