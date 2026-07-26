-- This test validates that every column listed in `stg_user_traits_column_names`
-- exists in the source table schema (`raw_identifies`) and therefore has a type.
--
-- Any returned row is a failure (`column_without_type`) and means the sheet column
-- is missing from `INFORMATION_SCHEMA.COLUMNS` for `raw_identifies`.
--QUERY to see the unknown typed columns:  select * from `dat-analytics-eng-ec869189.dev_audience_explorer_dbt_test__audit.assert_all_sheet_columns_have_a_type`
--
-- With `store_failures = true`, failed rows are persisted by dbt in the test audit schema
-- (typically `<target_schema>_dbt_test__audit`). You can find the exact failure table name
-- in dbt test output/logs (look for this test's relation) and query it in BigQuery.

{{ config (
    severity = 'warn',
    store_failures = true
)}}

with sheet_cols as (

    select distinct lower(column_names) as col
    from {{ ref('stg_user_traits_column_names') }}
),

typed_cols as (

    select lower(column_name) as col
    from `{{ ref('raw_identifies').database }}`.`{{ ref('raw_identifies').schema }}`.INFORMATION_SCHEMA.COLUMNS
    where table_name = '{{ ref('raw_identifies').identifier }}'
)

select sheet_cols.col as column_without_type
from sheet_cols
left join typed_cols 
on sheet_cols.col = typed_cols.col
where typed_cols.col is null