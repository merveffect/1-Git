/*
    ============================================================================
    DISCIPLINE v3 - FIXING WHAT AUDIT A FOUND
    ============================================================================
    Audit A returned 22 rows. Sorting them:

    REAL BUGS  (~58,000 records)
      hematology                          -> life_biomedical, is clinical
      endocrinology                       -> pharmacy,        is clinical
      school of chemistry                 -> pharmacy,        is chemistry
      department of chemistry and biochemistry -> pharmacy,   is chemistry
      applied economics                   -> mathematics,     is economics

      The pattern behind four of these: PHARMACY IS OVER-ATTRACTING
      CHEMISTRY. The anchor "pharmaceutical sciences" sits close to
      general chemistry in the embedding space and pulls chemistry
      departments in. Fixed by giving physical_chemistry stronger,
      more specific anchors rather than by weakening pharmacy.

    FALSE ALARMS - my audit regex was too greedy, the model was right
      biochemistry            stem "chemistry" fired; it is a life science
      geophysics              stem "physics" fired; it is an earth science
      medicinal chemistry     genuinely pharmacy
      pharmaceutical chemistry genuinely pharmacy
      RE2 has no lookbehind, so these are handled in the exclusion list.

    GENUINELY DUAL - a department really is two disciplines
      electrical and computer engineering
      mathematics and computer science
      chemistry and chemical engineering
      chemistry and biochemistry
      agricultural economics
      Single-label assignment cannot be right here by construction. Noted
      for later; it does not affect our roles, which only need health and
      pharmacy separated cleanly.

    THREE QUERIES
      1  audit A rerun with v3 anchors and corrected exclusions
      2  known-answer set extended with every trap found so far
      3  discipline distribution with v3 anchors - check nothing regressed
    ============================================================================
*/


-- ###########################################################################
-- Shared v3 anchor set. Additions over v2 are marked.
-- ###########################################################################
-- health_clinical gains the specialties audit A exposed:
--   hematology, endocrinology, rheumatology, nephrology, gastroenterology,
--   pulmonology, hepatology, infectious diseases, intensive care, geriatrics
-- physical_chemistry gains school/faculty forms so chemistry stops losing
--   to pharmacy: school of chemistry, chemical sciences, chemistry and
--   biochemistry, analytical chemistry, inorganic chemistry
-- social_behavioural gains applied and agricultural economics


