{{ config(
    materialized='incremental',
    tags=['enrichment', 'country_mapping'],
    description='Country mapping table with Tier 1: Original > Tier 2: TLD > Tier 3: ROR > Tier 4: IP hierarchy'
) }}

WITH mapping_data AS (
    -- Reference Data for TLDs and IP codes
    SELECT DISTINCT
        alpha_2_code,
        CASE 
            WHEN alpha_2_code = 'GB' THEN '.uk' 
            ELSE CONCAT('.', LOWER(alpha_2_code)) 
        END AS generated_tld,
        springer_nature_data_standard_location_name AS standard_name
    FROM {{ source('reference_data_presentation', 'full_location_standard') }}
    WHERE code_status = 'Current'
),

ror_data AS (
    -- Institutional Domain Reference (Tier 3)
    SELECT DISTINCT
        domain,
        country_name AS ror_country
    FROM {{ source('ror_mapping_raw_tables', 'ror_raw_final') }}
    WHERE domain IS NOT NULL
),

base_audience AS (
    -- Source of Truth for IDs and existing traits
    SELECT
        canonical_segment_id,
        snid,
        email,
        orcid,
        researcher_id,
        country AS original_raw_country,
        most_seen_ip_country,
        -- Extract components for TLD and ROR mapping
        SUBSTR(email, STRPOS(email, '@') + 1) AS email_domain,
        REGEXP_EXTRACT(LOWER(email), r'(\.[a-z]{2,})$') AS extracted_tld
    FROM {{ ref('audience_builder_big') }}
    WHERE mkt_pref_opt_in = TRUE
)

SELECT
    b.canonical_segment_id,
    b.snid,
    b.email,
    b.orcid,
    b.researcher_id,
    b.most_seen_ip_country,
    b.original_raw_country AS original_country,

    -- TIERED HIERARCHY LOGIC: Original > TLD > ROR > IP
    COALESCE(
        NULLIF(TRIM(b.original_raw_country), ''), -- Tier 1: Original Data
        m_tld.standard_name,                       -- Tier 2: Email TLD
        r.ror_country,                            -- Tier 3: ROR (Institutional)
        m_ip.standard_name                        -- Tier 4: Most Seen IP
    ) AS country,

    -- ENRICHMENT SOURCE TRACKING
    CASE 
        WHEN NULLIF(TRIM(b.original_raw_country), '') IS NOT NULL THEN 'ORIGINAL_DATA'
        WHEN m_tld.standard_name IS NOT NULL THEN 'TLD'
        WHEN r.ror_country IS NOT NULL THEN 'ROR'
        WHEN m_ip.standard_name IS NOT NULL THEN 'IP'
        ELSE 'UNKNOWN'
    END AS enrichment_source,

    -- Audit Metadata
    CURRENT_TIMESTAMP() AS enrichment_timestamp,
    (NULLIF(TRIM(b.original_raw_country), '') IS NULL AND 
     COALESCE(m_tld.standard_name, r.ror_country, m_ip.standard_name) IS NOT NULL) AS is_enriched

FROM base_audience b
LEFT JOIN mapping_data m_tld ON b.extracted_tld = m_tld.generated_tld
LEFT JOIN ror_data r ON b.email_domain = r.domain
LEFT JOIN mapping_data m_ip ON UPPER(b.most_seen_ip_country) = m_ip.alpha_2_code