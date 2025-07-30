-- depends_on: {{ ref('stg_user_traits_column_names') }}

{% set column_names = get_query_result('stg_user_traits_column_names', 'column_names') %}

select * from
  (select
    canonical_segment_id,
    name,
    case
      when name = 'list_keywords_dois_last_60_d'
        then REPLACE(REPLACE(REPLACE(REPLACE( value,'[',''), ']',''),r'\"',''),r'"','')
      else value
    end as value
       
    from {{ ref('raw_user_traits') }}
  )
  Pivot(max(value) for name in ({{ column_names }} ))
  