-- 116K known HCPs from CDP (ground truth)
SELECT DISTINCT snid
FROM {{ ref('audience_builder_big') }}
WHERE LOWER(TRIM(role)) = 'healthcare professional'
  AND snid IS NOT NULL