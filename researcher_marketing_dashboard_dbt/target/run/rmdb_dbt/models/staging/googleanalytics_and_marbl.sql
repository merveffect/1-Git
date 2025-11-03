-- back compat for old kwarg name
  
  
        
    

    

    merge into `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`googleanalytics_and_marbl` as DBT_INTERNAL_DEST
        using (

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
    
   
  
  
  WHERE date BETWEEN 
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    
    AND
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    

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
    
  
  
  WHERE CAST(SubmitDate AS date) BETWEEN 
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    
    AND
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    

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
        ) as DBT_INTERNAL_SOURCE
        on (FALSE)

    

    when not matched then insert
        (`Hostname___GA4__Google_Analytics`, `Data_Source_name`, `Data_Source_type`, `Data_Source_id`, `Samples_read_rate___GA4__Google_Analytics`, `Sessions___GA4_event_based__Google_Analytics`, `ga4_click_submit_manuscript`, `ga4_reach_fta`, `ga4_reach_submission_guidelines`, `ga4_reach_about_page`, `ga4_reach_books_contact_editor_page`, `ga4_reach_books_publishing_guidelines`, `ga4_submit_your_book_idea_click`, `Engaged_sessions___GA4__Google_Analytics`, `ga4_engagement_leading_to_submission`, `ga4_reach_b2c_blog_page`, `ga4_snapp_submission_complete`, `ga4_content_consumption`, `ga4_reach_india_apc_thankyou`, `ga4_reach_oa_general`, `ga4_ta_file_download`, `ga4_snapp_submission_start`, `ga4_click_submit_manuscript_all_old_events`, `ga4_submit_your_book_idea_click_old_events`, `ga4_ta_file_download_all_old_events`, `ga4_reach_books_contact_editor_old_events`, `ga4_reach_full_text_article_old_events`, `ga4_reach_journal_about_old_events`, `ga4_reach_journal_submission_guidelines_old_events`, `ga4_reach_b2c_blog_page_old_events`, `ga4_journal_engagement`, `ga4_research_article_readership`, `ga4_ejp_submission_complete`, `ga4_ejp_submission_start`, `ga4_source_readership`, `ga4_nav_sign_up_for_alerts`, `journal_title`, `business_model`, `main_group`, `portfolio`, `main_discipline`, `journal_id`, `date`, `campaign`, `country`, `RN`, `SOURCE`, `medium`, `ad_content`, `google_ad_network`, `kpi_marbl_leads`)
    values
        (`Hostname___GA4__Google_Analytics`, `Data_Source_name`, `Data_Source_type`, `Data_Source_id`, `Samples_read_rate___GA4__Google_Analytics`, `Sessions___GA4_event_based__Google_Analytics`, `ga4_click_submit_manuscript`, `ga4_reach_fta`, `ga4_reach_submission_guidelines`, `ga4_reach_about_page`, `ga4_reach_books_contact_editor_page`, `ga4_reach_books_publishing_guidelines`, `ga4_submit_your_book_idea_click`, `Engaged_sessions___GA4__Google_Analytics`, `ga4_engagement_leading_to_submission`, `ga4_reach_b2c_blog_page`, `ga4_snapp_submission_complete`, `ga4_content_consumption`, `ga4_reach_india_apc_thankyou`, `ga4_reach_oa_general`, `ga4_ta_file_download`, `ga4_snapp_submission_start`, `ga4_click_submit_manuscript_all_old_events`, `ga4_submit_your_book_idea_click_old_events`, `ga4_ta_file_download_all_old_events`, `ga4_reach_books_contact_editor_old_events`, `ga4_reach_full_text_article_old_events`, `ga4_reach_journal_about_old_events`, `ga4_reach_journal_submission_guidelines_old_events`, `ga4_reach_b2c_blog_page_old_events`, `ga4_journal_engagement`, `ga4_research_article_readership`, `ga4_ejp_submission_complete`, `ga4_ejp_submission_start`, `ga4_source_readership`, `ga4_nav_sign_up_for_alerts`, `journal_title`, `business_model`, `main_group`, `portfolio`, `main_discipline`, `journal_id`, `date`, `campaign`, `country`, `RN`, `SOURCE`, `medium`, `ad_content`, `google_ad_network`, `kpi_marbl_leads`)


    