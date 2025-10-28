
{{ config(
    materialized = "incremental"
 )}}

SELECT
  date,
  b2cCntctOptin_actual
FROM
  {{source('dbt_dev_ga4_ria_researcher_report','optins_sheet')}}
