-- Researcher profiles (aceproducts core_researcher_profiles): researcher_id ->
-- 5-year author group, used to classify power authors. Column name in the source
-- is Total_AMT_5yr_Author_Group (aliased to snake_case here).

with source as (

    select * from {{ source('core_researcher_profiles', 'researcher_profiles_out') }}

)

select
    researcher_id,
    Total_AMT_5yr_Author_Group as total_amt_5yr_author_group
from source
