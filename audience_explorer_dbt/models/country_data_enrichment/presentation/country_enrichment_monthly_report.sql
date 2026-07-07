{{ config(
    materialized='table',
    tags=['country_enrichment', 'monthly_report']
) }}

-- Aylik ulke enrichment raporu (Country blogu).
-- Zaman ekseni: first_country_load_at (ulkenin ilk yuklendigi ay).
-- Izin gruplari: mkt=1 & leg=0 -> Opt-in ; leg=1 & mkt=0 -> Leg Int ; digerleri haric.
-- Kaynak ayrimi (country_enrichment_final.enrichment_source):
--   organic  = source TLD/ROR/IP DEGIL (ORIGINAL_DATA veya finalde kayit yok)  [pembe]
--   enriched = source TLD/ROR/IP                                              [turuncu]
-- Total YOK - Excel'de toplanir.
-- Not: organic/total gecmise donuk degisebilir (izinler user_traits'te guncellenir).
--      enriched de first_country_load ayina bagli, o da ayni sekilde davranir.

WITH user_lifecycle AS (
    SELECT
        canonical_segment_id,
        MIN(IF(name = 'country' AND value IS NOT NULL AND value != '', loaded_at, NULL)) AS first_country_load_at,
        MAX(IF(name = 'mkt_pref_opt_in' AND value = 'true', 1, 0)) AS is_mkt,
        MAX(IF(name = 'is_legitimate_interest_author_opted_in' AND value = 'true', 1, 0)) AS is_leg
    FROM {{ source('cdp_profile_sync', 'user_traits') }}
    GROUP BY 1
),

-- izin grubu ata, hedef disi kullanicilari (1-1 ve 0-0) ele
lifecycle_grouped AS (
    SELECT
        canonical_segment_id,
        first_country_load_at,
        CASE
            WHEN is_mkt = 1 AND is_leg = 0 THEN 'Opt-in'
            WHEN is_leg = 1 AND is_mkt = 0 THEN 'Leg Int'
        END AS permission_group
    FROM user_lifecycle
    WHERE (is_mkt = 1 AND is_leg = 0) OR (is_leg = 1 AND is_mkt = 0)
),

-- her csid'in enrichment source'u
enrichment_source AS (
    SELECT canonical_segment_id, enrichment_source
    FROM {{ ref('country_enrichment_final') }}
),

-- csid seviyesinde: hangi ay, hangi izin grubu, organic mi enriched mi
classified AS (
    SELECT
        FORMAT_TIMESTAMP('%Y-%m', lg.first_country_load_at) AS month,
        lg.permission_group,
        lg.canonical_segment_id,
        CASE
            WHEN es.enrichment_source IN ('TLD', 'ROR', 'IP') THEN 'enriched'
            ELSE 'organic'
        END AS metric
    FROM lifecycle_grouped lg
    LEFT JOIN enrichment_source es
        ON lg.canonical_segment_id = es.canonical_segment_id
    WHERE lg.first_country_load_at IS NOT NULL
      AND lg.permission_group IS NOT NULL
)

SELECT
    month,
    metric,
    permission_group,
    COUNT(DISTINCT canonical_segment_id) AS users
FROM classified
GROUP BY 1, 2, 3
ORDER BY month, metric, permission_group