-- ###########################################################################
-- QUERY 1 - AUDIT A RERUN
--   Zero rows means the discipline axis is clean on the top 500.
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
  GROUP BY department
  HAVING LENGTH(department) BETWEEN 2 AND 200
  ORDER BY records DESC LIMIT 500
),
discipline_anchors AS (
  SELECT * FROM UNNEST([
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
    ('health_clinical','dentistry'),('health_clinical','public health'),
    ('health_clinical','epidemiology'),('health_clinical','school of medicine'),
    ('health_clinical','faculty of medicine'),('health_clinical','clinical sciences'),
    -- v3: specialties audit A found landing in the wrong group
    ('health_clinical','hematology'),('health_clinical','haematology'),
    ('health_clinical','endocrinology'),('health_clinical','rheumatology'),
    ('health_clinical','nephrology'),('health_clinical','gastroenterology'),
    ('health_clinical','pulmonology'),('health_clinical','hepatology'),
    ('health_clinical','infectious diseases'),('health_clinical','intensive care'),
    ('health_clinical','geriatrics'),('health_clinical','clinical oncology'),

    ('pharmacy','pharmacy'),('pharmacy','pharmacology'),
    ('pharmacy','school of pharmacy'),('pharmacy','faculty of pharmacy'),
    ('pharmacy','department of pharmacy'),('pharmacy','pharmaceutics'),
    ('pharmacy','clinical pharmacy'),('pharmacy','pharmaceutical sciences'),
    ('pharmacy','medicinal chemistry'),('pharmacy','pharmaceutical chemistry'),

    ('life_biomedical','biology'),('life_biomedical','biological sciences'),
    ('life_biomedical','biochemistry'),('life_biomedical','microbiology'),
    ('life_biomedical','biotechnology'),('life_biomedical','physiology'),
    ('life_biomedical','molecular biology'),('life_biomedical','genetics'),
    ('life_biomedical','cell biology'),('life_biomedical','immunology'),
    ('life_biomedical','neuroscience'),('life_biomedical','zoology'),
    ('life_biomedical','botany'),('life_biomedical','veterinary medicine'),
    ('life_biomedical','animal science'),('life_biomedical','life sciences'),
    ('life_biomedical','biochemistry and molecular biology'),

    -- v3: stronger, more specific chemistry so it stops losing to pharmacy
    ('physical_chemistry','chemistry'),('physical_chemistry','school of chemistry'),
    ('physical_chemistry','chemical sciences'),('physical_chemistry','analytical chemistry'),
    ('physical_chemistry','inorganic chemistry'),('physical_chemistry','organic chemistry'),
    ('physical_chemistry','physical chemistry'),('physical_chemistry','chemistry and biochemistry'),
    ('physical_chemistry','physics'),('physical_chemistry','applied physics'),
    ('physical_chemistry','physics and astronomy'),('physical_chemistry','astronomy'),
    ('physical_chemistry','materials science'),

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
    ('mathematics_statistics','mathematics and statistics'),
    ('mathematics_statistics','biostatistics'),

    ('social_behavioural','psychology'),('social_behavioural','economics'),
    ('social_behavioural','sociology'),('social_behavioural','political science'),
    ('social_behavioural','anthropology'),('social_behavioural','social sciences'),
    ('social_behavioural','social work'),('social_behavioural','communication'),
    -- v3
    ('social_behavioural','applied economics'),('social_behavioural','agricultural economics'),
    ('social_behavioural','econometrics'),

    ('earth_agriculture','geography'),('earth_agriculture','geology'),
    ('earth_agriculture','earth sciences'),('earth_agriculture','geophysics'),
    ('earth_agriculture','environmental science'),('earth_agriculture','agronomy'),
    ('earth_agriculture','agriculture'),('earth_agriculture','food science'),
    ('earth_agriculture','food engineering'),('earth_agriculture','horticulture'),
    ('earth_agriculture','forestry'),('earth_agriculture','soil science'),
    ('earth_agriculture','marine science'),('earth_agriculture','atmospheric science'),

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
    ('non_academic','information technology services'),('non_academic','library')
  ])
),
decisive_stems AS (
  SELECT * FROM UNNEST([
    STRUCT('health_clinical' AS expected, r'(cardiolog|oncolog|radiolog|patholog|ophthalmolog|urolog|neurolog|psychiatr|paediatr|pediatr|obstetr|gynaecolog|gynecolog|dermatolog|anaesthesiolog|anesthesiolog|orthopaed|orthoped|nephrolog|endocrinolog|rheumatolog|gastroenterolog|pulmonolog|geriatr|haematolog|hematolog|hepatolog|surgery|surgical|nursing|dentistr|odontolog|internal medicine|emergency medicine|family medicine|intensive care)' AS stem),
    ('pharmacy',               r'(pharmacy|pharmacolog|pharmaceutic|eczacilik|apothek|farmacia)'),
    ('life_biomedical',        r'(biochemis|microbiolog|immunolog|physiolog|molecular biolog|cell biolog|neuroscien|zoolog|botan|biotechnolog|genetics)'),
    ('physical_chemistry',     r'(materials science|astronom|astrophys)'),
    ('engineering',            r'(mechanical engineer|civil engineer|chemical engineer|industrial engineer|aerospace engineer|mechatronic)'),
    ('computing_data',         r'(informatics|software engineer|artificial intelligence)'),
    ('mathematics_statistics', r'(mathemat|statistic|matematik)'),
    ('social_behavioural',     r'(psycholog|sociolog|political science|anthropolog|econom)'),
    ('earth_agriculture',      r'(geolog|geograph|geophys|agronom|agricultur|forestr|oceanograph|atmospheric|soil science|food science)'),
    ('humanities_law_edu',     r'(philosoph|linguistic|theolog|archaeolog|jurisprudence|literature)')
  ])
),
de AS (
  SELECT department, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT department, records, department AS content FROM top_depts))
  WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
),
ae AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM discipline_anchors))
  WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
),
assigned AS (
  SELECT department, records, grp AS assigned_grp, sim FROM (
    SELECT d.department, d.records, a.grp,
           MAX(1 - ML.DISTANCE(d.v, a.v, 'COSINE')) AS sim
    FROM de d CROSS JOIN ae a GROUP BY 1,2,3
  ) QUALIFY ROW_NUMBER() OVER (PARTITION BY department ORDER BY sim DESC) = 1
)
SELECT
    a.department, a.records,
    s.expected      AS stem_says,
    a.assigned_grp  AS model_says,
    ROUND(a.sim, 3) AS sim
