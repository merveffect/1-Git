{{
  config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      'field': 'transaction_date',
      'data_type': 'date'
    }
  )
}}

SELECT
  date AS transaction_date,
  session_campaign,
  TRIM(SPLIT(session_source__medium, '/')[safe_offset(0)]) AS m_source,
  TRIM(SPLIT(session_source__medium, '/')[safe_offset(1)]) AS m_medium,
  session_manual_ad_content AS ad_content,
  session_google_ads_ad_network_type AS ad_network,
  country,
  currency,
  transaction_id,
  item_id,
  item_revenue,
  items_purchased,
  hostname
FROM {{ source('funnel_exports', 'transactions_ga') }}
WHERE hostname = 'single-ebooks.springernature.com'
  AND starts_with(transaction_id, 'SN')
  AND date > '2024-04-01'

{% if is_incremental() %}
  AND date >= DATE_SUB(
        (SELECT MAX(transaction_date) FROM {{ this }}),
        INTERVAL 3 DAY
      )
{% endif %}