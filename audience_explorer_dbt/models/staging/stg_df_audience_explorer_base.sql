-- depends_on: {{ ref('stg_user_traits_column_names') }}

{% set column_names = get_query_result('stg_user_traits_column_names', 'column_names') %}

select * from
  (select
    canonical_segment_id,
    name,
    value
       
    from {{ ref('raw_user_traits') }}
    WHERE canonical_segment_id IN (
	    select segment_id from {{ ref('raw_segment_known_users_with_email') }}
	    where segment_id IS NOT NULL
)
  )
  Pivot(max(value) for name in ({{ column_names }} ))
  
