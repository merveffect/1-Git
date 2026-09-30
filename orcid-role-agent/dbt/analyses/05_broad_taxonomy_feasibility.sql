/*
    ============================================================================
    FEASIBILITY TEST - MAPPING EVERY ORCID TITLE TO A BROAD OCCUPATION GROUP
    ============================================================================
    Question: instead of matching titles only against our 5 target roles,
    can we assign EVERY distinct ORCID title to one of ~18 standardised
    occupation groups, with the 5 target roles falling out of that?

    This query answers it on the 300 most frequent real titles, which is
    enough to see whether the idea holds. Self-contained: paste and run,
    no dbt models needed.

    TWO AXES, because our roles do not sit on one.
      DISCIPLINE  what field the person works in   (18 groups, ISCO-08 aligned)
      POSITION    what kind of post they hold      (8 groups)

    Our five roles then become queries over those axes:
      hcp           discipline in (health_clinical, pharmacy)
      pharmacist    discipline = pharmacy
      librarian     discipline = library_information
      researcher    position in (researcher_early, researcher_established)
                    -- ANY discipline, which is what we actually wanted
      faculty_head  position = leadership AND discipline is academic

    QUERY 1  assign titles to DISCIPLINE, show the distribution
    QUERY 2  sample titles per group - eyeball the quality
    QUERY 3  assign titles to POSITION
    QUERY 4  how much falls through: low margin / unassignable
    ============================================================================
*/


-- ###########################################################################
-- QUERY 1 - DISCIPLINE assignment across the top 300 titles
-- ###########################################################################
WITH top_titles AS (
  SELECT
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' '))  AS title,
      COUNT(*)                                          AS records
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
  UNNEST(r.employments) e
  WHERE r.snid IS NOT NULL
    AND UPPER(e.visibility) = 'PUBLIC'
    AND e.role IS NOT NULL AND TRIM(e.role) != ''
  GROUP BY title
  ORDER BY records DESC
  LIMIT 300
),

-- Candidate taxonomy. Several example titles per group, because a bare
-- label embeds badly against real job titles.
discipline_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('health_clinical' AS grp, 'physician' AS example),
    ('health_clinical','consultant cardiologist'),('health_clinical','registered nurse'),
    ('health_clinical','surgeon'),('health_clinical','dentist'),('health_clinical','physiotherapist'),
    ('health_clinical','arzt'),('health_clinical','medecin'),

    ('pharmacy','pharmacist'),('pharmacy','hospital pharmacist'),
    ('pharmacy','clinical pharmacist'),('pharmacy','apotheker'),('pharmacy','eczaci'),

    ('veterinary','veterinarian'),('veterinary','veterinary surgeon'),('veterinary','tierarzt'),

    ('life_biomedical','molecular biologist'),('life_biomedical','biochemist'),
    ('life_biomedical','geneticist'),('life_biomedical','microbiologist'),
    ('life_biomedical','neuroscientist'),('life_biomedical','immunologist'),

    ('physical_chemistry','physicist'),('physical_chemistry','chemist'),
    ('physical_chemistry','astronomer'),('physical_chemistry','materials scientist'),

    ('mathematics_statistics','mathematician'),('mathematics_statistics','statistician'),
    ('mathematics_statistics','biostatistician'),

    ('engineering','mechanical engineer'),('engineering','civil engineer'),
    ('engineering','electrical engineer'),('engineering','chemical engineer'),
    ('engineering','ingenieur'),

    ('computing_data','software engineer'),('computing_data','data scientist'),
    ('computing_data','computer scientist'),('computing_data','machine learning engineer'),
    ('computing_data','bioinformatician'),

    ('earth_environment','geologist'),('earth_environment','climate scientist'),
    ('earth_environment','ecologist'),('earth_environment','oceanographer'),

    ('agriculture_food','agronomist'),('agriculture_food','food scientist'),
    ('agriculture_food','soil scientist'),

    ('social_behavioural','psychologist'),('social_behavioural','economist'),
    ('social_behavioural','sociologist'),('social_behavioural','political scientist'),
    ('social_behavioural','anthropologist'),

    ('humanities_arts','historian'),('humanities_arts','philosopher'),
    ('humanities_arts','linguist'),('humanities_arts','literary scholar'),
    ('humanities_arts','archaeologist'),('humanities_arts','musician'),

    ('law','lawyer'),('law','legal scholar'),('law','attorney'),('law','patent attorney'),

    ('business_management','marketing manager'),('business_management','financial analyst'),
    ('business_management','accountant'),('business_management','human resources manager'),
    ('business_management','management consultant'),

    ('education_teaching','school teacher'),('education_teaching','primary school teacher'),
    ('education_teaching','education specialist'),

    ('library_information','librarian'),('library_information','subject librarian'),
    ('library_information','archivist'),('library_information','repository manager'),
    ('library_information','information specialist'),('library_information','kutuphaneci'),

    ('public_administration','civil servant'),('public_administration','policy advisor'),
    ('public_administration','public health officer'),

    ('technical_support','laboratory technician'),('technical_support','research technician'),
    ('technical_support','it support specialist'),

    ('communication_media','journalist'),('communication_media','science writer'),
    ('communication_media','editor'),('communication_media','translator')
  ])
),

