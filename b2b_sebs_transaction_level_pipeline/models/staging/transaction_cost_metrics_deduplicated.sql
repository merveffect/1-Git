WITH ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY Date, campaign, source, medium, sub_channels, isoalphatwo, transaction_id, item_id
      ORDER BY transaction_id, item_id
    ) AS row_num
  FROM {{ ref('transaction_cost_metrics_aggregated') }}
)

SELECT
  * EXCEPT(cost, clicks, impressions, row_num),
  CASE
    WHEN row_num = 1 AND isoalphatwo IS NOT NULL THEN cost
    WHEN isoalphatwo IS NULL THEN cost
    ELSE 0
  END AS cost,
  CASE
    WHEN row_num = 1 AND isoalphatwo IS NOT NULL THEN clicks
    WHEN isoalphatwo IS NULL THEN clicks
    ELSE 0
  END AS clicks,
  CASE
    WHEN row_num = 1 AND isoalphatwo IS NOT NULL THEN impressions
    WHEN isoalphatwo IS NULL THEN impressions
    ELSE 0
  END AS impressions
FROM ranked
