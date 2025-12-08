WITH ground_truth AS (
  SELECT
    snid,
    ARRAY(
      SELECT DISTINCT subj
      FROM UNNEST(REGEXP_EXTRACT_ALL(subjects, r'"(\d+)"')) AS subj
    ) AS actual
  FROM {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
  WHERE advertising_opt_in = TRUE
    AND subjects IS NOT NULL
),
-- Filter: only users with ≤ 6 ground truth subjects
filtered_ground_truth AS (
  SELECT
    snid,
    actual
  FROM ground_truth
  WHERE ARRAY_LENGTH(actual) <= 6
),

predictions AS (
  SELECT
    snid,
    ARRAY(
      SELECT DISTINCT id
      FROM UNNEST(SPLIT(REPLACE(top_3_marketing_pref_ids, ';', ','))) AS id
      WHERE TRIM(id) != ''
    ) AS predicted
  FROM {{ ref('snid_to_mktps_step2') }}
),

-- Per-user TP, predicted_total, actual_total, user-level accuracy
per_user AS (
  SELECT
    g.snid,
    COUNTIF(pred IN UNNEST(g.actual)) AS true_positive,
    ANY_VALUE(ARRAY_LENGTH(p.predicted)) AS predicted_total,
    ANY_VALUE(ARRAY_LENGTH(g.actual)) AS actual_total,
    -- At least one correct prediction for this user?
    IF(COUNTIF(pred IN UNNEST(g.actual)) > 0, 1, 0) AS has_correct_prediction
  FROM filtered_ground_truth g
  JOIN predictions p USING (snid)
  CROSS JOIN UNNEST(p.predicted) AS pred
  GROUP BY g.snid
),

-- Aggregate: global TP, FP, FN, counters
agg AS (
  SELECT
    SUM(true_positive) AS total_true_positive,
    SUM(predicted_total) AS total_predicted,
    SUM(actual_total) AS total_actual,
    SUM(has_correct_prediction) AS users_with_correct_prediction,
    COUNT(*) AS total_users
  FROM per_user
)

SELECT
  -- Raw counts
  total_true_positive AS true_positive,
  (total_predicted - total_true_positive) AS false_positive,
  (total_actual - total_true_positive) AS false_negative,

  -- Metrics
  SAFE_DIVIDE(total_true_positive, total_predicted) AS precision,
  SAFE_DIVIDE(total_true_positive, total_actual) AS recall,
  SAFE_DIVIDE(
    2 * total_true_positive,
    2 * total_true_positive + (total_predicted - total_true_positive) + (total_actual - total_true_positive)
  ) AS f1_score,

  -- NEW METRICS
  -- Overall accuracy = correct predictions / all predictions made
  SAFE_DIVIDE(total_true_positive, total_predicted) AS overall_accuracy,

  -- At least one correct hit per user = user-level accuracy
  SAFE_DIVIDE(users_with_correct_prediction, total_users) AS at_least_one_correct_accuracy

FROM agg
