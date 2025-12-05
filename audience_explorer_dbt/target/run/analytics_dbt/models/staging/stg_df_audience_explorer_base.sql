
  
    

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
  Pivot(max(value) for name in ('author_group_global','cep_id','orcid','persona','is_book_author_communications_opted_in','researcher_id','online_marketing_engagement','subjects','power_author_21_publications','list_journals_submguide_about_last_60_d','sn_fan_power_author','list_keywords_dois_last_60_d','most_recent_pub','not_sn_power_author','list_journal_etocs_last_180_d','list_journals_read_last_30_d','count_article_readership_last_60_d','sap_outbound_id','percent_oa','list_journals_submguide_about_last_30_d','sn_fan_regular_author','list_doi_last_60_d','journal_nurture_oa_interest_eligible_canvas_2','sn_journal_submitter','count_submguidelines_last_30_d','first_name','marketing_opt_in_not_mpc','email_received_all','the_source_pages_visitors','count_reach_fta_last_60_d','h_index','top_publisher','list_journals_read_last_60_d','marketing_optin_mpc','b_2_c_marketing_contacts_monthly','regular_author_11_20_publications','sn_opportunity_power_author','years_active','count_research_integrity_last_180_d','count_reach_fta_last_90_d','loyalty_group','sn_opportunity_occasional_author','list_journals_allpageviews_30_d','list_doi_last_90_d','count_els_last_60_d','sn_fan_one_time_author','welcome_onboarding_retargeting_internal_display','is_editorial_board_members_communications_opted_in','email','main_f2','sn_journal_authors_legitimate_interest','not_sn_occasional_author','list_journals_submission_opened_last_90_d','sn_fan_occasional_author','last_time_online','snid','change_over_py_sn_loyalty','avg_if','sn_opportunity_regular_author','is_global_subscribed','japa_all','etoc_received_all','author_group_global_detailed','oa_articles','count_about_last_30_d','role','occasional_author_2_10_publications','email_address','braze_received_all','anonymous_id','permutive_id','is_webshop_buyer_communications_opted_in','advertising_opt_in','chatpgt_users','one_time_author_1_publication','ga_client_id','user_researcher_home','is_legitimate_interest_author_opted_in','key_contributor','count_researcherhome_last_180_d','sn_positive_occasional_author','count_doi_last_180_d','count_about_last_90_days','sn_journal_submitters','sn_positive_regular_author','list_journals_submissions_alltime','has_recent_online_behaviour','count_submguidelines_last_90_days','is_editor_referral_opted_in','sn_journal_legitimate_interest_monthly','country','not_sn_regular_author','sn_positive_power_author','total_amt_5yr_author_group','count_oa_content_online_last_60_d','last_name','journal_nurture_eligible_canvas_1','journal_awareness_1','explicit_user_choice','newsletters','third_party_prom','sn_journal_authors','mkt_pref_opt_in','list_doi_last_180_d','not_sn_one_time_author','institution_name','b_2_c_marketing_contacts','list_journals_etocs_last_180_d','has_received_email','count_reach_fta_last_180_d','sn_journal_authors_monthly' ))
    );
  