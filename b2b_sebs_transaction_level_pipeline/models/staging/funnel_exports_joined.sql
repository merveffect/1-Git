  SELECT
  base.transaction_date,
  sebs.month,
  sebs.month_number,
  sebs.year,
  base.transaction_id,
  LOWER(base.session_campaign) AS campaign,
  LOWER(base.m_source) AS c_source,
  LOWER(base.m_medium) AS c_medium,
  LOWER(base.ad_content) AS ad_content,
  LOWER(base.ad_network) AS ad_network,
  LOWER(base.country) AS country,
  sebs.bpid,
  sebs.organization_name,
  base.currency,
  base.item_id,
  sebs.item_name,
  sebs.item_category,
  ROUND(SUM(base.item_revenue),2) AS item_revenue,
  SUM(base.items_purchased) AS items_purchased,
  FROM {{ ref('b2b_sebs_final_static') }} sebs
  INNER JOIN {{ ref('base') }} base
  ON sebs.transaction_id = base.transaction_id
  AND sebs.item_id = base.item_id
  AND sebs.date = base.transaction_date

  -- WHERE transaction_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY) AND DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17

