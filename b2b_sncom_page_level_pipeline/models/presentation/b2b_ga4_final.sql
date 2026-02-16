{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            "field": "event_date",
            "data_type": "date",
            "granularity": "day"
        },
        tags=['presentation', 'incremental']
    )
}}

SELECT
  ga4.* EXCEPT(event_name),
  event_name as event_type,
  CASE
        WHEN
            event_name = 'page_view'
            THEN CONCAT('SN.com | ',first_level_grouping,' | ',second_level_grouping, ' : Page View')
        WHEN
            event_name = 'hs_form_submit'
            THEN CONCAT('SN.com | ',first_level_grouping,' | ',second_level_grouping, ' : Form Submit')
        WHEN
            event_name = 'file_download_b2b'
            THEN CONCAT('SN.com | ',first_level_grouping,' | ',second_level_grouping, ' : File Download')
        WHEN
            event_name = 'session_start'
            THEN CONCAT('SN.com | ',first_level_grouping,' | ',second_level_grouping, ' : Session Start')
        WHEN
            event_name = 'video_start'
            THEN CONCAT('SN.com | ',first_level_grouping,' | ',second_level_grouping, ' : Video Start')
        WHEN
            event_name = 'video_complete'
            THEN CONCAT('SN.com | ',first_level_grouping,' | ',second_level_grouping, ' : Video Complete')
        WHEN
            event_name = 'click_b2b_stories'
            THEN CONCAT('SN.com | ',first_level_grouping,' | ',second_level_grouping, ' : Click B2B Stories')
        ELSE event_name
    END AS event_name,
  p_code AS campaign_products,
  a_code AS campaign_audience,
  g_code AS campaign_goals,
  ge_code AS campaign_geo,
  CASE
    WHEN sub_channels LIKE "%sea%" THEN "sea"
    WHEN sub_channels LIKE "%paid social%" THEN "paid social"
    WHEN sub_channels = "email" OR sub_channels = "etocs" THEN "email"
    WHEN sub_channels LIKE "%external display%" THEN "external display"
    WHEN sub_channels LIKE "%internal display%" THEN "internal display"
    WHEN sub_channels LIKE "%affiliate%" THEN "affiliate"
    WHEN sub_channels IN ("ai seo", "traditional seo") THEN "seo" -- SEO is upgraded and included in the main channel list
    ELSE "other channels"
END
  AS main_channels,
  CASE
    WHEN session_campaign IN ('(direct)', '(not set)', '(referral)', '(organic)') THEN session_campaign
    WHEN session_campaign NOT IN ('(direct)',
    '(not set)',
    '(referral)',
    '(organic)')
    AND session_campaign LIKE ANY ("%CORP%",
      "%ACGO%",
      "%REOF%",
      "%ACPG%",
      "%NEWB%") THEN '(b2b campaigns)'
      ELSE '(other campaigns)'
  END
    AS session_campaign_grouped
FROM
  {{ref('final_cte_channel_mapping')}} ga4
LEFT JOIN
  {{ref('product_codes')}} pc
ON
 regexp_extract(lower(ga4.session_campaign),r'[A-z]{4}_([A-z0-9]{5})_[A-z0-9]{4}_.._[A-z0-9]{4}_[A-z0-9\-]{5}.*') = lower(pc.p_code)
  AND (
    (extract(year from ga4.event_date) <= 2025 AND pc.version = 'dict') OR 
    (extract(year from ga4.event_date) >= 2026 AND pc.version = 'v2')
  )
LEFT JOIN
  {{ref('audience_codes')}} ac
ON
regexp_extract(lower(ga4.session_campaign),r'([A-z]{4})_[A-z0-9]{5}_[A-z0-9]{4}_.._[A-z0-9]{4}_[A-z0-9\-]{5}.*')=lower(ac.a_code)
  AND (
    (extract(year from ga4.event_date) <= 2025 AND ac.version = 'dict') OR 
    (extract(year from ga4.event_date) >= 2026 AND ac.version = 'v2')
  )
LEFT JOIN
  {{ref('goal_codes')}} gc
ON
regexp_extract(lower(ga4.session_campaign),r'[A-z]{4}_[A-z0-9]{5}_([A-z0-9]{4})_.._[A-z0-9]{4}_[A-z0-9\-]{5}.*')=lower(gc.g_code)
  AND (
    (extract(year from ga4.event_date) <= 2025 AND gc.version = 'dict') OR 
    (extract(year from ga4.event_date) >= 2026 AND gc.version = 'v2')
  )
LEFT JOIN
  {{ref('geo_codes')}}  gec
ON
regexp_extract(lower(ga4.session_campaign),r'[A-z]{4}_[A-z0-9]{5}_[A-z0-9]{4}_(..)_[A-z0-9]{4}_[A-z0-9\-]{5}.*')=lower(gec.ge_code)
  AND (
    (extract(year from ga4.event_date) <= 2025 AND gec.version = 'dict') OR 
    (extract(year from ga4.event_date) >= 2026 AND gec.version = 'v2')
  )

{% if execute %}
    {% if is_incremental() %}
        WHERE ga4.event_date = DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% else %}
        WHERE ga4.event_date <= DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% endif %}
{% endif %}