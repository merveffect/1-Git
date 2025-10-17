
  
    

    create or replace table `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_df_audience_explorer_id_flags`
      
    
    

    OPTIONS(
      description="""Flags for checking not null presence in key identifier fields from the audience explorer base table.\n"""
    )
    as (
      select
canonical_segment_id,
 (email IS NOT NULL) AS email_flag,
  (anonymous_id IS NOT NULL) AS anonymous_id_flag,
  (sap_outbound_id IS NOT NULL) AS sap_outbound_id_flag,
  (last_name IS NOT NULL) AS last_name_flag,
  (snid IS NOT NULL) AS snid_flag,
  (researcher_id IS NOT NULL) AS researcher_id_flag,
  (orcid IS NOT NULL) AS orcid_flag,
  (ga_client_id IS NOT NULL) AS ga_client_id_flag,
  (first_name IS NOT NULL) AS first_name_flag,
  (permutive_id IS NOT NULL) AS permutive_id_flag,
  (cep_id IS NOT NULL) AS cep_id_flag,
  
  from `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_df_audience_explorer_base_2`
    );
  