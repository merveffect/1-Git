SELECT
  * EXCEPT(
    transaction_date,
    cost_date,
    campaign,
    cost_campaign,
    c_source,
    cost_source,
    c_medium,
    cost_medium,
    isoalphatwo,
    cost_isoalphatwo,
    world_region,
    cost_world_region,
    sub_channels,
    cost_sub_channels,
    main_channels,
    cost_main_channels
  ),
  COALESCE(transaction_date, cost_date) AS Date,
  COALESCE(campaign, cost_campaign) AS campaign,
  COALESCE(c_source, cost_source) AS source,
  COALESCE(c_medium, cost_medium) AS medium,
  COALESCE(main_channels, cost_main_channels) AS main_channels,
  COALESCE(sub_channels, cost_sub_channels) AS sub_channels,
  COALESCE(isoalphatwo, cost_isoalphatwo) AS isoalphatwo,
  COALESCE(world_region, cost_world_region) AS world_region
FROM {{ ref('transaction_cost_joined') }}
