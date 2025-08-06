  -- depends_on: {{ ref('raw_user_traits') }}

{% set exclude_columns = [
  'canonical_segment_id', 'anonymous_id', 'sap_outbound_id', 'last_name', 'snid', 
  'researcher_id', 'orcid', 'ga_client_id', 'email', 'first_name', 'permutive_id'
] %}

{% set included_columns = get_columns_except_excluded('raw_user_traits', 'name', exclude_columns) %}

{% do log("Included columns: " ~ included_columns, info=True) %}


--{% set null_check_expr = get_null_flag_expression(included_columns) %}

--{{ log("🧪 Generated NULL check expression:", info=True) }}
--{{ log(null_check_expr, info=True) }}


WITH base AS (
  SELECT * FROM {{ ref('stg_df_audience_explorer_base') }}

)


SELECT *, 
       CASE 
        WHEN {{ get_null_flag_expression(included_columns) }} THEN 0 
        ELSE 1 
        END AS flag_column 
FROM base




