
{{config(
  materialized = 'table'
)
}}

WITH journal_agg AS (

SELECT
  d.bp_id,
  d.BP_full_name,
  d.grid_id,
  d.Jrnl_Title,
  LOWER(TRIM(d.Jrnl_Title)) AS journal_title_clean,

  SUM(d.No_License_2024) AS No_License_2024,
  SUM(d.No_License_2025) AS No_License_2025,
  SUM(d.No_License_2026) AS No_License_2026,

  SUM(d.Projected_No_License_2026) AS Projected_No_License_2026,

  SUM(d.No_License) AS total_denials,   -- 👈 this is your ranking metric
  SUM(d.Total_Item_Requests) AS total_requests,
  SUM(d.Projected_Item_Requests_2026) AS Projected_Item_Requests_2026

FROM

{{ref('stg_nature_jrnl_usage_denials') }} d

GROUP BY
  d.bp_id,
  d.BP_full_name,
  d.grid_id,
  d.Jrnl_Title,
  journal_title_clean

HAVING
  SUM(d.No_License) > 0   -- 🔥 updated to match ranking logic
),

/* 🔹 subscribed titles in 2026 */

subscribed_2026 AS (

SELECT DISTINCT
  bp_id,
  grid_id,
  LOWER(TRIM(Jrnl_Title)) AS journal_title_clean

FROM
  {{ref('mart_subscribed_nature_jrnls_usage_2024_2026') }}
),

/* 🔹 keep ONLY non-subscribed */

not_subscribed AS (

SELECT j.*

FROM journal_agg j

LEFT JOIN subscribed_2026 s
  ON j.bp_id = s.bp_id
 AND j.grid_id = s.grid_id
 AND j.journal_title_clean = s.journal_title_clean

WHERE s.journal_title_clean IS NULL
),

/* 🔹 rank based on total denials */

ranked AS (

SELECT *,
ROW_NUMBER() OVER(
  PARTITION BY bp_id
  ORDER BY total_denials DESC   -- ✅ changed here
) AS rn

FROM not_subscribed
)

SELECT
  r.*,
  m.launch_year

FROM ranked r

LEFT JOIN
 {{ref('stg_jrnl_metadata') }} m
  ON r.journal_title_clean = m.journal_title_clean

WHERE rn <= 10


