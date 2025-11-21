
  
    

    create or replace table `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_staging`.`stg_df_audience_explorer_base_2`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      -- depends_on: `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_raw`.`raw_user_traits`








WITH base AS (
  SELECT * FROM `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_staging`.`stg_df_nested_columns_joined`

)


SELECT *, 
       CASE 
        WHEN count_els_last_60_d IS NULL AND sn_fan_one_time_author IS NULL AND welcome_onboarding_retargeting_internal_display IS NULL AND is_editorial_board_members_communications_opted_in IS NULL AND count_reach_fta_last_90_d IS NULL AND loyalty_group IS NULL AND sn_opportunity_occasional_author IS NULL AND list_journals_allpageviews_30_d IS NULL AND user_researcher_home IS NULL AND is_legitimate_interest_author_opted_in IS NULL AND subjects IS NULL AND power_author_21_publications IS NULL AND count_about_last_30_d IS NULL AND role IS NULL AND main_f2 IS NULL AND sn_journal_authors_legitimate_interest IS NULL AND email_address IS NULL AND braze_received_all IS NULL AND is_webshop_buyer_communications_opted_in IS NULL AND sn_opportunity_regular_author IS NULL AND is_global_subscribed IS NULL AND japa_all IS NULL AND occasional_author_2_10_publications IS NULL AND count_reach_fta_last_60_d IS NULL AND third_party_prom IS NULL AND sn_journal_authors IS NULL AND mkt_pref_opt_in IS NULL AND list_doi_last_180_d IS NULL AND not_sn_one_time_author IS NULL AND institution_name IS NULL AND list_journals_etocs_last_180_d IS NULL AND has_received_email IS NULL AND count_reach_fta_last_180_d IS NULL AND sn_journal_authors_monthly IS NULL AND list_journals_submguide_about_last_60_d IS NULL AND sn_fan_power_author IS NULL AND list_keywords_dois_last_60_d IS NULL AND count_oa_content_online_last_60_d IS NULL AND journal_nurture_eligible_canvas_1 IS NULL AND regular_author_11_20_publications IS NULL AND sn_opportunity_power_author IS NULL AND not_sn_occasional_author IS NULL AND list_journals_submission_opened_last_90_d IS NULL AND b_2_c_marketing_contacts_monthly IS NULL AND list_journals_read_last_60_d IS NULL AND marketing_optin_mpc IS NULL AND top_publisher IS NULL AND advertising_opt_in IS NULL AND chatpgt_users IS NULL AND country IS NULL AND not_sn_regular_author IS NULL AND sn_positive_power_author IS NULL AND total_amt_5yr_author_group IS NULL AND email_received_all IS NULL AND the_source_pages_visitors IS NULL AND count_researcherhome_last_180_d IS NULL AND sn_positive_occasional_author IS NULL AND count_doi_last_180_d IS NULL AND count_about_last_90_days IS NULL AND sn_journal_submitters IS NULL AND key_contributor IS NULL AND one_time_author_1_publication IS NULL AND years_active IS NULL AND count_research_integrity_last_180_d IS NULL AND list_journal_etocs_last_180_d IS NULL AND sn_positive_regular_author IS NULL AND list_journals_submissions_alltime IS NULL AND has_recent_online_behaviour IS NULL AND count_submguidelines_last_90_days IS NULL AND list_journals_submguide_about_last_30_d IS NULL AND sn_fan_regular_author IS NULL AND list_doi_last_60_d IS NULL AND journal_nurture_oa_interest_eligible_canvas_2 IS NULL AND sn_journal_submitter IS NULL AND count_submguidelines_last_30_d IS NULL AND marketing_opt_in_not_mpc IS NULL AND etoc_received_all IS NULL AND author_group_global_detailed IS NULL AND oa_articles IS NULL AND avg_if IS NULL AND online_marketing_engagement IS NULL AND list_doi_last_90_d IS NULL AND sn_fan_occasional_author IS NULL AND last_time_online IS NULL AND change_over_py_sn_loyalty IS NULL AND is_editor_referral_opted_in IS NULL AND journal_awareness_1 IS NULL AND explicit_user_choice IS NULL AND newsletters IS NULL AND author_group_global IS NULL AND cep_id IS NULL AND h_index IS NULL AND persona IS NULL AND is_book_author_communications_opted_in IS NULL AND list_journals_read_last_30_d IS NULL AND count_article_readership_last_60_d IS NULL AND percent_oa IS NULL AND most_recent_pub IS NULL AND not_sn_power_author IS NULL AND sn_journal_legitimate_interest_monthly IS NULL AND b_2_c_marketing_contacts IS NULL THEN 0 
        ELSE 1 
        END AS flag_column 
FROM base
    );
  