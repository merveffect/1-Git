
{{config(
  materialized = 'table'
)
}}


WITH revenue_map AS (
  SELECT
    SAPID_BPID AS bp_id,
    REGEXP_REPLACE(LOWER(TRIM(Product_Name)), r'[^a-z0-9]', '') AS product_name,
    Product_Family__c,
    revenue
  FROM 

  {{source('SFfinal_table_march1','SFfinal_table_march1')}}

  WHERE Financial_Year__c = '2026'
),

denials AS (
  SELECT
    d.bp_id,
    d.BP_Full_Name,
    d.grid_id,
    d.Jrnl_Title,
    d.Access_Type,
    REGEXP_REPLACE(LOWER(TRIM(d.Jrnl_Title)), r'[^a-z0-9]', '') AS journal_key,

    d.Total_Item_Requests_2024,
    d.Total_Item_Requests_2025,
    d.Total_Item_Requests_2026,
    d.Projected_Item_Requests_2026,   -- added
    d.Total_Item_Requests

  FROM {{ref("stg_nature_jrnl_usage_denials")}} d
),

license_flags AS (
  SELECT
    d.bp_id,
    d.grid_id,
    d.Jrnl_Title,

    MAX(
      CASE
        WHEN rm.revenue > 0
         AND rm.product_name = d.journal_key
        THEN 1 ELSE 0
      END
    ) AS has_title_license_2026,

    MAX(
      CASE
        WHEN rm.revenue > 0
         AND rm.Product_Family__c IN (
           'Nature.com Complete',
           'Nature TA',
           'Nature Journals All Packages'
         )
        THEN 1 ELSE 0
      END
    ) AS has_nature_package_2026

  FROM denials d
  LEFT JOIN revenue_map rm
    ON d.bp_id = rm.bp_id

  GROUP BY
    d.bp_id,
    d.grid_id,
    d.Jrnl_Title
),

subscribed_titles_2026 AS (
  SELECT
    d.*
  FROM denials d
  JOIN license_flags lf
    ON d.bp_id = lf.bp_id
   
   AND d.Jrnl_Title = lf.Jrnl_Title
  WHERE
    lf.has_title_license_2026 = 1
     OR lf.has_nature_package_2026 = 1
)

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

FROM subscribed_titles_2026

GROUP BY
  bp_id,
  BP_Full_Name,
  grid_id,
  Jrnl_Title,
  Access_Type

ORDER BY
  bp_id,
  Jrnl_Title


