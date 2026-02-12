{{ config(
    materialized = "incremental",
    incremental_strategy="insert_overwrite",
    partition_by = {"field": "date", "data_type": "date"},
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"],
    cluster_by = ["campaign", "sub_channels", "medium", "Data_Source_type"]
 )}}


WITH
  main AS (
  SELECT
    * EXCEPT (cost,
      clicks,
      impressions,
      SOURCE,
      medium,
      Network_with_search_partners__AdWords,
      month,
      year,
      currency,
      Data_Source_name,
      Data_Source_id,
      account_ID,
      CampaignID,
      Data_Origin_Identifier,
      conversion_value_google_ads),
    LOWER(SOURCE) AS SOURCE,
    LOWER(medium) AS medium,
    LOWER(Network_with_search_partners__AdWords) AS google_ad_network,
    "" AS ad_content,
    SUM(cost) AS cost,
    SUM(clicks) AS clicks,
    SUM(impressions) AS impressions
  FROM
    {{source('RM_adspend','rm_adspend_static')}}
   
    {{ incremental_date_filter('date') }}



  GROUP BY ALL ),
  transformations AS (
  SELECT
    *,
    CASE
      WHEN (data_source_type = "adwords" OR data_source_type='Google Ads') AND REGEXP_CONTAINS(google_ad_network,"content|google display network|youtube") THEN "google - external display"
      WHEN data_source_type = "criteo" THEN "criteo - external display"
      WHEN data_source_type = "yahoo_japan_ydn" THEN "yahoo - external display"
      WHEN data_source_type = "yahoo_japan_search" THEN "yahoo - sea"
      WHEN (data_source_type = "adwords" OR data_source_type='Google Ads') AND NOT REGEXP_CONTAINS(google_ad_network,"content|google display network") THEN "google - sea"
      WHEN (data_source_type = "adwords"
      OR data_source_type='Google Ads')
    AND google_ad_network IS NULL THEN "google - sea"
      WHEN (data_source_type = "bing" OR data_source_type = "Microsoft Advertising") THEN "bing - sea"
      WHEN data_source_type = "facebookads" THEN "facebook - paid social"
      WHEN (data_source_type = "twitter" OR data_source_type="X Ads") THEN "twitter - paid social"
      WHEN data_source_type = "linkedin_api" THEN "linkedin - paid social"
      ELSE NULL
  END
    AS sub_channels
  FROM
    main )
    -- final table
SELECT
  *,
  CASE
    WHEN REGEXP_CONTAINS(sub_channels, '- sea') THEN "sea"
    WHEN REGEXP_CONTAINS(sub_channels, 'paid social') THEN "paid social"
    WHEN REGEXP_CONTAINS(sub_channels, 'email|etocs') THEN "email"
    WHEN REGEXP_CONTAINS(sub_channels, 'external display') THEN "external display"
    WHEN REGEXP_CONTAINS(sub_channels, 'internal display') THEN "internal display"
    ELSE "6. other channels"
END
  AS main_channels
FROM
  transformations
