SELECT
  page_path,
  evt_date,
  ARRAY_AGG(STRUCT(event_name, event_category, event_action, event_label, percent_scrolled, event_count, country, device_category, link_url, aq_source, link_text)) AS event_data
FROM
  {{ ref('raw_ga4_base_event_data') }}
GROUP BY
  page_path,
  evt_date