title_emb AS (
  SELECT title, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT title, records, title AS content FROM top_titles))
),
anchor_emb AS (
  SELECT grp, example, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM discipline_anchors))
),
per_group AS (
  SELECT
      t.title, t.records, a.grp,
      MAX(1 - ML.DISTANCE(t.v, a.v, 'COSINE')) AS sim
  FROM title_emb t CROSS JOIN anchor_emb a
  GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY title ORDER BY sim DESC) AS rnk
  FROM per_group
),
assigned AS (
  SELECT
      r1.title, r1.records,
      r1.grp                       AS discipline,
      ROUND(r1.sim, 3)             AS best_sim,
      ROUND(r1.sim - r2.sim, 3)    AS margin
  FROM ranked r1
  LEFT JOIN ranked r2 ON r1.title = r2.title AND r2.rnk = 2
  WHERE r1.rnk = 1
)
SELECT
    discipline,
    COUNT(*)                                        AS titles,
    SUM(records)                                    AS records,
    ROUND(SUM(records) / SUM(SUM(records)) OVER (), 4) AS share_of_records,
    ROUND(AVG(best_sim), 3)                         AS avg_similarity,
    ROUND(AVG(margin), 3)                           AS avg_margin,
    COUNTIF(margin < 0.03)                          AS weak_margin_titles
FROM assigned
GROUP BY discipline
ORDER BY records DESC;

/*
    WHAT TO LOOK FOR
      - Is every group populated, or do some never win? An empty group is
        either missing from ORCID or its anchors are too weak.
      - avg_margin tells you how decisive the assignment is. Low margin
        across a group means it overlaps with its neighbour.
      - weak_margin_titles is the size of the genuinely ambiguous band.
*/


