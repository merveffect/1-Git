SELECT
    -- The Anchor
    audience_builder_big.canonical_segment_id,

        audience_builder_big.email,
        audience_builder_big.country AS original_raw_cdp_country,
        audience_builder_big.most_seen_ip_country,
    
    -- Key fields for Tier 2 & Tier 3
    SUBSTR(
        audience_builder_big.email, 
        STRPOS(audience_builder_big.email, '@') + 1
    ) AS email_domain,

    REGEXP_EXTRACT(
        LOWER(audience_builder_big.email), 
        r'(\.[a-z]{2,})$'
    ) AS extracted_tld

FROM {{ ref('audience_builder_big') }} AS audience_builder_big
WHERE email IS NOT NULL