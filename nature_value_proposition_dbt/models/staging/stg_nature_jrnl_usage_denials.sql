{{
config(
    materialized = 'incremental',
    incremental_strategy = 'insert_overwrite',
    partition_by = {
    'field': 'Cal_date',
    'data_type': 'date',
    'granularity': 'month'
    },
    cluster_by = ['bp_id', 'grid_id', 'Jrnl_Title', 'Access_Type'])
}}


WITH base AS (

SELECT
  bp_id,
  BP_Full_Name,
  SF_SAP_ID,
  SF_Acc_ID,
  SF_Acc_Name,
  bp_country,
  grid_id,
  BP_2nd_Level,
  BP_Channel_Type,
  BP_LM,
  BP_World_Region,
  BP_Sub_Region,
  BP_Region,
  Jrnl_Title,
  Access_Type,
  Cal_Year,
  Cal_Date,
  No_Lic,
  Total_Item_Req

FROM 

{{ source('tbl_bp_monthly', 'tbl_bp_monthly') }}

WHERE

{% if is_incremental() %}

    -- Incremental: reload previous month only
     Cal_Date >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH)
     AND Cal_Date < DATE_TRUNC(CURRENT_DATE(), MONTH)

{% else %}

    -- Full refresh: from Jan 2024 until last completed month
     Cal_Date >= DATE '2024-01-01'
     AND Cal_Date < DATE_TRUNC(CURRENT_DATE(), MONTH)

{% endif %}

  AND BP_Type_Key IN ('0004', '0005')
  AND BP_ID_w_16 != 'Y'
  AND Jrnl_or_Bk = "Journal"
  AND BP_2nd_Level NOT IN (
    'A&I Service',
    'SN internal',
    'Conference/Exhibit.',
    'Author',
    'Personal'
  )

  AND BP_Channel_Type NOT IN ('Trade Relations')
  AND Jrnl_Title_No IN (
    '41586','43587','41550','41551','41587','43018','44161','41929','41556',
    '41589','44286','41557','44284','41558','43588','41559','41928','41560',
    '43016','41588','41561','44360','41562','41590','42256','41563','41591',
    '44161','42255','41592','41564','41565','41593','41566','41567','41477',
    '41596','44358','44222','41568','41569','41570','44959','41571','41572',
    '41573','43017','44287','41574','41575','41576','41577','41578','43586',
    '41579','41580','41581','41582','41583','42254','44159','41584','41585',
    '44460','41594','41893','44160','44221', "44359"
  )

),

months_2026 AS (
SELECT
  COUNT(DISTINCT EXTRACT(MONTH FROM Cal_Date)) AS months_available_2026
FROM base
WHERE Cal_Year = 2026
)


SELECT
  b.bp_id,
  b.BP_Full_Name,
  b.SF_SAP_ID,
  b.SF_Acc_ID,
  b.SF_Acc_Name,
  b.bp_country,
  b.grid_id,
  b.BP_2nd_Level,
  b.BP_Channel_Type,
  b.BP_LM,
  b.BP_World_Region,
  b.BP_Sub_Region,
  b.BP_Region,
  b.Jrnl_Title,
  b.Access_Type,
  b.Cal_Year,
  b.cal_date,

  SUM(b.No_Lic) AS No_License,

  SUM(CASE WHEN b.Cal_Year = 2024 THEN b.No_Lic ELSE 0 END) AS No_License_2024,
  SUM(CASE WHEN b.Cal_Year = 2025 THEN b.No_Lic ELSE 0 END) AS No_License_2025,
  SUM(CASE WHEN b.Cal_Year = 2026 THEN b.No_Lic ELSE 0 END) AS No_License_2026,

  SUM(CASE WHEN b.Cal_Year = 2024 THEN b.Total_Item_Req ELSE 0 END) AS Total_Item_Requests_2024,
  SUM(CASE WHEN b.Cal_Year = 2025 THEN b.Total_Item_Req ELSE 0 END) AS Total_Item_Requests_2025,
  SUM(CASE WHEN b.Cal_Year = 2026 THEN b.Total_Item_Req ELSE 0 END) AS Total_Item_Requests_2026,

  SUM(b.Total_Item_Req) AS Total_Item_Requests,

  -- dynamic projection
  SUM(CASE WHEN b.Cal_Year = 2026 THEN b.No_Lic ELSE 0 END)
  * SAFE_DIVIDE(12, m.months_available_2026)
  AS Projected_No_License_2026,

  SUM(CASE WHEN b.Cal_Year = 2026 THEN b.Total_Item_Req ELSE 0 END)
  * SAFE_DIVIDE(12, m.months_available_2026)
  AS Projected_Item_Requests_2026

FROM base b
CROSS JOIN months_2026 m

GROUP BY
  b.bp_id,
  b.BP_Full_Name,
  b.SF_SAP_ID,
  b.SF_Acc_ID,
  b.SF_Acc_Name,
  b.bp_country,
  b.grid_id,
  b.BP_2nd_Level,
  b.BP_Channel_Type,
  b.BP_LM,
  b.BP_World_Region,
  b.BP_Sub_Region,
  b.BP_Region,
  b.Jrnl_Title,
  b.Access_Type,
  b.Cal_Year,
  b.cal_date,
  m.months_available_2026

HAVING
  SUM(b.No_Lic + b.Total_Item_Req) > 0