-- ###########################################################################
-- QUERY 2 - SAMPLE: the 5 most frequent titles assigned to each group
-- This is the eyeball test. If these read wrong, the idea fails here.
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
  GROUP BY title ORDER BY records DESC LIMIT 300
),
discipline_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('health_clinical' AS grp, 'physician' AS example),
    ('health_clinical','consultant cardiologist'),('health_clinical','registered nurse'),
    ('health_clinical','surgeon'),('health_clinical','dentist'),('health_clinical','arzt'),
    ('pharmacy','pharmacist'),('pharmacy','hospital pharmacist'),('pharmacy','apotheker'),
    ('veterinary','veterinarian'),('veterinary','tierarzt'),
    ('life_biomedical','molecular biologist'),('life_biomedical','biochemist'),
    ('life_biomedical','geneticist'),('life_biomedical','neuroscientist'),
    ('physical_chemistry','physicist'),('physical_chemistry','chemist'),
    ('physical_chemistry','astronomer'),
    ('mathematics_statistics','mathematician'),('mathematics_statistics','statistician'),
    ('engineering','mechanical engineer'),('engineering','civil engineer'),
    ('engineering','electrical engineer'),
    ('computing_data','software engineer'),('computing_data','data scientist'),
    ('computing_data','computer scientist'),('computing_data','bioinformatician'),
    ('earth_environment','geologist'),('earth_environment','climate scientist'),
    ('earth_environment','ecologist'),
    ('agriculture_food','agronomist'),('agriculture_food','food scientist'),
    ('social_behavioural','psychologist'),('social_behavioural','economist'),
    ('social_behavioural','sociologist'),('social_behavioural','political scientist'),
    ('humanities_arts','historian'),('humanities_arts','philosopher'),
    ('humanities_arts','linguist'),('humanities_arts','archaeologist'),
    ('law','lawyer'),('law','legal scholar'),
    ('business_management','marketing manager'),('business_management','accountant'),
    ('business_management','human resources manager'),
    ('education_teaching','school teacher'),('education_teaching','primary school teacher'),
    ('library_information','librarian'),('library_information','archivist'),
    ('library_information','information specialist'),
    ('public_administration','civil servant'),('public_administration','policy advisor'),
    ('technical_support','laboratory technician'),('technical_support','research technician'),
    ('communication_media','journalist'),('communication_media','editor')
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
    (SELECT grp, example, example AS content FROM discipline_anchors))
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
  SELECT r1.title, r1.records, r1.grp AS discipline,
         ROUND(r1.sim,3) AS sim, ROUND(r1.sim - r2.sim,3) AS margin
  FROM ranked r1 LEFT JOIN ranked r2 ON r1.title=r2.title AND r2.rnk=2
  WHERE r1.rnk = 1
)
SELECT discipline, title, records, sim, margin
FROM assigned
QUALIFY ROW_NUMBER() OVER (PARTITION BY discipline ORDER BY records DESC) <= 5
ORDER BY discipline, records DESC;


-- ###########################################################################
-- QUERY 3 - POSITION axis: what KIND of post, independent of field
-- This is the axis "researcher" and "faculty_head" actually live on.
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
  GROUP BY title ORDER BY records DESC LIMIT 300
),
position_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('student' AS grp, 'phd student' AS example),
    ('student','doctoral candidate'),('student','graduate student'),
    ('student','undergraduate student'),('student','doktorand'),

    ('trainee_clinical','resident physician'),('trainee_clinical','specialist registrar'),
    ('trainee_clinical','clinical fellow'),('trainee_clinical','intern'),

    ('researcher_early','postdoctoral researcher'),('researcher_early','research associate'),
    ('researcher_early','research assistant'),('researcher_early','postdoctoral fellow'),
    ('researcher_early','wissenschaftlicher mitarbeiter'),

    ('researcher_established','principal investigator'),('researcher_established','senior research scientist'),
    ('researcher_established','group leader'),('researcher_established','research director'),
    ('researcher_established','staff scientist'),

    ('teaching_academic','professor'),('teaching_academic','associate professor'),
    ('teaching_academic','assistant professor'),('teaching_academic','senior lecturer'),
    ('teaching_academic','lecturer'),('teaching_academic','dozent'),

    ('leadership','dean'),('leadership','head of department'),
    ('leadership','director of institute'),('leadership','chief executive officer'),
    ('leadership','vice chancellor'),('leadership','chief medical officer'),

    ('practitioner','general practitioner'),('practitioner','consultant physician'),
    ('practitioner','community pharmacist'),('practitioner','practising solicitor'),

    ('support_technical','laboratory technician'),('support_technical','administrative assistant'),
    ('support_technical','project coordinator'),('support_technical','research manager')
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
    (SELECT grp, example, example AS content FROM position_anchors))
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
  SELECT r1.title, r1.records, r1.grp AS position_group,
         ROUND(r1.sim,3) AS sim, ROUND(r1.sim - r2.sim,3) AS margin
  FROM ranked r1 LEFT JOIN ranked r2 ON r1.title=r2.title AND r2.rnk=2
  WHERE r1.rnk = 1
)
SELECT
    position_group,
    COUNT(*)                                            AS titles,
    SUM(records)                                        AS records,
    ROUND(SUM(records) / SUM(SUM(records)) OVER (), 4)  AS share_of_records,
    ROUND(AVG(margin), 3)                               AS avg_margin,
    STRING_AGG(title, ' | ' ORDER BY records DESC LIMIT 4) AS sample_titles
