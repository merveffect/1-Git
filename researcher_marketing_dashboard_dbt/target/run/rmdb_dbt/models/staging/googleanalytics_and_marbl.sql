
  
    

    create or replace table `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`googleanalytics_and_marbl`
      
    partition by date
    cluster by campaign, journal_id, source, medium

    
    OPTIONS(
      description=""""""
    )
    as (
      

WITH
  main_data AS (
  SELECT
    * EXCEPT(Session_source__medium___GA4__Google_Analytics,
      Session_campaign___GA4__Google_Analytics),
    LOWER(Session_campaign___GA4__Google_Analytics) AS campaign,
    TRIM(SPLIT(Session_source__medium___GA4__Google_Analytics, '/')[SAFE_OFFSET(0)]) AS SOURCE,
    TRIM(SPLIT(Session_source__medium___GA4__Google_Analytics, '/')[SAFE_OFFSET(1)]) AS medium
  FROM
    `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`journal_mapping`
    
   
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-10-28')

  ),
  
  marbl_data AS (
  SELECT
    DISTINCT SOURCE AS marbl_source,
    CASE
      WHEN LOWER(Campaign) IS NULL THEN 'no_campaign'
      ELSE LOWER(Campaign)
    END AS marbl_campaign,
    medium AS marbl_medium,
    "" AS marbl_adcontent,
    LOWER(country) AS marbl_country,
    CAST(SubmitDate AS date) AS submit_date,
    COUNT(UniqueSubmissionID) AS kpi_marbl_leads
  FROM
    `snproject-cbb9ca25`.`ga4_ria_researcher_report`.`BooksMarketing`
    
  WHERE CAST(SubmitDate AS date) BETWEEN DATE('2024-01-01')
                  AND DATE('2025-10-28')

  GROUP BY
    campaign,
    SOURCE,
    medium,
    submit_date,
    country ),
  
  combined_data AS (
  SELECT
    *
  FROM
    main_data AS main
  FULL JOIN
    marbl_data AS marbl
  ON
    LOWER(main.campaign) = LOWER(marbl_campaign)
    AND main.source = marbl_source
    AND main.medium = marbl_medium
    AND main.Date = marbl.submit_date
    AND main.Country___GA4__Google_Analytics = marbl.marbl_country
  ),
  
  unified_data AS (
  SELECT
    * EXCEPT(date,
      marbl_campaign,
      marbl_source,
      marbl_medium,
      marbl_country,
      campaign,
      SOURCE,
      medium,
      Country___GA4__Google_Analytics,
      submit_date,
      Session_manual_ad_content___GA4__Google_Analytics,
      marbl_adcontent),
    COALESCE(Date, submit_date) AS date,
    COALESCE(campaign, marbl_campaign) AS campaign,
    COALESCE(SOURCE, marbl_source) AS SOURCE,
    COALESCE(medium, marbl_medium) AS medium,
    COALESCE(Session_manual_ad_content___GA4__Google_Analytics, marbl_adcontent) AS Ad_content___GA4__Google_Analytics,
    COALESCE(Country___GA4__Google_Analytics, marbl_country) AS country
  FROM
    combined_data ),
  
  row_number AS (
  SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY date, campaign, SOURCE, medium, Ad_content___GA4__Google_Analytics, country ORDER BY date DESC) AS RN
  FROM
    unified_data )
  
SELECT
  * EXCEPT(kpi_marbl_leads,
    SOURCE,
    medium,
    Ad_content___GA4__Google_Analytics,
    Session_Google_Ads_ad_network_type___GA4__Google_Analytics),
  LOWER(SOURCE) AS SOURCE,
  LOWER(medium) AS medium,
  LOWER(Ad_content___GA4__Google_Analytics) AS ad_content,
  LOWER(Session_Google_Ads_ad_network_type___GA4__Google_Analytics) AS google_ad_network,
  CASE
    WHEN rn = 1 AND journal_id IS NOT NULL THEN kpi_marbl_leads
    WHEN journal_id IS NULL THEN kpi_marbl_leads
    ELSE 0
  END AS kpi_marbl_leads
FROM
  row_number
    );
  