/*
    ============================================================================
    BENZERLIK ESIGI KALIBRASYONU  ***  SIRADAKI KRITIK ADIM  ***
    ============================================================================
    Test 1b sonucu:
        cardiologue                0.928
        Facharzt fur Kardiologie   0.795
        kardiyolog                 0.760
        librarian                  0.572   <-- ALAKASIZ terim
                                                 ama yine de 0.572!

    Bu modelin TABAN benzerligi yuksek. Alakasiz iki terim bile 0.57
    aliyor. Yani benim varsayilan esiklerim (0.90 / 0.55) YANLIS:
    0.55 esigi her seyi kabul ederdi.

    Asagidaki sorgu gercek pozitif ve gercek negatif orneklerle
    dagilimi olcup dogru esikleri buluyor.
    ============================================================================
*/

DECLARE MODEL_PATH STRING DEFAULT
    'datasn-rm-live.institution_disambiguation.embedding_model';

-- ---------------------------------------------------------------------------
-- Bilerek secilmis test seti: her rol icin DOGRU ve YANLIS ornekler
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE test_pairs AS
SELECT * FROM UNNEST([
  -- (unvan, rol, beklenen)  --------------------------------------------
  STRUCT('consultant cardiologist'      AS title, 'hcp' AS role_key, TRUE  AS should_match),
  STRUCT('kardiyolog',                        'hcp', TRUE),
  STRUCT('Oberarztin Kardiologie',            'hcp', TRUE),
  STRUCT('medecin generaliste',               'hcp', TRUE),
  STRUCT('registered nurse',                  'hcp', TRUE),
  STRUCT('clinical fellow',                   'hcp', TRUE),
  STRUCT('data consultant',                   'hcp', FALSE),
  STRUCT('software engineer',                 'hcp', FALSE),
  STRUCT('head of marketing',                 'hcp', FALSE),
  STRUCT('professor of physics',              'hcp', FALSE),
  STRUCT('financial analyst',                 'hcp', FALSE),

  STRUCT('subject librarian',                 'librarian', TRUE),
  STRUCT('bibliothekar',                      'librarian', TRUE),
  STRUCT('kutuphaneci',                       'librarian', TRUE),
  STRUCT('scholarly communications manager',  'librarian', TRUE),
  STRUCT('repository manager',                'librarian', TRUE),
  STRUCT('data engineer',                     'librarian', FALSE),
  STRUCT('archaeologist',                     'librarian', FALSE),
  STRUCT('professor of history',              'librarian', FALSE),

  STRUCT('dean of engineering',               'faculty_head', TRUE),
  STRUCT('dekan',                             'faculty_head', TRUE),
  STRUCT('head of department',                'faculty_head', TRUE),
  STRUCT('bolum baskani',                     'faculty_head', TRUE),
  STRUCT('head of laboratory',                'faculty_head', FALSE),
  STRUCT('project manager',                   'faculty_head', FALSE),
  STRUCT('phd student',                       'faculty_head', FALSE),

  STRUCT('postdoctoral researcher',           'researcher', TRUE),
  STRUCT('wissenschaftlicher mitarbeiter',    'researcher', TRUE),
  STRUCT('principal investigator',            'researcher', TRUE),
  STRUCT('research fellow',                   'researcher', TRUE),
  STRUCT('market research analyst',           'researcher', FALSE),
  STRUCT('hr manager',                        'researcher', FALSE),

  STRUCT('hospital pharmacist',               'pharmacist', TRUE),
  STRUCT('eczaci',                            'pharmacist', TRUE),
  STRUCT('apotheker',                         'pharmacist', TRUE),
  STRUCT('pharmacologist',                    'pharmacist', FALSE),
  STRUCT('pharmacy technician',               'pharmacist', FALSE)
]);

-- ---------------------------------------------------------------------------
-- VECTOR_SEARCH gercek TABLO ister (CTE kabul etmiyor - Test 2 bu yuzden
-- hata verdi). O yuzden embedding'leri once TEMP TABLE'a yaziyoruz.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE anchor_emb AS
SELECT role_key, polarity, anchor_term, ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(
  MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
  (SELECT role_key, polarity, anchor_term, anchor_term AS content
   FROM `researcher-360-prod-e7fd74be.orcid_role_agent_seeds.role_anchors`)
);

