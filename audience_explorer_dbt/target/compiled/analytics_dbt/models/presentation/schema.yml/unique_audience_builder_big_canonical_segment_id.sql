
    
    

with dbt_test__target as (

  select canonical_segment_id as unique_field
  from `dat-analytics-eng-ec869189`.`dev_audience_explorer_analytics_dbt_presentation`.`audience_builder_big`
  where canonical_segment_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


