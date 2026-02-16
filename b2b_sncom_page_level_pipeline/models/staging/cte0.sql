{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            "field": "event_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by=['event_date', 'session_source', 'session_medium'],
        tags=['staging', 'incremental']
    )
}}

SELECT
    fb2b.* EXCEPT(session_source, session_medium, session_manual_ad_content, session_google_ads_ad_network_type),
    LOWER(fb2b.session_source) AS session_source,
    LOWER(fb2b.session_medium) AS session_medium,
    LOWER(fb2b.session_manual_ad_content) AS session_manual_ad_content,
    LOWER(fb2b.session_google_ads_ad_network_type) AS session_google_ads_ad_network_type,
    map.sn_area AS sn_area,
    map.funnel_stage AS funnel_stage,
    map.first_level_grouping AS first_level_grouping,
    map.second_level_grouping AS second_level_grouping,
    map.region AS page_region,
    SPLIT(page_location, '/') AS parts
  FROM
  {{ref('b2b_ga4_test_static')}} fb2b
  LEFT JOIN
    {{ref('b2b_webpages_map_full')}} map
  ON
    fb2b.page_location LIKE map.url

{% if execute %}
    {% if is_incremental() %}
        WHERE fb2b.event_date = DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% else %}
        WHERE fb2b.event_date <= DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
    {% endif %}
{% endif %}