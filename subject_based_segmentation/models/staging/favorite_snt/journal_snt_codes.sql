-- Journal -> SNT id resolution, built fresh and independently from the
-- favorite_mpc_subject project (which resolves journal -> SNT against the
-- OLD snt reference table). The snt_discipline_code branch is validated
-- against the CURRENT snt reference table (snts_full_list): 100% match as
-- of 2026-09. The SNT_Hierarchy1-4 branch is a second, separate source of
-- journal->SNT associations on journal_metadata (not every journal's SNTs
-- live in snt_discipline_code alone) — not yet separately validated.
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

from_hierarchy AS (
  SELECT
    CAST(jm.journal_id AS STRING) AS journal_id,
    TRIM(CAST(snt AS STRING)) AS snt_id
  FROM {{ source('ae_metadata', 'journal_metadata') }} jm,
  UNNEST([jm.SNT_Hierarchy1, jm.SNT_Hierarchy2, jm.SNT_Hierarchy3, jm.SNT_Hierarchy4]) AS snt
  WHERE snt IS NOT NULL
    AND TRIM(CAST(snt AS STRING)) != ''
    AND TRIM(CAST(snt AS STRING)) != 'NULL'
)

SELECT DISTINCT journal_id, snt_id
FROM (
  SELECT * FROM from_discipline_code
  UNION ALL
  SELECT * FROM from_hierarchy
)
