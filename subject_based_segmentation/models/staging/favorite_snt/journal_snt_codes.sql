-- Journal -> SNT id resolution, built fresh and independently from the
-- favorite_mpc_subject project (which resolves journal -> SNT against the
-- OLD snt reference table). snt_discipline_code is validated against the
-- CURRENT snt reference table (snts_full_list): 100% match as of 2026-09.
--
-- SNT_Hierarchy1-4 is used ONLY as a fallback for the ~2.2% of journals
-- with no snt_discipline_code — NOT as an equal additional source. Checked
-- empirically (2026-09): SNT_Hierarchy1-4 values are dominated by broad
-- umbrella categories (e.g. "Life Sciences" appears on 44.6% of journals,
-- "Health Sciences" 31%, vs snt_discipline_code's most common value at only
-- 9.3%). Mixing both in as equal sources meant ~98% of journals — which
-- already had good specific discipline_code tags — also got these generic
-- top-level categories blended in, visibly skewing favorite_snt_predictions
-- toward "Biological/Life/Health Sciences" for most users.
--
-- journal_metadata.journal_id is INT64; users_and_journal_ids.journal_id is
-- STRING (parsed from JSON arrays) — cast to STRING to match throughout.

WITH from_discipline_code AS (
  SELECT
    CAST(jm.journal_id AS STRING) AS journal_id,
    TRIM(code) AS snt_id
  FROM {{ source('ae_metadata', 'journal_metadata') }} jm,
  UNNEST(SPLIT(jm.snt_discipline_code, ';')) AS code
  WHERE code IS NOT NULL
    AND TRIM(code) != ''
    AND TRIM(code) != 'NULL'
),

journals_with_discipline_code AS (
  SELECT DISTINCT journal_id FROM from_discipline_code
),

from_hierarchy_fallback AS (
  SELECT
    CAST(jm.journal_id AS STRING) AS journal_id,
    TRIM(CAST(snt AS STRING)) AS snt_id
  FROM {{ source('ae_metadata', 'journal_metadata') }} jm,
  UNNEST([jm.SNT_Hierarchy1, jm.SNT_Hierarchy2, jm.SNT_Hierarchy3, jm.SNT_Hierarchy4]) AS snt
  WHERE snt IS NOT NULL
    AND TRIM(CAST(snt AS STRING)) != ''
    AND TRIM(CAST(snt AS STRING)) != 'NULL'
    AND CAST(jm.journal_id AS STRING) NOT IN (SELECT journal_id FROM journals_with_discipline_code)
)

SELECT DISTINCT journal_id, snt_id
FROM (
  SELECT * FROM from_discipline_code
  UNION ALL
  SELECT * FROM from_hierarchy_fallback
)
