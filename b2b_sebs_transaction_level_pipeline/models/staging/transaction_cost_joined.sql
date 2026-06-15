SELECT
  *
FROM {{ ref('transaction_item_metrics_aggregated') }} AS tx
FULL OUTER JOIN {{ ref('j1_mktp_b2b') }} AS c
  ON tx.transaction_date = c.cost_date
  AND tx.campaign = c.cost_campaign
  AND tx.c_source = c.cost_source
  AND tx.c_medium = c.cost_medium
  AND tx.main_channels = c.cost_main_channels
  AND tx.sub_channels = c.cost_sub_channels
  AND tx.isoalphatwo = c.cost_isoalphatwo
  AND tx.world_region = c.cost_world_region
