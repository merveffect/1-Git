SELECT
SUM(cost) AS cost,
SUM(clicks) AS clicks,
SUM(impressions) AS impressions,
date AS cost_date,
campaign AS cost_campaign,
source AS cost_source,
medium AS cost_medium,
sub_channels AS cost_sub_channels,
main_channels AS cost_main_channels,
isoalphatwo AS cost_isoalphatwo,
world_region AS cost_world_region
FROM {{ ref('j1_mktp_b2b') }}
WHERE date > '2024-04-01'
-- FROM `snproject-cbb9ca25.ga4_ria_researcher_report.j1_mktp`
-- WHERE date between DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY) and DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
-- WHERE date BETWEEN '2024-06-01' AND '2024-06-30'
GROUP BY cost_date, cost_campaign, cost_source, cost_medium, cost_sub_channels, cost_main_channels, cost_isoalphatwo, cost_world_region