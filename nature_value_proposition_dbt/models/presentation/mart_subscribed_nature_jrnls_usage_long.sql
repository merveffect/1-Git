{{config(
  materialized = 'table'
)
}}


/* =========================================================
   1. JOURNAL METADATA
========================================================= */

WITH journal_meta AS (

SELECT DISTINCT
    LOWER(TRIM(journal_title)) AS journal_title_clean
FROM

{{ref('stg_jrnl_metadata')}}

),

/* =========================================================
   2. REVENUE
========================================================= */

revenue_clean AS (

SELECT
    SAPID_BPID AS bp_id,
    Financial_Year__c,

    LOWER(TRIM(Product_Name)) AS product_name_clean,

    Product_Family__c,
    revenue

FROM

{{source('SFfinal_table_march1','SFfinal_table_march1')}}

WHERE Financial_Year__c IN ('2024','2025','2026')

),

/* =========================================================
   3. PACKAGE SUBSCRIPTIONS
========================================================= */

package_flag AS (

SELECT
    bp_id,
    Financial_Year__c,

    MAX(
        CASE
            WHEN Product_Family__c IN (
                'Nature.com Complete',
                'Nature TA',
                'Nature Journals All Packages',
                'Nature Journals',
                'Nature Advance'
            )
            AND revenue > 0
            THEN 1
            ELSE 0
        END
    ) AS has_package

FROM revenue_clean

GROUP BY
    bp_id,
    Financial_Year__c

),

/* =========================================================
   4. INDIVIDUAL TITLE SUBSCRIPTIONS
========================================================= */

individual_titles AS (

SELECT DISTINCT

    r.bp_id,

    r.Financial_Year__c,

    j.journal_title_clean

FROM revenue_clean r

INNER JOIN journal_meta j

ON r.product_name_clean = j.journal_title_clean

WHERE

    r.revenue > 0

    AND r.Product_Family__c NOT IN (
        'Nature.com Complete',
        'Nature TA',
        'Nature Journals All Packages',
        'Nature Journals',
        'Nature Advance'
    )

),

/* =========================================================
   5. COUNTER DATA
========================================================= */

denials AS (

SELECT

    bp_id,

    BP_Full_Name,

    grid_id,

    Jrnl_Title,

    LOWER(TRIM(Jrnl_Title)) AS journal_title_clean,

    Access_Type,

    Total_Item_Requests_2024,

    Total_Item_Requests_2025,

    Projected_Item_Requests_2026

FROM

{{ref("stg_nature_jrnl_usage_denials")}}
),

/* =========================================================
   6. 2024
========================================================= */

usage_2024 AS (

SELECT

    d.bp_id,
    d.BP_Full_Name,
    d.grid_id,
    d.Jrnl_Title,
    d.Access_Type,

    2024 AS Year,

    SUM(d.Total_Item_Requests_2024) AS Requests

FROM denials d

LEFT JOIN package_flag p
ON d.bp_id=p.bp_id
AND p.Financial_Year__c='2024'

LEFT JOIN individual_titles i
ON d.bp_id=i.bp_id
AND i.Financial_Year__c='2024'
AND d.journal_title_clean=i.journal_title_clean

WHERE
    p.has_package=1
    OR i.journal_title_clean IS NOT NULL

GROUP BY
    d.bp_id,
    d.BP_Full_Name,
    d.grid_id,
    d.Jrnl_Title,
    d.Access_Type

),

/* =========================================================
   7. 2025
========================================================= */

usage_2025 AS (

SELECT

    d.bp_id,
    d.BP_Full_Name,
    d.grid_id,
    d.Jrnl_Title,
    d.Access_Type,

    2025 AS Year,

    SUM(d.Total_Item_Requests_2025) AS Requests

FROM denials d

LEFT JOIN package_flag p
ON d.bp_id=p.bp_id
AND p.Financial_Year__c='2025'

LEFT JOIN individual_titles i
ON d.bp_id=i.bp_id
AND i.Financial_Year__c='2025'
AND d.journal_title_clean=i.journal_title_clean

WHERE
    p.has_package=1
    OR i.journal_title_clean IS NOT NULL

GROUP BY
    d.bp_id,
    d.BP_Full_Name,
    d.grid_id,
    d.Jrnl_Title,
    d.Access_Type

),

/* =========================================================
   8. 2026
========================================================= */

usage_2026 AS (

SELECT

    d.bp_id,
    d.BP_Full_Name,
    d.grid_id,
    d.Jrnl_Title,
    d.Access_Type,

    2026 AS Year,

    SUM(d.Projected_Item_Requests_2026) AS Requests

FROM denials d

LEFT JOIN package_flag p
ON d.bp_id=p.bp_id
AND p.Financial_Year__c='2026'

LEFT JOIN individual_titles i
ON d.bp_id=i.bp_id
AND i.Financial_Year__c='2026'
AND d.journal_title_clean=i.journal_title_clean

WHERE
    p.has_package=1
    OR i.journal_title_clean IS NOT NULL

GROUP BY
    d.bp_id,
    d.BP_Full_Name,
    d.grid_id,
    d.Jrnl_Title,
    d.Access_Type

)

/* =========================================================
   FINAL
========================================================= */

SELECT * FROM usage_2024

UNION ALL

SELECT * FROM usage_2025

UNION ALL

SELECT * FROM usage_2026
