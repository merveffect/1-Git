{{ config(
    materialized = "incremental",
    partition_by = {"field": "etoc_date"},
    incremental_strategy = "insert_overwrite"
) }}

WITH main AS (
    SELECT
        DISTINCT rcpt_to AS rcpt_to,
        JSON_EXTRACT(rcpt_meta.json, '$.journalId') AS journal_id,
        REGEXP_EXTRACT(subject, r'(.*?)[-:]') AS journal_title,
        MIN(DATE(timestamp)) AS time_firstseen
    FROM {{ source('sparkpost_metrics_live','message_event') }}
    WHERE type = 'delivery'
      AND REGEXP_CONTAINS(campaign_id, 'toc-alert')
      AND subject != 'Confirm your email for journal alerts'
    GROUP BY 1,2,3
)

SELECT
    time_firstseen AS etoc_date,
    journal_id,
    journal_title,
    COUNT(DISTINCT rcpt_to) AS num_etoc_signups
FROM main
{% if is_incremental() %}
    WHERE DATE(time_firstseen) BETWEEN
          COALESCE(DATE('{{ var("backfill_start_date", "") }}'), DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY))
      AND COALESCE(DATE('{{ var("backfill_end_date", "") }}'), CURRENT_DATE())
{% else %}
    WHERE DATE(time_firstseen) BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                            AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}
GROUP BY 1,2,3
