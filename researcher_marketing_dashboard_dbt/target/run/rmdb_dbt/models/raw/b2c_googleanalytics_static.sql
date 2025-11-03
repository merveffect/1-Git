-- back compat for old kwarg name
  
  
        
    

    

    merge into `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`b2c_googleanalytics_static` as DBT_INTERNAL_DEST
        using (

select
    *
from `snproject-cbb9ca25`.`ga4_ria_researcher_report`.`googleanalytics`


  
  
  WHERE date BETWEEN 
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    
    AND
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    

        ) as DBT_INTERNAL_SOURCE
        on (FALSE)

    

    when not matched then insert
        (`Date`, `Hostname___GA4__Google_Analytics`, `Country___GA4__Google_Analytics`, `Session_campaign___GA4__Google_Analytics`, `Session_source__medium___GA4__Google_Analytics`, `Session_manual_ad_content___GA4__Google_Analytics`, `Session_Google_Ads_ad_network_type___GA4__Google_Analytics`, `Data_Source_name`, `Data_Source_type`, `Data_Source_id`, `Samples_read_rate___GA4__Google_Analytics`, `Sessions___GA4_event_based__Google_Analytics`, `ga4_click_submit_manuscript`, `ga4_reach_fta`, `ga4_reach_submission_guidelines`, `ga4_reach_about_page`, `ga4_reach_books_contact_editor_page`, `ga4_reach_books_publishing_guidelines`, `ga4_submit_your_book_idea_click`, `Engaged_sessions___GA4__Google_Analytics`, `Journal_ID___GA4__Google_Analytics`, `ga4_engagement_leading_to_submission`, `ga4_reach_b2c_blog_page`, `ga4_snapp_submission_complete`, `ga4_content_consumption`, `ga4_reach_india_apc_thankyou`, `ga4_reach_oa_general`, `ga4_ta_file_download`, `ga4_snapp_submission_start`, `ga4_click_submit_manuscript_all_old_events`, `ga4_submit_your_book_idea_click_old_events`, `ga4_ta_file_download_all_old_events`, `ga4_reach_books_contact_editor_old_events`, `ga4_reach_full_text_article_old_events`, `ga4_reach_journal_about_old_events`, `ga4_reach_journal_submission_guidelines_old_events`, `ga4_reach_b2c_blog_page_old_events`, `ga4_journal_engagement`, `ga4_research_article_readership`, `ga4_ejp_submission_complete`, `ga4_ejp_submission_start`, `ga4_source_readership`, `ga4_nav_sign_up_for_alerts`)
    values
        (`Date`, `Hostname___GA4__Google_Analytics`, `Country___GA4__Google_Analytics`, `Session_campaign___GA4__Google_Analytics`, `Session_source__medium___GA4__Google_Analytics`, `Session_manual_ad_content___GA4__Google_Analytics`, `Session_Google_Ads_ad_network_type___GA4__Google_Analytics`, `Data_Source_name`, `Data_Source_type`, `Data_Source_id`, `Samples_read_rate___GA4__Google_Analytics`, `Sessions___GA4_event_based__Google_Analytics`, `ga4_click_submit_manuscript`, `ga4_reach_fta`, `ga4_reach_submission_guidelines`, `ga4_reach_about_page`, `ga4_reach_books_contact_editor_page`, `ga4_reach_books_publishing_guidelines`, `ga4_submit_your_book_idea_click`, `Engaged_sessions___GA4__Google_Analytics`, `Journal_ID___GA4__Google_Analytics`, `ga4_engagement_leading_to_submission`, `ga4_reach_b2c_blog_page`, `ga4_snapp_submission_complete`, `ga4_content_consumption`, `ga4_reach_india_apc_thankyou`, `ga4_reach_oa_general`, `ga4_ta_file_download`, `ga4_snapp_submission_start`, `ga4_click_submit_manuscript_all_old_events`, `ga4_submit_your_book_idea_click_old_events`, `ga4_ta_file_download_all_old_events`, `ga4_reach_books_contact_editor_old_events`, `ga4_reach_full_text_article_old_events`, `ga4_reach_journal_about_old_events`, `ga4_reach_journal_submission_guidelines_old_events`, `ga4_reach_b2c_blog_page_old_events`, `ga4_journal_engagement`, `ga4_research_article_readership`, `ga4_ejp_submission_complete`, `ga4_ejp_submission_start`, `ga4_source_readership`, `ga4_nav_sign_up_for_alerts`)


    