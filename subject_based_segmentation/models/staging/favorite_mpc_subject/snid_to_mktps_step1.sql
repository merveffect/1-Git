WITH cte_user_journals AS (
  SELECT *
  FROM {{ ref('all_users_and_journals') }}
),


cte_journal_snt AS (
  --  journal → S&T (discipline + label), one row per (journal_id, snt_code).
  -- journal_metadata holds some journals more than once (17 as of 2026-11);
  -- without the GROUP BY every reader of such a journal would count its
  -- subjects twice in the step 2 frequency ranking. MIN() picks the label
  -- deterministically if the duplicate rows disagree.
  SELECT
    jm.journal_id,
    TRIM(disc_code) AS snt_code,
    MIN(TRIM(disc_label)) AS snt_label
  FROM {{source('ae_metadata', 'journal_metadata')}} jm
  LEFT JOIN UNNEST(SPLIT(jm.snt_discipline_code, ';')) AS disc_code WITH OFFSET AS pos1
  LEFT JOIN UNNEST(SPLIT(jm.snt_discipline, ';')) AS disc_label WITH OFFSET AS pos2
    ON pos1 = pos2
  WHERE disc_code IS NOT NULL
    AND TRIM(disc_code) != ''
    AND disc_label IS NOT NULL
  GROUP BY jm.journal_id, TRIM(disc_code)
),

cte_user_snt AS (
  SELECT
    uj.snid,
    uj.journal_id,
    js.snt_code,
    js.snt_label
  FROM cte_user_journals uj
  JOIN cte_journal_snt js
    ON SAFE_CAST(uj.journal_id AS INT64) = js.journal_id
),

cte_snt_mktp AS (
  -- S&T → Marketing Preference 
  SELECT
    us.snid,
    us.journal_id,
    us.snt_code,
    us.snt_label,
    COALESCE(
      direct_map.marketing_preference_id,
      fallback_map.marketing_preference_id
    ) AS marketing_preference_id,
    COALESCE(
      direct_map.marketing_preference,
      fallback_map.marketing_preference
    ) AS marketing_preference
  FROM cte_user_snt us

  -- direct map
  LEFT JOIN {{source('subject_based_segmentation', 'snts_mktps_mapped_final')}} direct_map
    ON us.snt_code = direct_map.marketing_preference_id

  -- fallback match: only when there is no direct match. Without the
  -- IS NULL guard, a code that matches directly AND sits in the hierarchy of
  -- N mapping rows produced N identical rows (COALESCE picks the direct value
  -- for all of them), inflating that subject's frequency N-fold.
  LEFT JOIN {{source('subject_based_segmentation', 'snts_mktps_mapped_final')}} fallback_map
    ON direct_map.marketing_preference_id IS NULL
   AND us.snt_code IN UNNEST(
      ARRAY_CONCAT(
        IFNULL(fallback_map.level_1_id, []),
        IFNULL(fallback_map.level_2_id, []),
        IFNULL(fallback_map.level_3_id, []),
        IFNULL(fallback_map.level_4_id, []),
        IFNULL(fallback_map.level_5_id, []),
        IFNULL(fallback_map.level_6_id, [])
      )
    )
)

select * from cte_snt_mktp





