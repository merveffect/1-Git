{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='run_id',
    on_schema_change='append_new_columns',
    partition_by={
      'field': 'run_ts',
      'data_type': 'timestamp',
      'granularity': 'day'
    }
  )
}}

-- Precision/recall/F1 of favorite_snt's top-10 SNT predictions, rolled up to
-- MPC subjects (favorite_snt_predictions_rolled_up_mpc), against the same
-- MPC ground truth used by favorite_mpc_subject/evaluation_metrics.sql
-- (advertising_opt_in=TRUE users' actual opted-in subjects). This is an
-- INDIRECT validation — there is no SNT-level ground truth to compare
-- against directly, so we can only check whether the SNTs we predicted are
-- topically consistent with the MPC subjects a user actually chose.

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

filtered_ground_truth AS (
  SELECT snid, actual
  FROM ground_truth
  WHERE ARRAY_LENGTH(actual) <= 6
),

predictions AS (
  SELECT
    snid,
    ARRAY(
      SELECT DISTINCT id
      FROM UNNEST(predicted_mpc_subjects) AS id
    ) AS predicted
  FROM {{ ref('favorite_snt_predictions_rolled_up_mpc') }}
),

per_user AS (
  SELECT
    g.snid,
    COUNTIF(pred IN UNNEST(g.actual)) AS true_positive,
    ANY_VALUE(ARRAY_LENGTH(p.predicted)) AS predicted_total,
    ANY_VALUE(ARRAY_LENGTH(g.actual)) AS actual_total,
    IF(COUNTIF(pred IN UNNEST(g.actual)) > 0, 1, 0) AS has_correct_prediction
  FROM filtered_ground_truth g
  JOIN predictions p USING (snid)
  CROSS JOIN UNNEST(p.predicted) AS pred
  GROUP BY g.snid
),

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
  -- Unique id per dbt run (unique_key)
  '{{ invocation_id }}' AS run_id,

  -- Partition field
  CURRENT_TIMESTAMP() AS run_ts,
  CURRENT_DATE() AS run_date,

  -- Raw counts
  total_true_positive AS true_positive,
  (total_predicted - total_true_positive) AS false_positive,
  (total_actual - total_true_positive) AS false_negative,

  -- Metrics
  SAFE_DIVIDE(total_true_positive, total_predicted) AS precision,
  SAFE_DIVIDE(total_true_positive, total_actual) AS recall,
  SAFE_DIVIDE(
    2 * total_true_positive,
    2 * total_true_positive
      + (total_predicted - total_true_positive)
      + (total_actual - total_true_positive)
  ) AS f1_score,

  -- User-level metric
  SAFE_DIVIDE(users_with_correct_prediction, total_users) AS at_least_one_correct_accuracy

FROM agg
