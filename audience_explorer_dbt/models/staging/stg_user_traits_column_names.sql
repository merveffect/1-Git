select 

  distinct name as column_names

  from {{ ref('raw_user_traits') }}