FROM assigned a
JOIN decisive_stems s ON REGEXP_CONTAINS(a.department, s.stem)
WHERE a.assigned_grp != s.expected
  -- RE2 has no lookbehind, so greedy-stem false alarms are excluded here
  AND NOT REGEXP_CONTAINS(a.department,
        r'(biochemis|geophys|medicinal chemis|pharmaceutical chemis|biostatistic|bioinformatic|mathematical biolog)')
  -- genuinely dual departments: single-label assignment cannot be right
  AND NOT REGEXP_CONTAINS(a.department,
        r'( and computer|computer science and|and chemical engineer|chemistry and biochem|agricultural econom|and molecular biolog|and environmental engineer|and astronomy|and statistics)')
  -- known-ambiguous
  AND NOT REGEXP_CONTAINS(a.department,
        r'(biomedical engineer|medical physics|health informatics|clinical psycholog|agricultural engineer|food engineer|environmental engineer|geological engineer)')
ORDER BY a.records DESC;


-- ###########################################################################
-- QUERY 2 - KNOWN-ANSWER SET, extended with every trap found so far
-- ###########################################################################
WITH labelled AS (
  SELECT * FROM UNNEST([
    -- traps from audit A
    STRUCT('hematology' AS department, 'health_clinical' AS truth),
    ('endocrinology','health_clinical'),('rheumatology','health_clinical'),
    ('nephrology','health_clinical'),('gastroenterology','health_clinical'),
    ('school of chemistry','physical_chemistry'),
    ('applied economics','social_behavioural'),
    ('biochemistry','life_biomedical'),('geophysics','earth_agriculture'),
    ('medicinal chemistry','pharmacy'),('pharmaceutical chemistry','pharmacy'),
    -- traps from the earlier audit
    ('radiology','health_clinical'),('pathology','health_clinical'),
    ('physiology','life_biomedical'),('psychology','social_behavioural'),
    ('psychiatry','health_clinical'),('neurology','health_clinical'),
    ('neuroscience','life_biomedical'),('ophthalmology','health_clinical'),
    ('urology','health_clinical'),('public health','health_clinical'),
    ('public administration','business_public'),
    ('veterinary medicine','life_biomedical'),('pharmacology','pharmacy'),
    ('geology','earth_agriculture'),('geography','earth_agriculture'),
    -- plain cases that must not regress
    ('medicine','health_clinical'),('internal medicine','health_clinical'),
    ('surgery','health_clinical'),('pediatrics','health_clinical'),
    ('nursing','health_clinical'),('cardiology','health_clinical'),
    ('dentistry','health_clinical'),('pharmacy','pharmacy'),
    ('chemistry','physical_chemistry'),('physics','physical_chemistry'),
    ('materials science','physical_chemistry'),('astronomy','physical_chemistry'),
    ('mathematics','mathematics_statistics'),('statistics','mathematics_statistics'),
    ('biology','life_biomedical'),('microbiology','life_biomedical'),
    ('biotechnology','life_biomedical'),('genetics','life_biomedical'),
    ('mechanical engineering','engineering'),('civil engineering','engineering'),
    ('electrical engineering','engineering'),('chemical engineering','engineering'),
    ('computer science','computing_data'),('informatics','computing_data'),
    ('economics','social_behavioural'),('sociology','social_behavioural'),
    ('agronomy','earth_agriculture'),('food science','earth_agriculture'),
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
    ('health_clinical','neurology'),('health_clinical','pathology'),
    ('health_clinical','ophthalmology'),('health_clinical','urology'),
    ('health_clinical','nursing'),('health_clinical','dentistry'),
    ('health_clinical','public health'),('health_clinical','epidemiology'),
    ('health_clinical','school of medicine'),('health_clinical','hematology'),
    ('health_clinical','endocrinology'),('health_clinical','rheumatology'),
    ('health_clinical','nephrology'),('health_clinical','gastroenterology'),
    ('health_clinical','geriatrics'),('health_clinical','intensive care'),
    ('pharmacy','pharmacy'),('pharmacy','pharmacology'),
    ('pharmacy','school of pharmacy'),('pharmacy','pharmaceutical sciences'),
    ('pharmacy','medicinal chemistry'),('pharmacy','pharmaceutical chemistry'),
    ('life_biomedical','biology'),('life_biomedical','biochemistry'),
    ('life_biomedical','microbiology'),('life_biomedical','biotechnology'),
    ('life_biomedical','physiology'),('life_biomedical','genetics'),
    ('life_biomedical','neuroscience'),('life_biomedical','veterinary medicine'),
    ('life_biomedical','immunology'),('life_biomedical','biological sciences'),
    ('physical_chemistry','chemistry'),('physical_chemistry','school of chemistry'),
    ('physical_chemistry','chemical sciences'),('physical_chemistry','organic chemistry'),
    ('physical_chemistry','analytical chemistry'),('physical_chemistry','physics'),
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
    ('social_behavioural','applied economics'),('social_behavioural','econometrics'),
    ('earth_agriculture','geography'),('earth_agriculture','geology'),
    ('earth_agriculture','geophysics'),('earth_agriculture','environmental science'),
    ('earth_agriculture','agronomy'),('earth_agriculture','food science'),
    ('business_public','business administration'),('business_public','management'),
    ('business_public','finance'),('business_public','public administration'),
    ('humanities_law_edu','philosophy'),('humanities_law_edu','history'),
    ('humanities_law_edu','law'),('humanities_law_edu','education'),
    ('humanities_law_edu','linguistics'),
    ('non_academic','research'),('non_academic','administration'),('non_academic','library')
  ])
),
le AS (
  SELECT department, truth, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT department, truth, department AS content FROM labelled))
  WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
),
ae AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM discipline_anchors))
  WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
),
result AS (
  SELECT department, truth, grp AS predicted, grp = truth AS correct FROM (
    SELECT l.department, l.truth, a.grp,
           MAX(1 - ML.DISTANCE(l.v, a.v, 'COSINE')) AS sim
    FROM le l CROSS JOIN ae a GROUP BY 1,2,3
  ) QUALIFY ROW_NUMBER() OVER (PARTITION BY department ORDER BY sim DESC) = 1
)
SELECT
    COUNTIF(correct)                        AS correct,
    COUNT(*)                                AS total,
    ROUND(COUNTIF(correct) / COUNT(*), 3)   AS accuracy,
    STRING_AGG(IF(correct, NULL,
      CONCAT(department, ' -> ', predicted, ' (should be ', truth, ')')),
      '  //  ' ORDER BY department)         AS failures
