
  
    

    create or replace table `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j1_mktp`
      
    partition by date
    

    
    OPTIONS(
      description=""""""
    )
    as (
      


WITH
  facebook AS (
  SELECT
    * EXCEPT(country),
    REGEXP_REPLACE(LOWER(country), '&(.)', 'and ') AS country
  FROM
    `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`g1_mktp`
    
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-10-28')

    AND SOURCE = "facebook" ),
  facebook_regions AS (
  SELECT
    DISTINCT LOWER(isoalphatwo) AS isoalphatwo,
    LOWER(world_region) AS world_region
  FROM
    `snproject-cbb9ca25`.`ga4_ria_researcher_report`.`regions` ),
  non_facebook AS (
  SELECT
    * EXCEPT(country),
    REGEXP_REPLACE(LOWER(country), '&(.)', 'and ') AS country
  FROM
    `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`g1_mktp`
     
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-10-28')

    AND SOURCE != "facebook" ),
  non_facebook_regions AS (
  SELECT
    DISTINCT REGEXP_REPLACE(LOWER(country), '&(.)', 'and ') AS regions_country,
    LOWER(isoalphatwo) AS isoalphatwo,
    LOWER(world_region) AS world_region
  FROM
    `snproject-cbb9ca25`.`ga4_ria_researcher_report`.`regions` )
SELECT
  * EXCEPT(country,
    cost,
    clicks,
    impressions),
  SUM(cost) AS cost,
  SUM(clicks) AS clicks,
  SUM(impressions) AS impressions
FROM ( (
    SELECT
      * EXCEPT (regions_country)
    FROM
      non_facebook
    LEFT JOIN
      non_facebook_regions
    ON
      non_facebook.country = regions_country )
  UNION ALL (
    SELECT
      *
    FROM
      facebook
    LEFT JOIN
      facebook_regions
    ON
      facebook.country = isoalphatwo ))
GROUP BY
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11
    );
  