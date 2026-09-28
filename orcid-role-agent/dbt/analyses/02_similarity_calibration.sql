/*
    ============================================================================
    BENZERLIK ESIGI KALIBRASYONU
    ============================================================================
    Her sorgu TEK BASINA calisir. TEMP TABLE yok, dbt tablosu yok -
    hicbir sey BigQuery'de olusturulmus olmak zorunda degil.
    Konsola yapistir, calistir.

    NEDEN: Test 1b'de alakasiz iki terim ("cardiologist" vs "librarian")
    bile 0.572 benzerlik aldi. Bu modelin TABAN benzerligi yuksek;
    esikleri gozlemle degil olcumle koymamiz lazim.
    ============================================================================
*/


-- ###########################################################################
-- SORGU 1 - DETAY: her test unvani icin en iyi rol, marj, dogru mu?
-- ###########################################################################
WITH anchor_input AS (
  SELECT * FROM UNNEST([
    STRUCT('hcp' AS role_key, 'include' AS polarity, 'physician' AS term),
    ('hcp','include','medical doctor'), ('hcp','include','surgeon'),
    ('hcp','include','cardiologist'),   ('hcp','include','oncologist'),
    ('hcp','include','registered nurse'),('hcp','include','general practitioner'),
    ('hcp','include','consultant physician'),('hcp','include','arzt'),
    ('hcp','include','medecin'),        ('hcp','include','clinical fellow'),
    ('hcp','exclude','data consultant'),('hcp','exclude','it consultant'),
    ('hcp','exclude','software engineer'),('hcp','exclude','medical writer'),

    ('pharmacist','include','pharmacist'),('pharmacist','include','clinical pharmacist'),
    ('pharmacist','include','hospital pharmacist'),('pharmacist','include','apotheker'),
    ('pharmacist','include','eczaci'),  ('pharmacist','include','pharmacien'),
    ('pharmacist','exclude','pharmacologist'),('pharmacist','exclude','pharmacy technician'),

    ('librarian','include','librarian'),('librarian','include','academic librarian'),
    ('librarian','include','subject librarian'),('librarian','include','information specialist'),
    ('librarian','include','repository manager'),('librarian','include','bibliothekar'),
    ('librarian','include','kutuphaneci'),('librarian','include','scholarly communications librarian'),
    ('librarian','exclude','data engineer'),

    ('researcher','include','research scientist'),('researcher','include','postdoctoral researcher'),
    ('researcher','include','principal investigator'),('researcher','include','research fellow'),
    ('researcher','include','research associate'),('researcher','include','wissenschaftlicher mitarbeiter'),
    ('researcher','include','chercheur'),('researcher','include','arastirmaci'),
    ('researcher','exclude','market research analyst'),('researcher','exclude','research administrator'),

    ('faculty_head','include','dean'),  ('faculty_head','include','dean of faculty'),
    ('faculty_head','include','head of department'),('faculty_head','include','department chair'),
    ('faculty_head','include','dekan'),('faculty_head','include','bolum baskani'),
    ('faculty_head','include','head of school'),('faculty_head','include','provost'),
    ('faculty_head','exclude','head of laboratory'),('faculty_head','exclude','head of marketing')
  ])
),
title_input AS (
  SELECT * FROM UNNEST([
    STRUCT('consultant cardiologist' AS title, 'hcp' AS expected_role, TRUE AS should_match),
    ('kardiyolog','hcp',TRUE), ('Oberarztin Kardiologie','hcp',TRUE),
    ('medecin generaliste','hcp',TRUE), ('registered nurse','hcp',TRUE),
    ('clinical fellow','hcp',TRUE),
    ('data consultant','hcp',FALSE), ('software engineer','hcp',FALSE),
    ('head of marketing','hcp',FALSE), ('professor of physics','hcp',FALSE),
    ('financial analyst','hcp',FALSE),

    ('subject librarian','librarian',TRUE), ('bibliothekar','librarian',TRUE),
    ('kutuphaneci','librarian',TRUE), ('scholarly communications manager','librarian',TRUE),
    ('repository manager','librarian',TRUE),
    ('data engineer','librarian',FALSE), ('archaeologist','librarian',FALSE),
    ('professor of history','librarian',FALSE),

    ('dean of engineering','faculty_head',TRUE), ('dekan','faculty_head',TRUE),
    ('head of department','faculty_head',TRUE), ('bolum baskani','faculty_head',TRUE),
    ('head of laboratory','faculty_head',FALSE), ('project manager','faculty_head',FALSE),
    ('phd student','faculty_head',FALSE),

    ('postdoctoral researcher','researcher',TRUE), ('wissenschaftlicher mitarbeiter','researcher',TRUE),
    ('principal investigator','researcher',TRUE), ('research fellow','researcher',TRUE),
    ('market research analyst','researcher',FALSE), ('hr manager','researcher',FALSE),

    ('hospital pharmacist','pharmacist',TRUE), ('eczaci','pharmacist',TRUE),
    ('apotheker','pharmacist',TRUE),
    ('pharmacologist','pharmacist',FALSE), ('pharmacy technician','pharmacist',FALSE)
  ])
),
anchor_emb AS (
  SELECT role_key, polarity, term, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT role_key, polarity, term, term AS content FROM anchor_input))
),
title_emb AS (
  SELECT title, expected_role, should_match, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT title, expected_role, should_match, title AS content FROM title_input))
),
per_role AS (
  SELECT
      t.title, t.expected_role, t.should_match, a.role_key,
      MAX(IF(a.polarity='include', 1 - ML.DISTANCE(t.v, a.v, 'COSINE'), NULL)) AS inc_sim,
      MAX(IF(a.polarity='exclude', 1 - ML.DISTANCE(t.v, a.v, 'COSINE'), NULL)) AS exc_sim
  FROM title_emb t CROSS JOIN anchor_emb a
  GROUP BY 1,2,3,4
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY title ORDER BY inc_sim DESC) AS rnk
  FROM per_role
)
SELECT
    r1.title                                    AS unvan,
    r1.expected_role                            AS beklenen,
    r1.should_match                             AS dogru_mu,
    r1.role_key                                 AS bulunan,
    r1.role_key = r1.expected_role              AS rol_isabetli,
    ROUND(r1.inc_sim, 3)                        AS en_iyi,
    ROUND(r2.inc_sim, 3)                        AS ikinci,
    ROUND(r1.inc_sim - r2.inc_sim, 3)           AS marj,
    ROUND(r1.exc_sim, 3)                        AS exclude_sim,
    r1.exc_sim > r1.inc_sim                     AS exclude_bloklardi
