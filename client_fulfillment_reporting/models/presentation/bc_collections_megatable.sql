-- Combine everything into one table with COALESCE
SELECT
  COALESCE(a.evt_date, b.evt_date, c.evt_date) AS evt_date,
  COALESCE(a.page_path, b.page_path, c.page_path) AS page_path,
  a.event_data,
  b.pageview_data,
  c.user_data,
  d.collection_id,
  d.collection_title AS collection_name,
  d.full_article_url,
  d.page_title,
  e.workfront_project_id AS wf_project_id,
  e.workfront_project_name AS wf_project_name,
  e.page_url AS wf_page_url,
  e.sponsor_feature_url AS wf_sponsor_feature_url,
  e.client_name AS wf_client_name,
  e.date_range_start AS wf_date_range_start,
  e.collection_title AS wf_collection_title
FROM {{ref('stg_collections_ga_events')}} AS a
FULL JOIN {{ref('stg_collections_ga_pageview')}} AS b
  USING (evt_date, page_path)
FULL JOIN {{ref('stg_collections_ga_users')}} AS c
  USING (evt_date, page_path)
INNER JOIN {{ref('stg_gsheet_wf_metadata')}} AS d
  USING (page_path)
LEFT JOIN {{ref('raw_workfront_metadata')}} AS e
  USING (collection_id)



