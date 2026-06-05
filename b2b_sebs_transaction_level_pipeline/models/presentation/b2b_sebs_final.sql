SELECT
  Date,
  transaction_id,
  month,
  month_number,
  year,
  item_id,
  item_name,
  item_category,
  SUM(item_revenue) AS item_revenue,
  currency,
  SUM(items_purchased) AS items_purchased,
  bpid,
  organization_name,
  campaign,
  source,
  medium,
  ad_network,
  ad_content,
  main_channels,
  sub_channels,
  country,
  isoalphatwo,
  world_region,
  SUM(cost) AS cost,
  SUM(clicks) AS clicks,
  SUM(impressions) AS impressions,
  CASE
    WHEN sub_channels IN ('ai seo', 'traditional seo') THEN '3. of which: SEO'
    WHEN REGEXP_CONTAINS(campaign, '^\\((direct|organic|referral|not set)\\)$')
      AND REGEXP_CONTAINS(sub_channels, '^(other channels|referral|organic social|baidu authorisation)$')
      THEN '2. of which: Non Marketing'
    ELSE '1. of which: Marketing'
  END AS revenue_breakdown,
  CASE
    WHEN bpid IS NULL OR bpid = '(not set)' THEN FALSE
    ELSE TRUE
  END AS bpid_present,
  COUNT(1) AS row_count
FROM {{ ref('transaction_cost_country_enriched') }}
WHERE transaction_id IS NOT NULL
GROUP BY
  Date,
  transaction_id,
  month,
  month_number,
  year,
  item_id,
  item_name,
  item_category,
  currency,
  bpid,
  organization_name,
  campaign,
  source,
  medium,
  ad_network,
  ad_content,
  main_channels,
  sub_channels,
  country,
  isoalphatwo,
  world_region
