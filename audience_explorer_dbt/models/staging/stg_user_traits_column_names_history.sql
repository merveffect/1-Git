{{
config(
    materialized=('incremental'),
    incremental_strategy='merge',
    on_schema_change='append_new_columns',
    partition_by={
        'field': 'ingestion_timestamp', 
        'data_type': 'timestamp', 
        'granularity': 'day'
    }
)
}}

with new_data as (
	select distinct 
	  column_names	  
	  from {{ ref('stg_user_traits_column_names') }}
),

change_detection as (
  select
    column_names
    from new_data
    
	{% if is_incremental() %}    
	  except distinct
	  select
	    column_names
	    from {{ this }}
	{% endif %}    
)

select
  column_names,
  current_timestamp() as ingestion_timestamp
  from change_detection
 