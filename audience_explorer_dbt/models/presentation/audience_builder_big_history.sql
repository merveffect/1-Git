{{
config(
    materialized=('incremental'),
    incremental_strategy='merge',
    unique_key='canonical_segment_id',
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
	  canonical_segment_id 	  
	  from {{ ref('audience_builder_big') }}
),

change_detection as (
  select
    canonical_segment_id
    from new_data
    
	{% if is_incremental() %}    
	  except distinct
	  select
	    canonical_segment_id
	    from {{ this }}
	{% endif %}    
)

select
  canonical_segment_id,
  current_timestamp() as ingestion_timestamp
  from change_detection
 