FROM assigned
GROUP BY position_group
ORDER BY records DESC;


-- ###########################################################################
-- QUERY 4 - THE HONEST CHECK: how much does NOT fit anywhere?
-- A taxonomy is only useful if the leftover bucket is small.
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
  GROUP BY title ORDER BY records DESC LIMIT 300
),
discipline_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('health_clinical' AS grp, 'physician' AS example),
    ('health_clinical','consultant cardiologist'),('health_clinical','registered nurse'),
    ('pharmacy','pharmacist'),('veterinary','veterinarian'),
    ('life_biomedical','molecular biologist'),('life_biomedical','biochemist'),
    ('physical_chemistry','physicist'),('physical_chemistry','chemist'),
    ('mathematics_statistics','mathematician'),('mathematics_statistics','statistician'),
    ('engineering','mechanical engineer'),('engineering','civil engineer'),
    ('computing_data','software engineer'),('computing_data','data scientist'),
    ('earth_environment','geologist'),('earth_environment','ecologist'),
    ('agriculture_food','agronomist'),
    ('social_behavioural','psychologist'),('social_behavioural','economist'),
    ('humanities_arts','historian'),('humanities_arts','linguist'),
    ('law','lawyer'),
    ('business_management','marketing manager'),('business_management','accountant'),
    ('education_teaching','school teacher'),
    ('library_information','librarian'),('library_information','archivist'),
    ('public_administration','civil servant'),
    ('technical_support','laboratory technician'),
    ('communication_media','journalist')
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
    (SELECT grp, example, example AS content FROM discipline_anchors))
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
  SELECT r1.title, r1.records, r1.grp,
         r1.sim, r1.sim - r2.sim AS margin
  FROM ranked r1 LEFT JOIN ranked r2 ON r1.title=r2.title AND r2.rnk=2
  WHERE r1.rnk = 1
)
SELECT
    CASE
      WHEN margin >= 0.06 THEN 'confident'
      WHEN margin >= 0.03 THEN 'usable'
      WHEN margin >= 0.01 THEN 'ambiguous - two groups nearly tied'
      ELSE 'unassignable - generic title'
    END                                                 AS verdict,
    COUNT(*)                                            AS titles,
    SUM(records)                                        AS records,
    ROUND(SUM(records) / SUM(SUM(records)) OVER (), 4)  AS share_of_records,
    STRING_AGG(title, ' | ' ORDER BY records DESC LIMIT 6) AS examples
FROM assigned
GROUP BY verdict
ORDER BY records DESC;

/*
    DECIDING

    If 'confident' + 'usable' covers most records, the broad taxonomy
    works and should replace the 5-role anchor set: the non-target groups
    become the distractors automatically, and no hand-maintained list of
    "things that are not our roles" is needed any more.

    If the leftover is large, look at the examples: they will be generic
    titles like "professor" or "director" that carry a POSITION but no
    DISCIPLINE. That is expected and is exactly why there are two axes -
    such a title should get a position group and no discipline, with the
    discipline supplied by the department or organisation instead.
*/
