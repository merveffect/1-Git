-- depends_on: {{ ref('stg_user_traits_column_names') }}




select
  {{ get_query_result('stg_user_traits_column_names', 'column_names') }} as identifier

  