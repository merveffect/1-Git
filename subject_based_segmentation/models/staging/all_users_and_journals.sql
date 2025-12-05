WITH cte_user_journals AS (
SELECT DISTINCT
    snid,
    TRIM(journal_id) AS journal_id
  FROM (
    -- 1️⃣ last_submission_journal_id
    SELECT snid, CAST(last_submission_journal_id AS STRING) AS journal_id
    FROM {{ref('users_with_journal_signal')}}
    WHERE last_submission_journal_id IS NOT NULL

    UNION ALL

    -- 2️⃣ read_last_30d
    SELECT snid, TRIM(x) AS journal_id
    FROM {{ref('users_with_journal_signal')}},
    UNNEST(SPLIT(REGEXP_REPLACE(REGEXP_REPLACE(read_last_30d, r'[\[\]\"]', ''), ';', ','), ',')) AS x
    WHERE read_last_30d IS NOT NULL

    UNION ALL

    -- 3️⃣ read_last_60d
    SELECT snid, TRIM(x) AS journal_id
    FROM {{ref('users_with_journal_signal')}},
    UNNEST(SPLIT(REGEXP_REPLACE(REGEXP_REPLACE(read_last_60d, r'[\[\]\"]', ''), ';', ','), ',')) AS x
    WHERE read_last_60d IS NOT NULL

    UNION ALL

    -- 4️⃣ journals_etocs_180d
    SELECT snid, TRIM(x) AS journal_id
    FROM {{ref('users_with_journal_signal')}},
    UNNEST(SPLIT(REGEXP_REPLACE(REGEXP_REPLACE(journals_etocs_180d, r'[\[\]\"]', ''), ';', ','), ',')) AS x
    WHERE journals_etocs_180d IS NOT NULL

    UNION ALL

    -- 5️⃣ journals_submguide_last_30d
    SELECT snid, TRIM(x) AS journal_id
    FROM {{ref('users_with_journal_signal')}},
    UNNEST(SPLIT(REGEXP_REPLACE(REGEXP_REPLACE(journals_submguide_last_30d, r'[\[\]\"]', ''), ';', ','), ',')) AS x
    WHERE journals_submguide_last_30d IS NOT NULL

    UNION ALL

    -- 6️⃣ journals_submguide_last_60d
    SELECT snid, TRIM(x) AS journal_id
    FROM {{ref('users_with_journal_signal')}},
    UNNEST(SPLIT(REGEXP_REPLACE(REGEXP_REPLACE(journals_submguide_last_60d, r'[\[\]\"]', ''), ';', ','), ',')) AS x
    WHERE journals_submguide_last_60d IS NOT NULL

    UNION ALL

    -- 7️⃣ journals_subm_alltime
    SELECT snid, TRIM(x) AS journal_id
    FROM {{ref('users_with_journal_signal')}},
    UNNEST(SPLIT(REGEXP_REPLACE(REGEXP_REPLACE(journals_subm_alltime, r'[\[\]\"]', ''), ';', ','), ',')) AS x
    WHERE journals_subm_alltime IS NOT NULL

    UNION ALL

    -- 8️⃣ list_journal_etocs_last_180_d
    SELECT snid, TRIM(x) AS journal_id
    FROM {{ref('users_with_journal_signal')}},
    UNNEST(SPLIT(REGEXP_REPLACE(REGEXP_REPLACE(list_journal_etocs_last_180_d, r'[\[\]\"]', ''), ';', ','), ',')) AS x
    WHERE list_journal_etocs_last_180_d IS NOT NULL

    UNION ALL

    -- 9️⃣ list_journals_allpageviews_30_d
    SELECT snid, TRIM(x) AS journal_id
    FROM {{ref('users_with_journal_signal')}},
    UNNEST(SPLIT(REGEXP_REPLACE(REGEXP_REPLACE(list_journals_allpageviews_30_d, r'[\[\]\"]', ''), ';', ','), ',')) AS x
    WHERE list_journals_allpageviews_30_d IS NOT NULL
  )
  WHERE journal_id IS NOT NULL AND journal_id != ''
)


SELECT snid, journal_id
FROM cte_user_journals
GROUP BY snid, journal_id
ORDER BY snid



