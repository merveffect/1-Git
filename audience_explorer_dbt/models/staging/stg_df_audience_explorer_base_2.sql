  -- depends_on: {{ ref('raw_user_traits') }}

{% set exclude_columns = [
  'canonical_segment_id', 'anonymous_id', 'sap_outbound_id', 'last_name', 'snid', 
  'researcher_id', 'orcid', 'ga_client_id', 'email', 'first_name', 'permutive_id'
] %}

{% set included_columns = get_columns_except_excluded('stg_user_traits_column_names', 'column_names', exclude_columns) %}

{% do log("Included columns: " ~ included_columns, info=True) %}


WITH base AS (
  SELECT * FROM {{ ref('stg_df_nested_columns_joined') }}

)


SELECT *, 
       CASE 
        WHEN {{ get_null_flag_expression(included_columns) }} THEN 0 
        ELSE 1 
        END AS flag_column 
FROM base




