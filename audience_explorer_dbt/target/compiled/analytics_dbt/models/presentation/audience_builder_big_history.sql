

with new_data as (
	select distinct 
	  canonical_segment_id 	  
	  from `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_presentation`.`audience_builder_big`
),

change_detection as (
  select
    canonical_segment_id
    from new_data
    
	    
	  except distinct
	  select
	    canonical_segment_id
	    from `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_presentation`.`audience_builder_big_history`
	    
)

select
  canonical_segment_id,
  current_timestamp() as ingestion_timestamp
  from change_detection