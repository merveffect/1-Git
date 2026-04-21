{{ config(
    materialized='incremental',
    partition_by={
        'field': 'enrichment_timestamp',
        'data_type': 'timestamp',
        'granularity': 'day'
    },
    tags=['enrichment', 'country_history']
) }}

WITH source_determination AS (
    SELECT
        country_enrichment_tld_extract.canonical_segment_id,
        country_enrichment_tld_extract.original_raw_cdp_country,
        country_enrichment_tld_extract.most_seen_ip_country,

        mapping_location_data.standard_name AS tld_country,
        ror_domains.ror_country AS ror_country,
        mapping_location_data_ip.standard_name AS ip_country,
        
        CASE 
            WHEN country_enrichment_tld_extract.original_raw_cdp_country IS NOT NULL THEN 'ORIGINAL_DATA'
            WHEN mapping_location_data.standard_name IS NOT NULL THEN 'TLD'
            WHEN ror_domains.ror_country IS NOT NULL THEN 'ROR'
            WHEN mapping_location_data_ip.standard_name IS NOT NULL THEN 'IP'
            ELSE 'UNKNOWN'
        END AS enrichment_source

    FROM {{ ref('stg_country_enrichment_tld_extract') }} AS country_enrichment_tld_extract
    LEFT JOIN {{ ref('stg_country_enrichment_mapping_location_data') }} AS mapping_location_data
        ON country_enrichment_tld_extract.extracted_tld = mapping_location_data.generated_tld
    LEFT JOIN {{ ref('stg_country_enrichment_ror_data') }} AS ror_domains
        ON country_enrichment_tld_extract.email_domain = ror_domains.domain
    LEFT JOIN {{ ref('stg_country_enrichment_mapping_location_data') }} AS mapping_location_data_ip
        ON UPPER(country_enrichment_tld_extract.most_seen_ip_country) = mapping_location_data_ip.alpha_2_code
),

final_records AS (
SELECT
canonical_segment_id,
enrichment_source,

CASE
    WHEN enrichment_source = 'ORIGINAL_DATA' THEN original_raw_cdp_country
    WHEN enrichment_source = 'TLD' THEN tld_country
    WHEN enrichment_source = 'ROR' THEN ror_country
    WHEN enrichment_source = 'IP' THEN ip_country
    ELSE NULL
END AS calculated_country,


--Audit Metadata
CURRENT_TIMESTAMP() AS enrichment_timestamp,

--Enrichment status
(enrichment_source NOT IN ('UNKNOWN', 'ORIGINAL_DATA')) AS is_enriched

FROM source_determination
) 

SELECT final.* FROM final_records AS final

{% if is_incremental() %}
-- Change detection with LEFT JOIN to existing records
  LEFT JOIN (
      SELECT * FROM {{ this }}
      QUALIFY ROW_NUMBER() OVER (PARTITION BY canonical_segment_id ORDER BY enrichment_timestamp DESC) = 1
  ) AS last_record
    ON final.canonical_segment_id = last_record.canonical_segment_id

  WHERE 
    -- 1. Add new records that don't exist in the target table
    last_record.canonical_segment_id IS NULL 
    OR 
    -- 2. If the record exists, only update if there's a change in calculated country or enrichment source
    final.calculated_country != last_record.calculated_country
    OR 
    final.enrichment_source != last_record.enrichment_source
{% endif %}

