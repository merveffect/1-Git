
{{config(
  materialized = 'table'
)
}}

SELECT
  bp_id,
  BP_Full_Name,
  grid_id,
  Jrnl_Title,
  Access_Type,

  SUM(Total_Item_Requests_2024) AS Total_Item_Requests_2024,
  SUM(Total_Item_Requests_2025) AS Total_Item_Requests_2025,
  SUM(Total_Item_Requests_2026) AS Total_Item_Requests_2026,

  -- added projection
  SUM(Projected_Item_Requests_2026) AS Projected_Item_Requests_2026,
  SUM(Total_Item_Requests) AS Total_Item_Requests_All_Years

FROM 

 {{ ref('int_nature_jrnl_subscribed') }}

GROUP BY
  bp_id,
  BP_Full_Name,
  grid_id,
  Jrnl_Title,
  Access_Type

ORDER BY
  bp_id,
  Jrnl_Title



