-- ===========================================================================
-- ERISIM TESTI
-- Yeni Vertex baglantisi kurmaya gerek YOK - mevcut remote model var:
--     datasn-rm-live.institution_disambiguation.embedding_model
-- Sadece o proje uzerinde okuma izni gerekiyor.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- TEST 1: Mevcut embedding modeline erisim var mi?
-- ---------------------------------------------------------------------------
SELECT
    content,
    ARRAY_LENGTH(ml_generate_embedding_result) AS boyut
FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT 'consultant cardiologist' AS content
     UNION ALL SELECT 'librarian')
);
-- OK: 2 satir, boyut dolu.
-- HATA "Access Denied": datasn-rm-live uzerinde okuma izni gerekiyor.


-- ---------------------------------------------------------------------------
-- TEST 1b: *** PROJENIN EN KRITIK TESTI ***
-- Bu model COK DILLI mi?
--
-- Model institution disambiguation icin kurulmustu; kurum isimleri
-- cogunlukla Ingilizce oldugu icin orada sorun cikmamis olabilir.
-- Ama ORCID unvanlari 100+ dilde. Model Ingilizce-only ise
-- "kardiyolog" ve "Oberarztin" kacar ve BASKA MODEL gerekir.
-- ---------------------------------------------------------------------------
WITH e AS (
  SELECT content, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT 'cardiologist' AS content
     UNION ALL SELECT 'kardiyolog'                      -- TR
     UNION ALL SELECT 'Facharzt fur Kardiologie'        -- DE
     UNION ALL SELECT 'cardiologue'                     -- FR
     UNION ALL SELECT 'librarian'))                     -- alakasiz kontrol
SELECT
    b.content                                           AS terim,
    ROUND(1 - ML.DISTANCE(a.v, b.v, 'COSINE'), 3)       AS benzerlik
FROM e a CROSS JOIN e b
WHERE a.content = 'cardiologist' AND b.content != 'cardiologist'
ORDER BY benzerlik DESC;

/*
    BEKLENEN (cok dilli model):
        kardiyolog                  0.80+
        Facharzt fur Kardiologie    0.75+
        cardiologue                 0.85+
        librarian                   0.40-

    COK DILLI DEGILSE:
        Uc dil de librarian ile benzer seviyede (0.3-0.5) cikar.
        Bu durumda dbt_project.yml -> embedding_model degistirilmeli
        ve yeni bir remote model kurulmali:
            text-multilingual-embedding-002
        Tek satirlik degisiklik, kod etkilenmez.
*/


-- ---------------------------------------------------------------------------
-- TEST 2: VECTOR_SEARCH calisiyor mu? (kucuk olcekte prova)
-- ---------------------------------------------------------------------------
WITH anchors AS (
  SELECT 'hcp' AS role_key, content AS anchor_term, ml_generate_embedding_result AS embedding
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT 'physician' AS content UNION ALL SELECT 'cardiologist'))
),
titles AS (
  SELECT content AS title, ml_generate_embedding_result AS embedding
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT 'kardiyolog' AS content UNION ALL SELECT 'head librarian'))
)
SELECT
    query.title         AS unvan,
    base.anchor_term    AS eslesen_anchor,
    ROUND(1 - distance, 3) AS benzerlik
FROM VECTOR_SEARCH(
    TABLE anchors, 'embedding',
    TABLE titles,  'embedding',
    top_k => 1,
    distance_type => 'COSINE');
-- BEKLENEN: kardiyolog -> cardiologist (yuksek), head librarian -> dusuk


-- ---------------------------------------------------------------------------
-- TEST 3: LLM hakemligi - hangi yol calisiyor?
-- ---------------------------------------------------------------------------
-- 3a) AI.GENERATE_BOOL (tercih edilen, sade)
SELECT
    t,
    AI.GENERATE_BOOL(
        CONCAT('Is "', t, '" a healthcare professional job title?'),
        connection_id => 'EU.vertex_ai_conn',
        endpoint      => 'gemini-2.5-flash').result AS is_hcp
FROM UNNEST(['consultant cardiologist', 'data consultant']) AS t;
-- Calisirsa:  judge_function: 'ai_generate_bool'
-- Calismazsa: 3b'ye gec (sorun degil)

-- 3b) ML.GENERATE_TEXT (guvenli liman) - once remote model gerekir
-- CREATE OR REPLACE MODEL `<proje>.<dataset>.remote_gemini_2_5_flash`
-- REMOTE WITH CONNECTION `<proje>.EU.vertex_ai_conn`
-- OPTIONS (ENDPOINT = 'gemini-2.5-flash');
--   -> judge_function: 'ml_generate_text'

-- NOT: LLM hakemligi OLMADAN da pipeline calisir; sadece vektor
-- kararlariyla gider (esikler biraz daha muhafazakar tutulur).
-- Yani Test 3 bloklayici degil, Test 1b bloklayici.
