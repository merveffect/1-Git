

WITH main AS (
    SELECT
        DISTINCT rcpt_to AS rcpt_to,
        JSON_EXTRACT(rcpt_meta.json, '$.journalId') AS journal_id,
        REGEXP_EXTRACT(subject, r'(.*?)[-:]') AS journal_title,
        MIN(DATE(timestamp)) AS time_firstseen
    FROM `poc-spring-email-metrics`.`sparkpost_metrics_live`.`message_event`
    WHERE type = 'delivery'
      AND REGEXP_CONTAINS(campaign_id, 'toc-alert')
      AND subject != 'Confirm your email for journal alerts'
    GROUP BY 1,2,3
)

SELECT
  time_firstseen AS etoc_date,
  journal_id,
  journal_title,
  COUNT(DISTINCT(rcpt_to)) AS num_etoc_signups
FROM
  main


  WHERE DATE(time_firstseen) BETWEEN 
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
    
    AND
    
      CURRENT_DATE()
    

GROUP BY
  1,
  2,
  3