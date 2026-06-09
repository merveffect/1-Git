    -- Institutional Domain Reference (Tier 3)
    SELECT DISTINCT
        domain,
        country_name AS ror_country
    FROM {{ref('raw_ror_table') }}
    WHERE domain IS NOT NULL