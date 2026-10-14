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

WITH source_determination AS (
    SELECT
        tld_extract.canonical_segment_id,

        mapping_location_data.standard_name AS tld_country,
        mapping_location_data.alpha_2_code AS tld_iso_code,
        ror_domains.ror_country AS ror_country,
        mapping_location_data_ror.alpha_2_code AS ror_iso_code,
        mapping_location_data_ip.standard_name AS ip_country,
        mapping_location_data_ip.alpha_2_code AS ip_iso_code,

        CASE
            WHEN mapping_location_data.standard_name IS NOT NULL THEN 'TLD'
            WHEN ror_domains.ror_country IS NOT NULL THEN 'ROR'
            WHEN mapping_location_data_ip.standard_name IS NOT NULL THEN 'IP'
            ELSE 'UNKNOWN'
        END AS enrichment_source

    FROM {{ ref('stg_country_enrichment_tld_extract') }} AS tld_extract
    LEFT JOIN {{ ref('stg_country_enrichment_mapping_location_data') }} AS mapping_location_data
        ON tld_extract.extracted_tld = mapping_location_data.generated_tld
    LEFT JOIN {{ ref('stg_country_enrichment_ror_data') }} AS ror_domains
        ON tld_extract.email_domain = ror_domains.domain
    LEFT JOIN {{ ref('stg_country_enrichment_mapping_location_data') }} AS mapping_location_data_ip
        ON UPPER(tld_extract.most_seen_ip_country) = mapping_location_data_ip.alpha_2_code
    LEFT JOIN {{ ref('stg_country_enrichment_mapping_location_data') }} AS mapping_location_data_ror
        ON UPPER(TRIM(ror_domains.ror_country)) = UPPER(TRIM(mapping_location_data_ror.standard_name))
),

final_records AS (
    SELECT
        canonical_segment_id,
        enrichment_source,

        CASE
            WHEN enrichment_source = 'TLD' THEN tld_iso_code
            WHEN enrichment_source = 'ROR' THEN ror_iso_code
            WHEN enrichment_source = 'IP' THEN ip_iso_code
        END AS iso_code,

        CASE
            WHEN enrichment_source = 'TLD' THEN tld_country
            WHEN enrichment_source = 'ROR' THEN ror_country
            WHEN enrichment_source = 'IP' THEN ip_country
        END AS calculated_country,

        CURRENT_TIMESTAMP() AS enrichment_timestamp,
        enrichment_source != 'UNKNOWN' AS is_enriched

    FROM source_determination
)

SELECT final.* FROM final_records AS final

{% if is_incremental() %}
LEFT JOIN (
    SELECT * FROM {{ this }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY canonical_segment_id ORDER BY enrichment_timestamp DESC) = 1
) AS last_record
    ON final.canonical_segment_id = last_record.canonical_segment_id
WHERE
    last_record.canonical_segment_id IS NULL
    OR COALESCE(final.calculated_country, '__NULL__') != COALESCE(last_record.calculated_country, '__NULL__')
    OR COALESCE(final.enrichment_source, '__NULL__') != COALESCE(last_record.enrichment_source, '__NULL__')
    OR COALESCE(final.iso_code, '__NULL__') != COALESCE(last_record.iso_code, '__NULL__')
{% endif %}