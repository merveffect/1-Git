
{{config(
  materialized = 'table'
)
}}

/* =========================
1️⃣ Metadata (68 journals)
========================= */
WITH journal_meta AS (
  SELECT DISTINCT
    journal_id,
    LOWER(TRIM(journal_title)) AS journal_title_clean
  FROM 
  {{ ref('stg_jrnl_metadata') }}
),

/* =========================
2️⃣ Revenue base
========================= */
revenue_clean AS (
  SELECT
    SAPID_BPID AS bp_id,
    Financial_Year__c,
    LOWER(TRIM(Product_Name)) AS product_name_clean,
    Product_Family__c,
    revenue
  FROM 
    {{ source('SFfinal_table_march1', 'SFfinal_table_march1') }}
  WHERE Financial_Year__c between '2024' and '2026'

),

/* =========================
3️⃣ Package flag
========================= */
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

/* =========================
4️⃣ Match ONLY valid Nature journals
========================= */
individual_titles AS (
  SELECT DISTINCT
    r.bp_id,
    r.Financial_Year__c,
    j.journal_id   -- 🔥 use ID, not name
  FROM revenue_clean r
  INNER JOIN journal_meta j
    ON r.product_name_clean = j.journal_title_clean
  WHERE
    r.revenue > 0
    AND r.Product_Family__c NOT IN (
      'Nature.com Complete',
      'Nature TA',
      'Nature Journals All Packages'
    )
),

/* =========================
5️⃣ Count using journal_id
========================= */
individual_counts AS (
  SELECT
    bp_id,
    Financial_Year__c,
    COUNT(DISTINCT journal_id) AS individual_title_count
  FROM individual_titles
  GROUP BY 1,2
)

/* =========================
6️⃣ Final
========================= */
SELECT
  p.bp_id,
  p.Financial_Year__c,

  CASE
    WHEN p.has_nature_package = 1 THEN 68
    ELSE COALESCE(i.individual_title_count, 0)
  END AS subscribed_title_count,

  p.has_nature_package

FROM package_flag p

LEFT JOIN individual_counts i
  ON p.bp_id = i.bp_id
 AND p.Financial_Year__c = i.Financial_Year__c

ORDER BY
  p.bp_id,
  p.Financial_Year__c


