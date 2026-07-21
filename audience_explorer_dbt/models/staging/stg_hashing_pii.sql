{{ config(
  materialized = 'table'
) }}

SELECT
  *,
  -- Normalize edilmiş halleri (Görsel kontrol için tutuyorsan kalsın)
  LOWER(NULLIF(TRIM(email), '')) AS email_normalized,

  -- Hashed email: UDF zaten NULL ve temizlik kontrolü yapıyor
  `dat-analytics-eng-ec869189.ae_metadata.hash_pii_email`(email) AS email_hashed,
  

FROM {{ ref('stg_df_audience_explorer_cleaned') }}