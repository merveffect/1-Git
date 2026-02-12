SELECT
    cte1.* EXCEPT(parts),
    CONCAT( parts[SAFE_OFFSET(ARRAY_LENGTH(parts) - 2)], '/', parts[SAFE_OFFSET(ARRAY_LENGTH(parts) - 1)] ) AS regex_end
  FROM
    {{ref('cte1')}} cte1    