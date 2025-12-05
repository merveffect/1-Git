
{{ config(
    materialized = "table",
    tags= ["daily", "marketing_optins"]
 )}}

SELECT
  date,
  b2cCntctOptin_actual
FROM
  {{source('ga4_ria_researcher_report','optins_sheet')}}
