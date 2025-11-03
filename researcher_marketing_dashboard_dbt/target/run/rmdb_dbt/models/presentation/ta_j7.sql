-- back compat for old kwarg name
  
  
        
    

    

    merge into `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`ta_j7` as DBT_INTERNAL_DEST
        using ( 

SELECT
  a.*,
  b.* EXCEPT(journal_id,
    journal_title),
  CASE
    WHEN researchER_marketing_activity = TRUE AND product_code != "oaagr" THEN "researcher marketing"
    WHEN product_code = "oaagr" THEN "OAAGR campaign traffic"
    ELSE "all other traffic"
END
  AS traffic_type_ta
FROM
  `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`j7` a
LEFT JOIN
  `snproject-cbb9ca25`.`ga4_ria_researcher_report`.`transformative_agreements_sheet` b
ON
  a.journal_id = b.journal_id
  
  
  
  WHERE date BETWEEN 
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    
    AND
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    

        ) as DBT_INTERNAL_SOURCE
        on (FALSE)

    

    when not matched then insert
        (`date`, `campaign`, `clean_campaign`, `SOURCE`, `medium`, `main_channels`, `sub_channels`, `country`, `isoalphatwo`, `world_region`, `audience_code`, `product_code`, `goal_code`, `campaign_code`, `geo_code`, `team_code`, `products`, `journal_title`, `oatype`, `journal_id`, `business_model`, `main_discipline`, `main_group`, `portfolio`, `imprint`, `journal_imprint`, `engagement_rate`, `kpi_marbl_leads`, `Sessions`, `pi_publishing_guidelines`, `EngagedSessions`, `ELS`, `snapp_submission_complete`, `content_consumption`, `reach_india_apc_thankyou`, `reach_oa_general`, `snapp_submission_start`, `kpi_submit_click`, `pi_reach_fta`, `kpi_reach_submission_guideline_pages`, `kpi_reach_about_pages`, `pi_contact_an_editor`, `kpi_submit_your_book_idea`, `reach_b2c_blog_page`, `ta_file_download`, `search_volume`, `journal_engagement`, `research_article_readership`, `source_readership`, `ejp_submission_start`, `ejp_submission_complete`, `nav_sign_up_for_alerts`, `cost`, `clicks`, `impressions`, `researchER_marketing_activity`, `research_marketing_activity`, `naming_convention_correct`, `nature_grp`, `is_oax`, `id`, `status`, `campaign_category`, `name`, `responsible_person`, `target_audience_name`, `validity_from`, `validity_to`, `archived`, `workspace_category`, `workspace_name`, `primary_campaign_goal`, `marmind_campaign_code`, `description`, `sweden`, `anz_caul`, `anz_nature`, `colombia`, `spain`, `italy`, `switzerland`, `slovenia`, `slovakia`, `germany`, `denmark`, `egypt`, `portugal`, `finland`, `hungary`, `greece`, `poland`, `ireland`, `uk`, `austria`, `czech_republic`, `qatar`, `sanlic`, `norway`, `netherlands`, `israel`, `turkey`, `malta`, `traffic_type_ta`)
    values
        (`date`, `campaign`, `clean_campaign`, `SOURCE`, `medium`, `main_channels`, `sub_channels`, `country`, `isoalphatwo`, `world_region`, `audience_code`, `product_code`, `goal_code`, `campaign_code`, `geo_code`, `team_code`, `products`, `journal_title`, `oatype`, `journal_id`, `business_model`, `main_discipline`, `main_group`, `portfolio`, `imprint`, `journal_imprint`, `engagement_rate`, `kpi_marbl_leads`, `Sessions`, `pi_publishing_guidelines`, `EngagedSessions`, `ELS`, `snapp_submission_complete`, `content_consumption`, `reach_india_apc_thankyou`, `reach_oa_general`, `snapp_submission_start`, `kpi_submit_click`, `pi_reach_fta`, `kpi_reach_submission_guideline_pages`, `kpi_reach_about_pages`, `pi_contact_an_editor`, `kpi_submit_your_book_idea`, `reach_b2c_blog_page`, `ta_file_download`, `search_volume`, `journal_engagement`, `research_article_readership`, `source_readership`, `ejp_submission_start`, `ejp_submission_complete`, `nav_sign_up_for_alerts`, `cost`, `clicks`, `impressions`, `researchER_marketing_activity`, `research_marketing_activity`, `naming_convention_correct`, `nature_grp`, `is_oax`, `id`, `status`, `campaign_category`, `name`, `responsible_person`, `target_audience_name`, `validity_from`, `validity_to`, `archived`, `workspace_category`, `workspace_name`, `primary_campaign_goal`, `marmind_campaign_code`, `description`, `sweden`, `anz_caul`, `anz_nature`, `colombia`, `spain`, `italy`, `switzerland`, `slovenia`, `slovakia`, `germany`, `denmark`, `egypt`, `portugal`, `finland`, `hungary`, `greece`, `poland`, `ireland`, `uk`, `austria`, `czech_republic`, `qatar`, `sanlic`, `norway`, `netherlands`, `israel`, `turkey`, `malta`, `traffic_type_ta`)


    