{{config(
  materialized = 'table'
)
}}

WITH aggregated AS (
  SELECT
    bp_id,
    BP_Full_Name,
    grid_id,
    Jrnl_Title,
    Access_Type,

    SUM(Total_Item_Requests_2024) AS req_2024,
    SUM(Total_Item_Requests_2025) AS req_2025,
    SUM(Projected_Item_Requests_2026) AS req_2026

  FROM 
  
  {{ ref('int_nature_jrnl_subscribed') }}


  GROUP BY
    bp_id,
    BP_Full_Name,
    grid_id,
    Jrnl_Title,
    Access_Type
)

-- 🔥 UNPIVOT STARTS HERE

SELECT
  bp_id,
  BP_Full_Name,
  grid_id,
  Jrnl_Title,
  Access_Type,
  2024 AS Year,
  req_2024 AS Requests

FROM aggregated

UNION ALL

SELECT
  bp_id,
  BP_Full_Name,
  grid_id,
  Jrnl_Title,
  Access_Type,
  2025 AS Year,
  req_2025 AS Requests

FROM aggregated

UNION ALL

SELECT
  bp_id,
  BP_Full_Name,
  grid_id,
  Jrnl_Title,
  Access_Type,
  2026 AS Year,
  req_2026 AS Requests

FROM aggregated
