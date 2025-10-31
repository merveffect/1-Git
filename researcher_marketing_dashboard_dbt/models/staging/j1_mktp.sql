{{ config(
    materialized = "incremental",
    partition_by = {"field": "date"},
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"]

 )}}


WITH
  facebook AS (
  SELECT
    * EXCEPT(country),
    REGEXP_REPLACE(LOWER(country), '&(.)', 'and ') AS country
  FROM
    {{ref('g1_mktp')}}
    {% if is_incremental() %}
  WHERE date BETWEEN 
        COALESCE(
          DATE('{{ var("backfill_start_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
        AND
        COALESCE(
          DATE('{{ var("backfill_end_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
{% else %}
  WHERE date BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                  AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}
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
     {% if is_incremental() %}
  WHERE date BETWEEN 
        COALESCE(
          DATE('{{ var("backfill_start_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
        AND
        COALESCE(
          DATE('{{ var("backfill_end_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
{% else %}
  WHERE date BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                  AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}
    AND SOURCE != "facebook" ),
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