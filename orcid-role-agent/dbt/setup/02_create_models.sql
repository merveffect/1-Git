-- ---------------------------------------------------------------------------
-- Uzak (remote) modeller. BIR KEZ calistirilir.
-- Model adlari dbt macros/vertex.sql icindeki isimlendirmeyle eslesmeli:
--     remote_<model_adi_alt_cizgili>
-- ---------------------------------------------------------------------------

-- 1) EMBEDDING MODELI
--    Cok dilli sart: ORCID unvanlari 100+ dilde. Ingilizce-only bir model
--    "kardiyolog", "Facharzt", "bibliothecaire" gibi girdileri kacirir.
CREATE OR REPLACE MODEL `researcher-360-prod-e7fd74be.orcid_role_agent.remote_text_multilingual_embedding_002`
REMOTE WITH CONNECTION `researcher-360-prod-e7fd74be.EU.vertex_ai_conn`
OPTIONS (ENDPOINT = 'text-multilingual-embedding-002');


-- 2) VEKTOR INDEKSI (opsiyonel, anchor sayisi buyurse hizlandirir)
-- CREATE VECTOR INDEX anchor_idx
-- ON `researcher-360-prod-e7fd74be.orcid_role_agent.int_anchor_embeddings`(embedding)
-- OPTIONS (index_type = 'IVF', distance_type = 'COSINE');


-- 3) DOGRULAMA - baglanti calisiyor mu?
SELECT
    content,
    ARRAY_LENGTH(ml_generate_embedding_result) AS dim
FROM ML.GENERATE_EMBEDDING(
    MODEL `researcher-360-prod-e7fd74be.orcid_role_agent.remote_text_multilingual_embedding_002`,
    (SELECT 'consultant cardiologist' AS content
     UNION ALL SELECT 'kardiyolog'
     UNION ALL SELECT 'Facharzt fur Kardiologie'),
    STRUCT(TRUE AS flatten_json_output, 'SEMANTIC_SIMILARITY' AS task_type)
);
-- Beklenen: 3 satir, dim = 768. Uc unvan birbirine cok yakin olmali.