FROM result;


-- ###########################################################################
-- QUERY 3 - DISTRIBUTION WITH v3 ANCHORS
--   Confirm the fixes did not shift anything else. Compare against v2:
--     health_clinical 27.1% / engineering 19.0% / life_biomedical 11.2%
--     physical_chemistry 10.3% / social_behavioural 7.2% / computing 6.0%
--     mathematics 4.7% / pharmacy 3.7% / earth 3.3% / business 3.0%
--     humanities 2.9% / non_academic 1.6%
--   health_clinical should rise slightly (the specialties it regained) and
--   pharmacy should fall slightly (the chemistry it gives back).
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
  GROUP BY department
  HAVING LENGTH(department) BETWEEN 2 AND 200
  ORDER BY records DESC LIMIT 500
),
discipline_anchors AS (
  SELECT * FROM UNNEST([
    STRUCT('health_clinical' AS grp, 'medicine' AS example),
    ('health_clinical','internal medicine'),('health_clinical','surgery'),
    ('health_clinical','general surgery'),('health_clinical','pediatrics'),
    ('health_clinical','psychiatry'),('health_clinical','radiology'),
    ('health_clinical','cardiology'),('health_clinical','neurology'),
    ('health_clinical','neurosurgery'),('health_clinical','pathology'),
    ('health_clinical','ophthalmology'),('health_clinical','urology'),
    ('health_clinical','dermatology'),('health_clinical','anesthesiology'),
    ('health_clinical','orthopedics'),('health_clinical','medical oncology'),
    ('health_clinical','nursing'),('health_clinical','dentistry'),
    ('health_clinical','public health'),('health_clinical','epidemiology'),
    ('health_clinical','school of medicine'),('health_clinical','faculty of medicine'),
    ('health_clinical','hematology'),('health_clinical','endocrinology'),
    ('health_clinical','rheumatology'),('health_clinical','nephrology'),
    ('health_clinical','gastroenterology'),('health_clinical','pulmonology'),
    ('health_clinical','hepatology'),('health_clinical','infectious diseases'),
    ('health_clinical','intensive care'),('health_clinical','geriatrics'),
    ('pharmacy','pharmacy'),('pharmacy','pharmacology'),
    ('pharmacy','school of pharmacy'),('pharmacy','faculty of pharmacy'),
    ('pharmacy','department of pharmacy'),('pharmacy','pharmaceutics'),
    ('pharmacy','clinical pharmacy'),('pharmacy','pharmaceutical sciences'),
    ('pharmacy','medicinal chemistry'),('pharmacy','pharmaceutical chemistry'),
    ('life_biomedical','biology'),('life_biomedical','biological sciences'),
    ('life_biomedical','biochemistry'),('life_biomedical','microbiology'),
    ('life_biomedical','biotechnology'),('life_biomedical','physiology'),
    ('life_biomedical','molecular biology'),('life_biomedical','genetics'),
    ('life_biomedical','cell biology'),('life_biomedical','immunology'),
    ('life_biomedical','neuroscience'),('life_biomedical','veterinary medicine'),
    ('life_biomedical','biochemistry and molecular biology'),
    ('physical_chemistry','chemistry'),('physical_chemistry','school of chemistry'),
    ('physical_chemistry','chemical sciences'),('physical_chemistry','organic chemistry'),
    ('physical_chemistry','analytical chemistry'),('physical_chemistry','inorganic chemistry'),
    ('physical_chemistry','physical chemistry'),('physical_chemistry','chemistry and biochemistry'),
    ('physical_chemistry','physics'),('physical_chemistry','applied physics'),
    ('physical_chemistry','physics and astronomy'),('physical_chemistry','astronomy'),
    ('physical_chemistry','materials science'),
    ('engineering','mechanical engineering'),('engineering','civil engineering'),
    ('engineering','electrical engineering'),('engineering','chemical engineering'),
    ('engineering','biomedical engineering'),('engineering','industrial engineering'),
    ('engineering','electrical and computer engineering'),
    ('engineering','electronics and communication engineering'),
    ('engineering','materials science and engineering'),
    ('engineering','engineering'),('engineering','school of engineering'),
    ('computing_data','computer science'),('computing_data','computer engineering'),
    ('computing_data','computer science and engineering'),('computing_data','informatics'),
    ('computing_data','information technology'),('computing_data','software engineering'),
    ('mathematics_statistics','mathematics'),('mathematics_statistics','statistics'),
    ('mathematics_statistics','applied mathematics'),
    ('mathematics_statistics','mathematics and statistics'),
    ('mathematics_statistics','biostatistics'),
    ('social_behavioural','psychology'),('social_behavioural','economics'),
    ('social_behavioural','sociology'),('social_behavioural','political science'),
    ('social_behavioural','anthropology'),('social_behavioural','social sciences'),
    ('social_behavioural','applied economics'),('social_behavioural','agricultural economics'),
    ('social_behavioural','econometrics'),
    ('earth_agriculture','geography'),('earth_agriculture','geology'),
    ('earth_agriculture','earth sciences'),('earth_agriculture','geophysics'),
    ('earth_agriculture','environmental science'),('earth_agriculture','agronomy'),
    ('earth_agriculture','agriculture'),('earth_agriculture','food science'),
    ('earth_agriculture','food engineering'),('earth_agriculture','forestry'),
    ('business_public','business administration'),('business_public','business school'),
    ('business_public','school of management'),('business_public','finance'),
    ('business_public','accounting'),('business_public','marketing'),
    ('business_public','public administration'),('business_public','management'),
    ('humanities_law_edu','philosophy'),('humanities_law_edu','history'),
    ('humanities_law_edu','law'),('humanities_law_edu','faculty of law'),
    ('humanities_law_edu','education'),('humanities_law_edu','school of education'),
    ('humanities_law_edu','linguistics'),('humanities_law_edu','english'),
    ('non_academic','research'),('non_academic','research and development'),
    ('non_academic','administration'),('non_academic','library')
  ])
),
de AS (
  SELECT department, records, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT department, records, department AS content FROM top_depts))
  WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
),
ae AS (
  SELECT grp, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT grp, example, example AS content FROM discipline_anchors))
  WHERE ARRAY_LENGTH(ml_generate_embedding_result) > 0
),
scored AS (
  SELECT d.department, d.records, a.grp,
         MAX(1 - ML.DISTANCE(d.v, a.v, 'COSINE')) AS sim
  FROM de d CROSS JOIN ae a GROUP BY 1,2,3
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY department ORDER BY sim DESC) AS rnk
  FROM scored
),
assigned AS (
  SELECT r1.department, r1.records, r1.grp AS discipline,
         r1.sim - r2.sim AS margin
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
