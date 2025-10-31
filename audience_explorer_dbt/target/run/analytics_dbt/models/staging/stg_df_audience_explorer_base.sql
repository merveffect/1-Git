
  
    

    create or replace table `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_staging`.`stg_df_audience_explorer_base`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      -- depends_on: `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_staging`.`stg_user_traits_column_names`



select * from
  (select
    canonical_segment_id,
    name,
    value
       
    from `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_raw`.`raw_user_traits`
  )
  Pivot(max(value) for name in ('researcher_id','sn_positive_regular_author','list_journals_submissions_alltime','has_recent_online_behaviour','list_journals_submguide_about_last_60_d','list_journals_read_last_30_d','count_article_readership_last_60_d','sn_fan_power_author','first_name','avg_if','list_journals_etocs_last_180_d','has_received_email','count_reach_fta_last_180_d','country','not_sn_regular_author','count_doi_last_180_d','count_submguidelines_last_30_d','count_reach_fta_last_60_d','japa_all','list_journals_submguide_about_last_30_d','permutive_id','institution_name','occasional_author_2_10_publications','list_journals_read_last_60_d','list_doi_last_90_d','count_oa_content_online_last_60_d','last_name','not_sn_occasional_author','h_index','email_received_all','anonymous_id','author_group_global','ga_client_id','total_amt_5yr_author_group','chatpgt_users','regular_author_11_20_publications','sn_opportunity_power_author','etoc_received_all','author_group_global_detailed','list_doi_last_60_d','welcome_onboarding_retargeting_internal_display','count_submguidelines_last_90_days','sap_outbound_id','email_address','braze_received_all','count_about_last_90_days','advertising_opt_in','marketing_optin_mpc','orcid','sn_opportunity_regular_author','is_legitimate_interest_author_opted_in','marketing_opt_in_not_mpc','count_els_last_60_d','sn_fan_one_time_author','cep_id','is_webshop_buyer_communications_opted_in','list_journal_etocs_last_180_d','journal_awareness_1','explicit_user_choice','newsletters','count_reach_fta_last_90_d','sn_journal_submitters','top_publisher','is_global_subscribed','sn_journal_submitter','years_active','count_research_integrity_last_180_d','third_party_prom','sn_journal_authors','mkt_pref_opt_in','list_doi_last_180_d','loyalty_group','list_keywords_dois_last_60_d','persona','is_editorial_board_members_communications_opted_in','count_about_last_30_d','role','one_time_author_1_publication','snid','main_f2','most_recent_pub','not_sn_power_author','list_journals_submission_opened_last_90_d','not_sn_one_time_author','percent_oa','subjects','power_author_21_publications','count_researcherhome_last_180_d','sn_positive_occasional_author','online_marketing_engagement','sn_fan_regular_author','sn_opportunity_occasional_author','the_source_pages_visitors','change_over_py_sn_loyalty','list_journals_allpageviews_30_d','is_editor_referral_opted_in','sn_fan_occasional_author','sn_positive_power_author','email','oa_articles','user_researcher_home','is_book_author_communications_opted_in' ))
    );
  