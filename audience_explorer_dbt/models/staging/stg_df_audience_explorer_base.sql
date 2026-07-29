-- depends_on: {{ ref('stg_user_traits_column_names') }}

{% set column_names = get_query_result('stg_user_traits_column_names', 'column_names') %}

with latest_traits as (
  select
    canonical_segment_id,
    name,
    value
  from {{ ref('raw_user_traits') }}
  where canonical_segment_id in (
      select canonical_segment_id from {{ ref('stg_known_users_join') }}
  )
  qualify row_number() over (
    partition by canonical_segment_id, name
    order by received_at desc
  ) = 1
)

select *
from latest_traits
Pivot(max(value) for name in ({{ column_names }}))
