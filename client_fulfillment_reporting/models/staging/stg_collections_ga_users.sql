SELECT
  page_path,
  evt_date,
  ARRAY_AGG(STRUCT(user_pseudo_id)) AS user_data
FROM
  {{ ref('raw_ga4_user_logs') }}
GROUP BY
  page_path,
  evt_date