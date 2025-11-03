

with new_data as (
	select distinct 
	  column_names	  
	  from `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_user_traits_column_names`
),

change_detection as (
  select
    column_names
    from new_data
    
	    
	  except distinct
	  select
	    column_names
	    from `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_staging`.`stg_user_traits_column_names_history`
	    
)

select
  column_names,
  current_timestamp() as ingestion_timestamp
  from change_detection