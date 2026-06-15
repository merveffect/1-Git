
{{config(
  materialized = 'table'
)
}}

/* =========================================================
   1. TOP 10 NON-SUBSCRIBED DENIED JOURNALS
========================================================= */

WITH denied_titles AS (

SELECT
    bp_id,
    BP_full_name AS BP_Full_Name,
    grid_id,

    Jrnl_Title AS journal_title,

    total_denials,

    Projected_No_License_2026 AS projected_denials_2026,

    total_requests,

    Projected_Item_Requests_2026,

    launch_year

FROM

{{ref('mart_top_10_denied_nature_jrnls_per_institute') }}

),

/* =========================================================
   2. FOR2 SIGNAL
========================================================= */

for2 AS (

SELECT
    bp_id,
    grid_id,
    journal_title,

    MAX(match_flag) AS for2_signal

FROM

{{ref('mart_for2_jrnl_mapping') }}

GROUP BY
    bp_id,
    grid_id,
    journal_title
),

/* =========================================================
   3. SDG SIGNAL
========================================================= */

sdg AS (

SELECT
    bp_id,
    grid_id,
    journal_title,

    MAX(match_flag) AS sdg_signal

FROM

{{ref('mart_sdg_jrnl_mapping') }}

GROUP BY
    bp_id,
    grid_id,
    journal_title
),

/* =========================================================
   4. FUNDING SIGNAL
========================================================= */

funding AS (

SELECT
    bp_id,
    grid_id,
    journal_title,

    CASE
      WHEN SUM(total_funding_eur) > 0 THEN 'Yes'
      ELSE 'No'
    END AS funding_signal

FROM

{{ref('mart_for2_jrnl_mapping_grant') }}

GROUP BY
    bp_id,
    grid_id,
    journal_title
),

/* =========================================================
   5. BASE RECOMMENDATION LOGIC
========================================================= */

base AS (

SELECT

    d.bp_id,
    d.BP_Full_Name,
    d.grid_id,

    d.journal_title,

    d.total_denials,
    d.projected_denials_2026,

    d.total_requests,
    d.Projected_Item_Requests_2026,

    d.launch_year,

    /* ------------------------------------
       SIGNALS
    ------------------------------------ */

    IF(f.funding_signal = 'Yes', 'Yes', 'No') AS funding,

    IF(fr.for2_signal = 'YES', 'Yes', 'No') AS for2,

    IF(s.sdg_signal = 'YES', 'Yes', 'No') AS sdg,

    /* ------------------------------------
       FIT SCORE
    ------------------------------------ */

    (
      IF(f.funding_signal = 'Yes',1,0)
      + IF(fr.for2_signal = 'YES',1,0)
      + IF(s.sdg_signal = 'YES',1,0)
    ) AS fit_score

FROM denied_titles d

LEFT JOIN funding f
ON d.bp_id = f.bp_id
AND d.grid_id = f.grid_id
AND LOWER(TRIM(d.journal_title)) =
    LOWER(TRIM(f.journal_title))

LEFT JOIN for2 fr
ON d.bp_id = fr.bp_id
AND d.grid_id = fr.grid_id
AND LOWER(TRIM(d.journal_title)) =
    LOWER(TRIM(fr.journal_title))

LEFT JOIN sdg s
ON d.bp_id = s.bp_id
AND d.grid_id = s.grid_id
AND LOWER(TRIM(d.journal_title)) =
    LOWER(TRIM(s.journal_title))

),

/* =========================================================
   6. TOP 60% DENIAL CONTRIBUTION
========================================================= */

ranked AS (

SELECT
    *,

    SUM(projected_denials_2026) OVER (
        PARTITION BY bp_id
    ) AS total_bp_denials,

    SUM(projected_denials_2026) OVER (
        PARTITION BY bp_id
        ORDER BY projected_denials_2026 DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_denials

FROM base

),

/* =========================================================
   7. FINAL LOGIC
========================================================= */

final AS (

SELECT
    *,

    CASE
      WHEN SAFE_DIVIDE(
          cumulative_denials,
          total_bp_denials
      ) <= 0.6
      THEN 'Yes'
      ELSE 'No'
    END AS denial_signal,

    CASE
      WHEN fit_score = 3 THEN 'Best Fit'
      WHEN fit_score = 2 THEN 'Strong Match'
      WHEN fit_score = 1 THEN 'Relevant'
      ELSE 'Emerging Opportunity'
    END AS recommendation_strength

FROM ranked

)

/* =========================================================
   FINAL OUTPUT
========================================================= */

SELECT

    bp_id,
    BP_Full_Name,
    grid_id,

    journal_title,

    projected_denials_2026 AS denials,

    denial_signal,

    funding,
    for2,
    sdg,

    recommendation_strength,

    fit_score,

    total_denials,
    total_requests,
    Projected_Item_Requests_2026,

    launch_year

FROM final

ORDER BY
    bp_id,
    fit_score DESC,
    projected_denials_2026 DESC
