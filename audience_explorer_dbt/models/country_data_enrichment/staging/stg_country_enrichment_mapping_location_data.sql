    SELECT DISTINCT
        alpha_2_code,
        CASE 
            WHEN alpha_2_code = 'GB' THEN '.uk' 
            ELSE CONCAT('.', LOWER(alpha_2_code)) 
        END AS generated_tld,
        springer_nature_data_standard_location_name AS standard_name
    FROM {{ref('raw_full_location_standard') }}
    WHERE code_status = 'Current'