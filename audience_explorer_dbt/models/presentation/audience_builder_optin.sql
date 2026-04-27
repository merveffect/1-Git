{{ config(materialization='view') }}

select
  *
  from {{ ref('audience_builder_big') }}
  where advertising_opt_in
  
  