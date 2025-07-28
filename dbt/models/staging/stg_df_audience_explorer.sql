-- depends_on: {{ ref('stg_user_traits_column_names') }}

{% set column_names = get_query_result('stg_user_traits_column_names', 'column_names') %}

select * from
  (select
    canonical_segment_id,
    name,
    value
    from {{ ref('raw_user_traits') }}
    where canonical_segment_id = 'use_PIoyyMbVhpz7kBGq2JH2zvWGnhB'
  )
  Pivot(max(value) for name in ('{{ column_names }}'))
  