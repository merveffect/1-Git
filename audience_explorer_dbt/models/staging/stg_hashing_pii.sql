{{ config(
  materialized = 'table'
) }}

SELECT
  *,
  -- Normalize edilmiş halleri (Görsel kontrol için tutuyorsan kalsın)
  LOWER(NULLIF(TRIM(email), '')) AS email_normalized,
  LOWER(NULLIF(TRIM(email_address), '')) AS email_address_normalized,

  -- Hashed email: UDF zaten NULL ve temizlik kontrolü yapıyor
  `dat-analytics-eng-ec869189.ae_metadata.hash_pii_email`(email) AS email_hashed,
  
  `dat-analytics-eng-ec869189.ae_metadata.hash_pii_email`(email_address) AS email_address_hashed

FROM {{ ref('stg_df_audience_explorer_cleaned') }}