
{{config(
  materialized = 'table'
)
}}

with
/* =========================================================
   1. TOP 10 NON-SUBSCRIBED DENIED JOURNALS
========================================================= */

all_denials AS (

SELECT

    bp_id,
    grid_id,

    Jrnl_Title AS journal_title,

    SUM(Projected_No_License_2026) AS projected_denials_2026

FROM

{{ref('stg_nature_jrnl_usage_denials')}}

GROUP BY

    bp_id,
    grid_id,
    Jrnl_Title

),

all_denials_ranked AS (

SELECT
    *,

    SUM(projected_denials_2026) OVER(
        PARTITION BY bp_id
    ) AS total_bp_denials,

    SUM(projected_denials_2026) OVER(
        PARTITION BY bp_id
        ORDER BY projected_denials_2026 DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_denials

FROM all_denials

),

denial_signal AS (

SELECT

    bp_id,
    grid_id,
    journal_title,
    projected_denials_2026,

    SAFE_DIVIDE(
        cumulative_denials,
        total_bp_denials
    ) AS cumulative_denial_pct,

    CASE
        WHEN SAFE_DIVIDE(
            cumulative_denials,
            total_bp_denials
        ) <= 0.60
        THEN 'High'
        ELSE 'Moderate'
    END AS denial_signal

FROM all_denials_ranked

),  


denied_titles AS (

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

{{ref('mart_top_10_denied_nature_jrnls_per_institute')}}

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

{{ref('mart_for2_jrnl_mapping')}}

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

{{ref('mart_sdg_jrnl_mapping')}}

GROUP BY
    bp_id,
    grid_id,
    journal_title

),

/* =========================================================
   4. FUNDING SIGNAL
   YES IF A GRANT MAPPING EXISTS
========================================================= */

funding AS (

SELECT
    bp_id,
    grid_id,
    journal_title,

    'Yes' AS funding_signal,

    COUNT(*) AS grants,

    SUM(total_funding_eur) AS total_funding_eur

FROM
{{ref('mart_for2_jrnl_mapping_grant')}}

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

    CASE
      WHEN f.journal_title IS NOT NULL THEN 'YES'
      ELSE 'N/A'
    END AS funding,

    IF(fr.for2_signal = 'YES', 'YES', 'No') AS for2,

    IF(s.sdg_signal = 'YES', 'YES', 'No') AS sdg,

    /* ------------------------------------
       FIT SCORE
    ------------------------------------ */

    (
      IF(f.journal_title IS NOT NULL,1,0)
      + IF(fr.for2_signal = 'YES',1,0)
      + IF(s.sdg_signal = 'YES',1,0)
    ) AS fit_score,

    COALESCE(f.grants,0) AS grants,

    COALESCE(f.total_funding_eur,0) AS total_funding_eur

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



/* =========================================================
   7. FINAL LOGIC
========================================================= */

final AS (

SELECT

    b.*,

    COALESCE(ds.denial_signal,'NO') AS denial_signal,

    ROUND(ds.cumulative_denial_pct*100,1) AS cumulative_denial_pct,

    CASE
        WHEN fit_score = 3 THEN 'Best Fit'
        WHEN fit_score = 2 THEN 'Strong Match'
        WHEN fit_score = 1 THEN 'Relevant'
        ELSE 'Emerging Opportunity'
    END AS recommendation_strength

FROM base b

LEFT JOIN denial_signal ds
ON b.bp_id = ds.bp_id
AND b.grid_id = ds.grid_id
AND LOWER(TRIM(b.journal_title))
    = LOWER(TRIM(ds.journal_title))

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
cumulative_denial_pct,

    funding,
    for2,
    sdg,

    recommendation_strength,

    fit_score,

    grants,
    total_funding_eur,

    total_denials,
    total_requests,
    Projected_Item_Requests_2026,

    launch_year

FROM final

ORDER BY

CASE recommendation_strength
    WHEN 'Best Fit' THEN 1
    WHEN 'Strong Match' THEN 2
    WHEN 'Relevant' THEN 3
    WHEN 'Emerging Opportunity' THEN 4
    ELSE 5
END,
fit_score DESC,
projected_denials_2026 DESC,
journal_title
