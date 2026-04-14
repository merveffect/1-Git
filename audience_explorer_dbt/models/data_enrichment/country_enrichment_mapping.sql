{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='canonical_segment_id',
    on_schema_change='append_new_columns',
    partition_by={
        'field': 'enrichment_timestamp',
        'data_type': 'timestamp',
        'granularity': 'day'
    },
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

new_ids AS (
    -- Identify new canonical_segment_ids with mkt_pref_opt_in = TRUE (for incremental run) 
    SELECT DISTINCT canonical_segment_id
    FROM {{ ref('audience_builder_big') }}
    WHERE mkt_pref_opt_in = TRUE

    {% if is_incremental() %}
    EXCEPT DISTINCT
    SELECT canonical_segment_id
    FROM {{ this }}
    {% endif %}
),

base_audience AS (
    -- Source of Truth for IDs and existing traits
    SELECT
      src.canonical_segment_id,
        src.snid,
        src.email,
        src.orcid,
        src.researcher_id,
        src.country AS original_raw_country,
        src.most_seen_ip_country,
        -- Extract components for TLD and ROR mapping
        SUBSTR(src.email, STRPOS(src.email, '@') + 1) AS email_domain,
        REGEXP_EXTRACT(LOWER(src.email), r'(\.[a-z]{2,})$') AS extracted_tld
    FROM {{ ref('audience_builder_big') }} src
    INNER JOIN new_ids n ON src.canonical_segment_id = n.canonical_segment_id

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


