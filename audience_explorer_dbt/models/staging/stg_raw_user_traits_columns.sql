-- it is used in connected sheets Audience Explorer Big Columns (not part of the pipeline)
select 
distinct name 
from {{ref('raw_user_traits')}}