FROM ranked r1
LEFT JOIN ranked r2 ON r1.title = r2.title AND r2.rnk = 2
WHERE r1.rnk = 1
ORDER BY r1.should_match DESC, r1.inc_sim DESC;

/*
    NASIL OKUNUR:
      rol_isabetli = FALSE       -> anchor eksigi, role_anchors.csv'ye terim ekle
      dogru_mu=TRUE  en_iyi min  -> kabul esiginin USTU olamaz
      dogru_mu=FALSE en_iyi max  -> kabul esiginin ALTI olmali
      Ikisi ortusuyorsa mutlak esik yetmez -> marj sutununa bak
      exclude_bloklardi = TRUE   -> exclude anchor'i ise yariyor
*/


-- ###########################################################################
-- SORGU 2 - OZET: dogru ve yanlis eslesmelerin dagilimi
-- Yukaridaki CTE'lerin AYNISI; sadece son SELECT farkli.
-- ###########################################################################
WITH anchor_input AS (
  SELECT * FROM UNNEST([
    STRUCT('hcp' AS role_key, 'include' AS polarity, 'physician' AS term),
    ('hcp','include','medical doctor'), ('hcp','include','surgeon'),
    ('hcp','include','cardiologist'),   ('hcp','include','oncologist'),
    ('hcp','include','registered nurse'),('hcp','include','general practitioner'),
    ('hcp','include','consultant physician'),('hcp','include','arzt'),
    ('hcp','include','medecin'),        ('hcp','include','clinical fellow'),
    ('pharmacist','include','pharmacist'),('pharmacist','include','clinical pharmacist'),
    ('pharmacist','include','hospital pharmacist'),('pharmacist','include','apotheker'),
    ('pharmacist','include','eczaci'),  ('pharmacist','include','pharmacien'),
    ('librarian','include','librarian'),('librarian','include','academic librarian'),
    ('librarian','include','subject librarian'),('librarian','include','information specialist'),
    ('librarian','include','repository manager'),('librarian','include','bibliothekar'),
    ('librarian','include','kutuphaneci'),
    ('researcher','include','research scientist'),('researcher','include','postdoctoral researcher'),
    ('researcher','include','principal investigator'),('researcher','include','research fellow'),
    ('researcher','include','wissenschaftlicher mitarbeiter'),('researcher','include','arastirmaci'),
    ('faculty_head','include','dean'),  ('faculty_head','include','dean of faculty'),
    ('faculty_head','include','head of department'),('faculty_head','include','department chair'),
    ('faculty_head','include','dekan'),('faculty_head','include','bolum baskani')
  ])
),
title_input AS (
  SELECT * FROM UNNEST([
    STRUCT('consultant cardiologist' AS title, 'hcp' AS expected_role, TRUE AS should_match),
    ('kardiyolog','hcp',TRUE), ('Oberarztin Kardiologie','hcp',TRUE),
    ('medecin generaliste','hcp',TRUE), ('registered nurse','hcp',TRUE),
    ('clinical fellow','hcp',TRUE),
    ('data consultant','hcp',FALSE), ('software engineer','hcp',FALSE),
    ('head of marketing','hcp',FALSE), ('professor of physics','hcp',FALSE),
    ('financial analyst','hcp',FALSE),
    ('subject librarian','librarian',TRUE), ('bibliothekar','librarian',TRUE),
    ('kutuphaneci','librarian',TRUE), ('scholarly communications manager','librarian',TRUE),
    ('repository manager','librarian',TRUE),
    ('data engineer','librarian',FALSE), ('archaeologist','librarian',FALSE),
    ('professor of history','librarian',FALSE),
    ('dean of engineering','faculty_head',TRUE), ('dekan','faculty_head',TRUE),
    ('head of department','faculty_head',TRUE), ('bolum baskani','faculty_head',TRUE),
    ('head of laboratory','faculty_head',FALSE), ('project manager','faculty_head',FALSE),
    ('phd student','faculty_head',FALSE),
    ('postdoctoral researcher','researcher',TRUE), ('wissenschaftlicher mitarbeiter','researcher',TRUE),
    ('principal investigator','researcher',TRUE), ('research fellow','researcher',TRUE),
    ('market research analyst','researcher',FALSE), ('hr manager','researcher',FALSE),
    ('hospital pharmacist','pharmacist',TRUE), ('eczaci','pharmacist',TRUE),
    ('apotheker','pharmacist',TRUE),
    ('pharmacologist','pharmacist',FALSE), ('pharmacy technician','pharmacist',FALSE)
  ])
),
anchor_emb AS (
  SELECT role_key, term, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT role_key, term, term AS content FROM anchor_input))
),
title_emb AS (
  SELECT title, expected_role, should_match, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT title, expected_role, should_match, title AS content FROM title_input))
),
matched AS (
  SELECT
      t.title, t.should_match,
      MAX(1 - ML.DISTANCE(t.v, a.v, 'COSINE')) AS sim
  FROM title_emb t
  JOIN anchor_emb a ON a.role_key = t.expected_role
  GROUP BY 1,2
)
SELECT
    should_match                                             AS dogru_eslesme_mi,
    COUNT(*)                                                 AS adet,
    ROUND(MIN(sim), 3)                                       AS min,
    ROUND(APPROX_QUANTILES(sim, 100)[OFFSET(25)], 3)         AS p25,
    ROUND(AVG(sim), 3)                                       AS ortalama,
    ROUND(APPROX_QUANTILES(sim, 100)[OFFSET(75)], 3)         AS p75,
    ROUND(MAX(sim), 3)                                       AS max
FROM matched
GROUP BY should_match
ORDER BY should_match DESC;

/*
    ARADIGIMIZ SEY:
        dogru_eslesme_mi=TRUE   min = 0.74
        dogru_eslesme_mi=FALSE  max = 0.68
                                       ^^^^ BOSLUK VAR -> esik 0.71 olur

    Ortusuyorsa (TRUE.min < FALSE.max) tek bir mutlak esik yetmiyor
    demektir; o zaman sorgu 1'deki MARJ sutunu belirleyici olur veya
    LLM hakemi gerekir.
*/
