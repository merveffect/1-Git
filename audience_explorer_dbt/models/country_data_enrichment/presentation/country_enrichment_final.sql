{{ config(
    materialized='table',
    tags=['enrichment', 'presentation']
) }}

WITH latest_records AS (
    SELECT 
        canonical_segment_id,
        iso_code,
        calculated_country,
        enrichment_source,
        is_enriched,
        enrichment_timestamp
    FROM {{ ref('stg_country_enrichment_matches') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY canonical_segment_id 
        ORDER BY enrichment_timestamp DESC
    ) = 1
)

SELECT
    -- 1. Enrichment data from history table (latest record per canonical_segment_id)
    latest.canonical_segment_id,
    audience.snid,
    audience.email,
    latest.iso_code,
    latest.calculated_country AS country,
    latest.enrichment_source,
    latest.is_enriched,
    latest.enrichment_timestamp AS last_enriched_at

FROM latest_records AS latest
INNER JOIN {{ ref('audience_builder_big') }} AS audience 
    ON latest.canonical_segment_id = audience.canonical_segment_id

-- 3. Market preference filter to ensure we only include relevant records in the final presentation layer
WHERE audience.mkt_pref_opt_in = TRUE
and enrichment_source != 'UNKNOWN' -- Exclude records where enrichment was attempted but no source could be determined