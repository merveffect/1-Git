WITH base_final AS (
    SELECT
        latest.canonical_segment_id,
        audience.snid,
        audience.email,
        latest.iso_code,
        latest.calculated_country AS country,
        latest.enrichment_source,
        latest.is_enriched,
        latest.enrichment_timestamp AS last_enriched_at,
        LOWER(TRIM(audience.email)) AS email_normalized
    FROM (
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
    ) AS latest
    INNER JOIN {{ ref('audience_builder_big') }} AS audience
        ON latest.canonical_segment_id = audience.canonical_segment_id
    WHERE audience.mkt_pref_opt_in = TRUE
      AND latest.enrichment_source != 'UNKNOWN'
      AND audience.email IS NOT NULL
),

email_counts AS (
    SELECT
        email_normalized,
        COUNT(*) AS email_row_count
    FROM base_final
    GROUP BY email_normalized
),

known_users AS (
    SELECT
        segment_id AS canonical_segment_id,
        LOWER(TRIM(email)) AS email_normalized
    FROM {{ source('prod_cdi_presentation','segment_known_users_with_email') }}
    WHERE email IS NOT NULL
),

scored AS (
    SELECT
        base_final.*,
        email_counts.email_row_count,
        CASE
            WHEN known_users.canonical_segment_id IS NOT NULL THEN 1
            ELSE 0
        END AS is_known_user_match
    FROM base_final
    INNER JOIN email_counts
        ON base_final.email_normalized = email_counts.email_normalized
    LEFT JOIN known_users
        ON base_final.canonical_segment_id = known_users.canonical_segment_id
       AND base_final.email_normalized = known_users.email_normalized
)

SELECT
    canonical_segment_id,
    snid,
    email,
    iso_code,
    country,
    enrichment_source,
    is_enriched,
    last_enriched_at
FROM scored
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY email_normalized
    ORDER BY CASE
        WHEN email_row_count > 1 AND is_known_user_match = 1 THEN 0
        WHEN email_row_count > 1 AND is_known_user_match = 0 THEN 1
        ELSE 0
    END
) = 1
