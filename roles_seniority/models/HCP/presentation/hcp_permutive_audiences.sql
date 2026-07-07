WITH base_data AS (
    SELECT 
        snid,
        hcp_bucket,
        'hcp001' AS main_code,
        CASE 
            WHEN LOWER(TRIM(hcp_bucket)) LIKE '%practitioner%' THEN 'hcp0prctcnr'
            WHEN LOWER(TRIM(hcp_bucket)) LIKE '%researcher%'   THEN 'hcp0rsrchr'
            WHEN LOWER(TRIM(hcp_bucket)) LIKE '%administrator%' THEN 'hcp0admnstr'
            ELSE NULL
        END AS sub_code
    FROM {{ ref('hcp_unified') }}
),

filtered_consents AS (
    SELECT 
        b.snid,
        CASE 
            WHEN b.sub_code IS NOT NULL THEN CONCAT(b.main_code, ',', b.sub_code)
            ELSE b.main_code
        END AS final_segment_codes
    FROM base_data b
    INNER JOIN {{ ref('audience_builder_big') }} c ON b.snid = c.snid
    WHERE (c.mkt_pref_opt_in = true or c.advertising_opt_in = true) 
)

SELECT 
    CONCAT(snid, '\t', final_segment_codes) AS permutive_row
FROM filtered_consents