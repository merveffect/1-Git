{{ config(
    materialized = "incremental",
    partition_by = {"field": "status_date"},
    tags= ["daily", "ta_j7"]
 )}}



WITH j7_table AS (
  SELECT
    distinct journal_id,
    journal_title
  FROM
   {{ref('j7')}}
),

submissions AS (
  SELECT
    jf.journal_id,
    ps.selected_peer_review_system.peer_review_system_name AS peer_review_system_name,
    ps.selected_peer_review_system.site_status AS site_status,
    CASE 
      WHEN ps.selected_peer_review_system.site_status = 'Live' THEN ps.selected_peer_review_system.date_live
      WHEN ps.selected_peer_review_system.site_status = 'Ceased' THEN ps.selected_peer_review_system.date_ceased
      WHEN ps.selected_peer_review_system.site_status = 'Closed' THEN ps.selected_peer_review_system.date_closed
      WHEN ps.selected_peer_review_system.site_status = 'Suspended' THEN ps.selected_peer_review_system.date_suspended
    END AS status_date
  FROM
      {{source('xx_jflow','jflow')}} AS jf,
    UNNEST(peer_review) AS ps
    where
 COALESCE(
      ps.selected_peer_review_system.date_live,
      ps.selected_peer_review_system.date_ceased,
      ps.selected_peer_review_system.date_closed,
      ps.selected_peer_review_system.date_suspended
    ) IS NOT NULL
)
SELECT
distinct 
  j.journal_id,
  j.journal_title,
  s.peer_review_system_name AS peer_review_system,
  s.site_status,
  date(s.status_date) as status_date
FROM
  j7_table AS j
LEFT JOIN
  submissions s
  ON
  j.journal_id = s.journal_id

--  {% if is_incremental() %}
--   WHERE date(status_date) BETWEEN 
--         COALESCE(
--           DATE('{{ var("backfill_start_date", "") }}') ,
--           DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
--         )
--         AND
--         COALESCE(
--           DATE('{{ var("backfill_end_date", "") }}') ,
--           DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
--         )
-- {% else %}
--   WHERE date(status_date) BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
--                   AND DATE('{{ var("end_date", "2025-12-31") }}')
-- {% endif %}


