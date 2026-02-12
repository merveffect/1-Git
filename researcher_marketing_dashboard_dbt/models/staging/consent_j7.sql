{{ config(
    materialized = "incremental",
    incremental_strategy="insert_overwrite",
    partition_by = {"field": "date", "data_type": "date"},
    tags= ["daily", "j7", "ta_j7", "transposed_awa1", "transposed_bae", "transposed_nurture"]
 )}}

WITH
  main AS (
  -- GA4 session data
  SELECT
    date,
    campaign,
    SOURCE,
    medium,
    main_channels,
    sub_channels,
    imprint,
    researchER_marketing_activity,
    research_marketing_activity,
    SUM(sessions) AS sessions
  FROM
    {{ref("j7")}}  
    
    {{ incremental_date_filter('date') }}

  GROUP BY ALL ),
  consent_events AS (
  -- Consent events aggregated by type
  SELECT
    date AS consent_date,
    LOWER(utm_campaign) AS utm_campaign,
    LOWER(utm_source) AS utm_source,
    LOWER(utm_medium) AS utm_medium,
    sub_channels AS consent_channels,
    main_domain,
    event_name,
    consent_context,
    SUM(freq_events) AS freq_events
  FROM
    {{source('cookie_consent_data',"marketing_view")}}
   
   {{ incremental_date_filter('date') }}

  GROUP BY ALL ),
  aggregations AS (
  -- Join GA4 and consent data
  SELECT
    m.*,
    c.consent_date,
    c.utm_campaign,
    c.utm_source,
    c.utm_medium,
    c.consent_channels,
    c.main_domain,
    c.event_name,
    c.freq_events,
    c.consent_context
  FROM
    main m
  LEFT JOIN
    consent_events c
  ON
    m.date = c.consent_date
    AND m.campaign = c.utm_campaign
    AND m.source = c.utm_source
    AND m.medium = c.utm_medium
    AND m.imprint = c.main_domain )
    -- Final output with consent-specific aggregations
SELECT
  date,
  campaign,
  SOURCE,
  medium,
  main_channels,
  sub_channels,
  imprint,
  researchER_marketing_activity,
  research_marketing_activity,
  Sessions,
  consent_date,
  utm_campaign,
  utm_source,
  utm_medium,
  consent_channels,
  main_domain,
  SUM(CASE
      WHEN event_name = 'banner_visible' THEN freq_events
      ELSE 0
  END
    ) AS total_banner_visible,
  SUM(CASE
      WHEN event_name = 'close_cookie_preferences' THEN freq_events
      ELSE 0
  END
    ) AS total_close_cookie_preferences,
  SUM(CASE
      WHEN event_name = 'manage_cookie_preferences' THEN freq_events
      ELSE 0
  END
    ) AS total_manage_cookie_preferences,
  SUM(CASE
      WHEN event_name = 'save_cookie_preferences' THEN freq_events
      ELSE 0
  END
    ) AS total_save_cookie_preferences,
  SUM(CASE
      WHEN event_name = 'accept_all_cookies' AND consent_context = 'Cookie banner' THEN freq_events
      ELSE 0
  END
    ) AS total_accept_all_cookies,
  SUM(CASE
      WHEN event_name = 'accept_all_cookies' AND consent_context = 'Preferences dialog' THEN freq_events
      ELSE 0
  END
    ) AS total_accept_all_cookies_preference_dialogue,
  SUM(CASE
      WHEN event_name = 'manage_cookie_preferences' OR (event_name = 'accept_all_cookies' AND consent_context = 'Cookie banner') OR (event_name = 'reject_non_essential_cookies' AND consent_context = 'Cookie banner') THEN freq_events
      ELSE 0
  END
    ) AS total_interaction,
  SUM(CASE
      WHEN event_name = 'reject_non_essential_cookies' AND consent_context = 'Cookie banner' THEN freq_events
      ELSE 0
  END
    ) AS total_reject_non_essential_cookies,
  SUM(CASE
      WHEN event_name = 'reject_non_essential_cookies' AND consent_context = 'Preferences dialog' THEN freq_events
      ELSE 0
  END
    ) AS total_reject_non_essential_cookies_preference_dialogue
FROM
  aggregations
GROUP BY ALL
