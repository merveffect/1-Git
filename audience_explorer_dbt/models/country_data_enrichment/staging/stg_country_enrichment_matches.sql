{{ config(
    materialized='incremental',
    full_refresh=false,
    partition_by={
        'field': 'enrichment_timestamp',
        'data_type': 'timestamp',
        'granularity': 'day'
        },
    tags=['country_enrichment', 'country_history']
) }}

{% if is_incremental() %}
WITH previously_enriched AS (
    -- canonical segment ids has been enriched before, we need to check if the new enrichment is different from the previous one
    -- these are the records that have been enriched before, we will use them to compare with the new enrichment results
    -- not truly "original" -> do not count as ORIGINAL_DATA.
    SELECT DISTINCT canonical_segment_id
    FROM {{ this }}
    WHERE enrichment_source IN ('TLD', 'ROR', 'IP')
),

source_determination AS (
{% else %}
WITH source_determination AS (
{% endif %}
    SELECT
        country_enrichment_tld_extract.canonical_segment_id,
        country_enrichment_tld_extract.original_raw_cdp_country,
        country_enrichment_tld_extract.most_seen_ip_country,

        mapping_location_data.standard_name AS tld_country,
        mapping_location_data.alpha_2_code AS tld_iso_code,
        ror_domains.ror_country AS ror_country,
        mapping_location_data_ip.standard_name AS ip_country,
        mapping_location_data_ip.alpha_2_code AS ip_iso_code,
        mapping_location_data_ror.alpha_2_code AS ror_iso_code,
        mapping_location_data_original.alpha_2_code AS original_iso_code,

        CASE
            WHEN country_enrichment_tld_extract.original_raw_cdp_country IS NOT NULL
                 {% if is_incremental() %}
                 AND previously_enriched.canonical_segment_id IS NULL
                 {% endif %}
                 THEN 'ORIGINAL_DATA'
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
    LEFT JOIN {{ ref('stg_country_enrichment_mapping_location_data') }} AS mapping_location_data_ror
        ON UPPER(TRIM(ror_domains.ror_country)) = UPPER(TRIM(mapping_location_data_ror.standard_name))
    LEFT JOIN {{ ref('stg_country_enrichment_mapping_location_data') }} AS mapping_location_data_original
        ON UPPER(TRIM(country_enrichment_tld_extract.original_raw_cdp_country)) = UPPER(TRIM(mapping_location_data_original.standard_name))
    {% if is_incremental() %}
    LEFT JOIN previously_enriched
        ON previously_enriched.canonical_segment_id = country_enrichment_tld_extract.canonical_segment_id
    {% endif %}
),

final_records AS (
SELECT
canonical_segment_id,
enrichment_source,

CASE
    WHEN enrichment_source = 'ORIGINAL_DATA' THEN original_iso_code
    WHEN enrichment_source = 'TLD' THEN tld_iso_code
    WHEN enrichment_source = 'ROR' THEN ror_iso_code
    WHEN enrichment_source = 'IP' THEN ip_iso_code
    ELSE NULL
END AS iso_code,

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
    last_record.canonical_segment_id IS NULL
    OR
        COALESCE(final.calculated_country, '__NULL__') != COALESCE(last_record.calculated_country, '__NULL__')
    OR
        COALESCE(final.enrichment_source, '__NULL__') != COALESCE(last_record.enrichment_source, '__NULL__')
        OR
        COALESCE(final.iso_code, '__NULL__') != COALESCE(last_record.iso_code, '__NULL__')
{% endif %}