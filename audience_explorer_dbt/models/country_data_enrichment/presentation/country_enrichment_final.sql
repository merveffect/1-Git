{{ config(
    materialized='table',
    tags=['enrichment', 'presentation']
) }}

SELECT
    canonical_segment_id,
    snid,
    email,
    iso_code,
    country,
    enrichment_source,
    is_enriched,
    last_enriched_at
FROM {{ ref('stg_country_enrichment_final_email_dedup') }}