CREATE TEMP TABLE title_emb AS
SELECT title, role_key AS expected_role, should_match,
       ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(
  MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
  (SELECT title, role_key, should_match, title AS content FROM test_pairs)
);

-- ---------------------------------------------------------------------------
-- 1. HER (unvan, rol) cifti icin en iyi benzerlik
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE scored AS
SELECT
    t.title,
    t.expected_role,
    t.should_match,
    a.role_key                                  AS matched_role,
    MAX(1 - ML.DISTANCE(t.embedding, a.embedding, 'COSINE')) AS similarity
FROM title_emb t CROSS JOIN anchor_emb a
WHERE a.polarity = 'include'
GROUP BY 1,2,3,4;

-- ---------------------------------------------------------------------------
-- 2. ⭐ DAGILIM - dogru ve yanlis eslesmeler nerede duruyor?
--    Ideal: should_match=TRUE'nun MIN'i, FALSE'un MAX'inin UZERINDE olmali.
--    Ortusuyorsa tek bir esikle ayirmak mumkun degil.
-- ---------------------------------------------------------------------------
SELECT
    should_match                                AS dogru_eslesme_mi,
    COUNT(*)                                    AS adet,
    ROUND(MIN(similarity), 3)                   AS min,
    ROUND(APPROX_QUANTILES(similarity, 100)[OFFSET(10)], 3)  AS p10,
    ROUND(AVG(similarity), 3)                   AS ortalama,
    ROUND(APPROX_QUANTILES(similarity, 100)[OFFSET(90)], 3)  AS p90,
    ROUND(MAX(similarity), 3)                   AS max
FROM scored
WHERE expected_role = matched_role
GROUP BY should_match;

-- ---------------------------------------------------------------------------
-- 3. ⭐ MARJ TESTI - mutlak esik yerine GORECELI fark
--    Taban benzerlik yuksek oldugunda mutlak esik kirilgan olur.
--    Daha saglam soru: "en iyi rol, ikinciyi ne kadar geride birakti?"
-- ---------------------------------------------------------------------------
WITH ranked AS (
  SELECT
      title, expected_role, should_match, matched_role, similarity,
      ROW_NUMBER() OVER (PARTITION BY title ORDER BY similarity DESC) AS rnk
  FROM scored
),
margins AS (
  SELECT
      title,
      MAX(IF(rnk = 1, matched_role, NULL))      AS best_role,
      MAX(IF(rnk = 1, similarity,  NULL))       AS best_sim,
      MAX(IF(rnk = 2, similarity,  NULL))       AS second_sim,
      MAX(expected_role)                        AS expected_role,
      MAX(CAST(should_match AS INT64)) = 1      AS should_match
  FROM ranked WHERE rnk <= 2 GROUP BY title
)
SELECT
    title                                       AS unvan,
    expected_role                               AS beklenen_rol,
    should_match                                AS dogru_mu,
    best_role                                   AS bulunan_rol,
    ROUND(best_sim, 3)                          AS en_iyi,
    ROUND(second_sim, 3)                        AS ikinci,
    ROUND(best_sim - second_sim, 3)             AS marj,
    best_role = expected_role                   AS rol_dogru_mu
FROM margins
ORDER BY should_match DESC, best_sim DESC;

/*
    SONUCU NASIL OKUYACAGIZ:

    Sorgu 2'de:
      - TRUE min  ile FALSE max  arasinda BOSLUK varsa
        -> esik ikisinin arasina konur, is biter
      - Ortusuyorsa
        -> mutlak esik yetmez, marj (sorgu 3) veya LLM hakemi gerekir

    Sorgu 3'te:
      - rol_dogru_mu = FALSE olan satirlar -> anchor eksigi var,
        role_anchors.csv'ye terim eklenmeli
      - marj kucuk olanlar -> belirsiz bolge, insan review'a gider

    Cikan degerler dbt_project.yml -> sim_auto_accept / sim_judge_floor /
    sim_review_floor / sim_min_margin alanlarina yazilacak.
*/
