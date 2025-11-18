{{ config(
    materialized = "incremental",
    partition_by = {"field": "date"},
    
 )}}


SELECT * EXCEPT(country, cost, clicks, impressions),
sum(cost) as cost,
sum(clicks) as clicks,
sum(impressions) as impressions

FROM
(
(SELECT * except(regions_country) FROM (

  (SELECT * EXCEPT(country),
  regexp_replace(lower(country), '&(.)', 'and ') as country

  FROM `snproject-cbb9ca25.ria_ops_dataset.stage1_extdisplay_channel_grouping_2025` where source != "facebook") AS main
#facebook is excluded and dealt with in a separate query because it has a different country syntax to all other ad platforms
  LEFT JOIN

  (
    SELECT DISTINCT
    regexp_replace(lower(country), '&(.)', 'and ') AS regions_country,
    lower(isoalphatwo) as isoalphatwo,
    lower(world_region) as world_region
    FROM `snproject-cbb9ca25.ria_researcher_report.regions`
  ) AS regions

  ON main.country = regions_country))

  UNION ALL

  (SELECT * FROM
  (
  (SELECT * EXCEPT(country),
  regexp_replace(lower(country), '&(.)', 'and ') as country

  FROM FROM {{ref('step1_channel_grouping')}} where source = "facebook") AS main

  LEFT JOIN

  (
    SELECT DISTINCT
    lower(isoalphatwo) as isoalphatwo,
    lower(world_region) as world_region
    FROM {{source('ria_researcher_report','regions')}}
  ) AS regions

  ON main.country = isoalphatwo
  )
  )
  )
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,12,13