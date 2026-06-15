
{{config(
  materialized = 'table'
)
}}

WITH revenue_clean AS (
  SELECT
    SAPID_BPID AS bp_id,
    Financial_Year__c,
    Product_Name,
    Product_Family__c,
    revenue
  FROM {{ source('SFfinal_table_march1', 'SFfinal_table_march1') }}
  WHERE Financial_Year__c >= '2024'
),

package_flag AS (
  SELECT
    bp_id,
    Financial_Year__c,
    MAX(
      CASE
        WHEN Product_Family__c IN (
          'Nature.com Complete',
          'Nature TA',
          'Nature Journals All Packages'
        )
        AND revenue > 0
        THEN 1 ELSE 0
      END
    ) AS has_nature_package
  FROM revenue_clean
  GROUP BY 1,2
),

individual_titles AS (
  SELECT DISTINCT
    bp_id,
    Financial_Year__c,
    Product_Name
  FROM revenue_clean
  WHERE revenue > 0
    AND Product_Family__c NOT IN (
      'Nature.com Complete',
      'Nature TA',
      'Nature Journals All Packages'
    )
),

individual_counts AS (
  SELECT
    bp_id,
    Financial_Year__c,
    COUNT(DISTINCT Product_Name) AS subscribed_title_count
  FROM individual_titles
  GROUP BY 1,2
)

SELECT
  p.bp_id,
  p.Financial_Year__c,

  CASE
    WHEN p.has_nature_package = 1 THEN 68
    ELSE COALESCE(i.subscribed_title_count,0)
  END AS subscribed_title_count,

  CASE
    WHEN p.has_nature_package = 1 THEN 0
    ELSE 68 - COALESCE(i.subscribed_title_count,0)
  END AS not_subscribed_title_count,

  p.has_nature_package

FROM package_flag p

LEFT JOIN individual_counts i
  ON p.bp_id = i.bp_id
 AND p.Financial_Year__c = i.Financial_Year__c

ORDER BY
  p.bp_id,
  p.Financial_Year__c


