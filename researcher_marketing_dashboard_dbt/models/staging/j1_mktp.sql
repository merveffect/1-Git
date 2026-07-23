{{ config(
    materialized = "incremental",
    incremental_strategy="insert_overwrite",
    partition_by = {"field": "date","data_type": "date"},
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"]

 )}}


WITH
  facebook AS (
  SELECT
    * EXCEPT(country),
    REGEXP_REPLACE(LOWER(country), '&(.)', 'and ') AS country
  FROM
    {{ref('g1_mktp')}}
    
    {{ incremental_date_filter('date') }}

    AND SOURCE = "facebook" ),
  facebook_regions AS (
  SELECT
    DISTINCT LOWER(isoalphatwo) AS isoalphatwo,
    LOWER(world_region) AS world_region
  FROM
    {{source('ga4_ria_researcher_report','regions')}} ),
  non_facebook AS (
  SELECT
    * EXCEPT(country),
    REGEXP_REPLACE(LOWER(country), '&(.)', 'and ') AS country
  FROM
    {{ref('g1_mktp')}}
    {{ incremental_date_filter('date') }}

    AND (SOURCE != "facebook" OR SOURCE IS NULL) ),
  non_facebook_regions AS (
  SELECT
    DISTINCT REGEXP_REPLACE(LOWER(country), '&(.)', 'and ') AS regions_country,
    LOWER(isoalphatwo) AS isoalphatwo,
    LOWER(world_region) AS world_region
  FROM
    {{source('ga4_ria_researcher_report','regions')}} )
SELECT
  * EXCEPT(country,
    cost,
    clicks,
    impressions,
    video_views),
  SUM(cost) AS cost,
  SUM(clicks) AS clicks,
  SUM(impressions) AS impressions,
  SUM(video_views) AS video_views,
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
GROUP BY ALL