SELECT
  m.Date,
  m.transaction_id,
  m.month,
  m.month_number,
  m.year,
  m.campaign,
  m.source,
  m.medium,
  m.ad_network,
  m.ad_content,
  m.main_channels,
  m.sub_channels,
  c.country,
  m.isoalphatwo,
  m.world_region,
  m.bpid,
  m.organization_name,
  m.item_id,
  m.item_name,
  m.item_category,
  m.item_revenue,
  m.items_purchased,
  m.currency,
  m.cost,
  m.clicks,
  m.impressions
FROM {{ ref('transaction_cost_metrics_deduplicated') }} AS m
LEFT JOIN (
  SELECT DISTINCT
    LOWER(isoalphatwo) AS country_isoalphatwo,
    country
  FROM {{ source('ga4_ria_researcher_report', 'countries') }}
) AS c
  ON m.isoalphatwo = c.country_isoalphatwo
