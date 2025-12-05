
  
    

    create or replace table `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_presentation`.`audience_builder_optin`
      
    
    

    
    OPTIONS(
      description="""This model includes features related to audience opt-in status."""
    )
    as (
      

select
  *
  from `dat-analytics-eng-ec869189`.`prod_audience_explorer_analytics_dbt_presentation`.`audience_builder_big`
  where advertising_opt_in
    );
  