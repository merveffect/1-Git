WITH date_bounds AS (
  SELECT
    MIN(evt_date) AS min_date,
    MAX(evt_date) AS max_date
  FROM {{ ref('bc_collections_megatable') }}
),

expected_dates AS (
  SELECT day AS evt_date
  FROM date_bounds,
  UNNEST(GENERATE_DATE_ARRAY(min_date, max_date)) AS day
),

actual_dates AS (
  SELECT DISTINCT evt_date
  FROM {{ ref('bc_collections_megatable') }}
)

SELECT
  e.evt_date AS missing_evt_date
FROM expected_dates e
LEFT JOIN actual_dates a
  ON e.evt_date = a.evt_date
WHERE a.evt_date IS NULL
