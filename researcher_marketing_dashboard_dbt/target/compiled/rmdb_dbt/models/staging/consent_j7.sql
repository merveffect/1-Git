

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
    `snproject-cbb9ca25`.`dev_rmdb_dbt_presentation`.`j7`
     
    
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-11-09')


  GROUP BY
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9 ),
  consent_events AS (
  -- Consent events aggregated by type
  SELECT
    date AS consent_date,
    LOWER(utm_campaign) AS utm_campaign,
    LOWER(utm_source) AS utm_source,
    LOWER(utm_medium) AS utm_medium,
    marmind_channels AS consent_channels,
    page_location,
    event_name,
    consent_context,
    SUM(freq_events) AS freq_events
  FROM
    `snproject-cbb9ca25`.`cookie_consent_data`.`marketing_view`
    
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-11-09')

  GROUP BY
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8 ),
  aggregations AS (
  -- Join GA4 and consent data
  SELECT
    m.*,
    c.consent_date,
    c.utm_campaign,
    c.utm_source,
    c.utm_medium,
    c.consent_channels,
    c.page_location,
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
    AND m.imprint = c.page_location )
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
  page_location,
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
GROUP BY
  date,
  campaign,
  SOURCE,
  medium,
  main_channels,
  sub_channels,
  imprint,
  researchER_marketing_activity,
  research_marketing_activity,
  consent_date,
  utm_campaign,
  utm_source,
  utm_medium,
  consent_channels,
  page_location,
  Sessions