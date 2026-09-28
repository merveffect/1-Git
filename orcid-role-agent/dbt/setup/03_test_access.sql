-- ===========================================================================
-- ERISIM TESTI - Vertex AI baglantisi kurulduktan SONRA calistir.
-- Her adimi tek tek calistir, hangisi calisiyor not al.
-- Toplam maliyet: birkac kurus.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- TEST 1: EMBEDDING MODELI  (bu SART - calismazsa proje duruyor)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE MODEL
  `researcher-360-prod-e7fd74be.orcid_role_agent.remote_text_multilingual_embedding_002`
REMOTE WITH CONNECTION `researcher-360-prod-e7fd74be.EU.vertex_ai_conn`
OPTIONS (ENDPOINT = 'text-multilingual-embedding-002');

SELECT
    content,
    ARRAY_LENGTH(ml_generate_embedding_result)  AS boyut,
    ml_generate_embedding_status                AS durum
FROM ML.GENERATE_EMBEDDING(
    MODEL `researcher-360-prod-e7fd74be.orcid_role_agent.remote_text_multilingual_embedding_002`,
    (SELECT 'consultant cardiologist' AS content
     UNION ALL SELECT 'kardiyolog'
     UNION ALL SELECT 'Facharzt fur Kardiologie'
     UNION ALL SELECT 'librarian'),
    STRUCT(TRUE AS flatten_json_output, 'SEMANTIC_SIMILARITY' AS task_type)
);
-- ✅ BEKLENEN: 4 satir, boyut = 768, durum bos.
-- ❌ HATA: baglanti service account'una roles/aiplatform.user verilmemis.


-- ---------------------------------------------------------------------------
-- TEST 1b: cok dillilik gercekten calisiyor mu?
-- ---------------------------------------------------------------------------
WITH e AS (
  SELECT content, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `researcher-360-prod-e7fd74be.orcid_role_agent.remote_text_multilingual_embedding_002`,
    (SELECT 'cardiologist' AS content
     UNION ALL SELECT 'kardiyolog'
     UNION ALL SELECT 'Facharzt fur Kardiologie'
     UNION ALL SELECT 'librarian'),
    STRUCT(TRUE AS flatten_json_output, 'SEMANTIC_SIMILARITY' AS task_type))
)
SELECT
    a.content AS terim_1,
    b.content AS terim_2,
    ROUND(1 - ML.DISTANCE(a.v, b.v, 'COSINE'), 3) AS benzerlik
FROM e a CROSS JOIN e b
WHERE a.content = 'cardiologist' AND b.content != 'cardiologist'
ORDER BY benzerlik DESC;
-- ✅ BEKLENEN: kardiyolog ve Facharzt YUKSEK (>0.75), librarian DUSUK (<0.5)
-- ❌ Hepsi birbirine yakinsa model cok dilli degil - ENDPOINT'i kontrol et.


-- ---------------------------------------------------------------------------
-- TEST 2: AI.GENERATE_BOOL  (tercih edilen yol - calismayabilir)
-- ---------------------------------------------------------------------------
SELECT
    title,
    AI.GENERATE_BOOL(
        CONCAT('Is "', title, '" a healthcare professional job title? '),
        connection_id => 'EU.vertex_ai_conn',
        endpoint      => 'gemini-2.5-flash'
    ).result AS is_hcp
FROM UNNEST(['consultant cardiologist', 'data consultant', 'librarian']) AS title;
-- ✅ CALISIRSA: dbt_project.yml -> judge_function: 'ai_generate_bool'  (varsayilan)
-- ❌ "Function not found" / bolge hatasi verirse TEST 3'e gec. Sorun degil.


-- ---------------------------------------------------------------------------
-- TEST 3: ML.GENERATE_TEXT  (guvenli liman - her yerde calisir)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE MODEL
  `researcher-360-prod-e7fd74be.orcid_role_agent.remote_gemini_2_5_flash`
REMOTE WITH CONNECTION `researcher-360-prod-e7fd74be.EU.vertex_ai_conn`
OPTIONS (ENDPOINT = 'gemini-2.5-flash');

SELECT
    prompt,
    ml_generate_text_llm_result AS cevap,
    ml_generate_text_status     AS durum
FROM ML.GENERATE_TEXT(
    MODEL `researcher-360-prod-e7fd74be.orcid_role_agent.remote_gemini_2_5_flash`,
    (SELECT CONCAT('Is "', t, '" a healthcare professional job title? ',
                   'Answer only YES or NO.') AS prompt
     FROM UNNEST(['consultant cardiologist', 'data consultant', 'librarian']) AS t),
    STRUCT(0.0 AS temperature, 8 AS max_output_tokens, TRUE AS flatten_json_output)
);
-- ✅ BEKLENEN: YES / NO / NO
-- ❌ Bu da calismazsa Vertex'te Gemini modeli bu bolgede acik degil demektir -
--    baska bir bolge dene veya quota/model erisimi talep et.


-- ---------------------------------------------------------------------------
-- TEST 4: QUOTA - 50.000 unvani islerken rate limit yeriz mi?
-- ---------------------------------------------------------------------------
-- Konsolda kontrol et:
--   IAM & Admin > Quotas > "Vertex AI API"
--   - Online prediction requests per minute
--   - Generate content requests per minute (bolge bazli)
--
-- 50.000 embedding tek seferde gider (batch destekli, sorun cikmaz).
-- LLM hakemligi sadece belirsiz bolgeye gider (~birkac bin) ama
-- dakikalik limit dusukse job yavaslar ya da hata verir.
-- Gerekirse quota artisi talep et - birkac gun surebilir.
