WITH cte_user_journals AS (
  SELECT *
  FROM {{ ref('all_users_and_journals') }}
),


cte_user_snt AS (
  -- 🧠 ADIM 2: journal → S&T (discipline + label)
  SELECT
    uj.snid,
    uj.journal_id,
    TRIM(disc_code) AS snt_code,
    TRIM(disc_label) AS snt_label
  FROM cte_user_journals uj
  JOIN {{source('ae_metadata', 'journal_metadata')}} jm
    ON SAFE_CAST(uj.journal_id AS INT64) = jm.journal_id
  LEFT JOIN UNNEST(SPLIT(jm.snt_discipline_code, ';')) AS disc_code WITH OFFSET AS pos1
  LEFT JOIN UNNEST(SPLIT(jm.snt_discipline, ';')) AS disc_label WITH OFFSET AS pos2
    ON pos1 = pos2
  WHERE disc_code IS NOT NULL
    AND disc_code != ''
    AND disc_label IS NOT NULL
),

cte_snt_mktp AS (
  -- 🎯 ADIM 3: S&T → Marketing Preference eşleşmesi
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

  -- 🔹 1️⃣ Doğrudan eşleşme (S&T kodu = Marketing Preference ID)
  LEFT JOIN {{source('subject_based_segmentation', 'SNTS-MKTPS_MAPPED_FINAL')}} direct_map
    ON us.snt_code = direct_map.marketing_preference_id

  -- 🔹 2️⃣ Fallback eşleşme (S&T kodu level kolonlarında geçiyorsa)
  LEFT JOIN {{source('subject_based_segmentation', 'SNTS-MKTPS_MAPPED_FINAL')}} fallback_map
    ON us.snt_code IN UNNEST(
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





