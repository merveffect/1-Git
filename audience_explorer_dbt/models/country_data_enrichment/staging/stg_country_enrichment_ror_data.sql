    -- Institutional Domain Reference (Tier 3)
    SELECT DISTINCT
        domain,
            CASE
                WHEN country_name = 'Vietnam' THEN 'Viet Nam'
                WHEN country_name = 'The Gambia' THEN 'Gambia'
                ELSE country_name
            END AS ror_country
    FROM {{ref('raw_ror_table') }}
    WHERE domain IS NOT NULL