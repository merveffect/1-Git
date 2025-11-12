



WITH j7_table AS (
  SELECT
    distinct journal_id,
    journal_title
  FROM
   `snproject-cbb9ca25`.`dev_rmdb_dbt_presentation`.`j7`
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
      `snproject52c6e272`.`xx_jflow`.`jflow` AS jf,
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