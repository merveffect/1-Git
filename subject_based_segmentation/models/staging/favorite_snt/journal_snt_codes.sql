-- Journal -> SNT id resolution, built fresh and independently from the
-- favorite_mpc_subject project (which resolves journal -> SNT against the
-- OLD snt reference table). This one is validated against the CURRENT
-- snt reference table (snts_full_list): 100% of journal_metadata's SNT
-- codes matched snts_full_list.snt_id as of 2026-09.

SELECT DISTINCT
  -- journal_metadata.journal_id is INT64; users_and_journal_ids.journal_id
  -- is STRING (parsed from JSON arrays) — cast to STRING to match
  CAST(jm.journal_id AS STRING) AS journal_id,
  TRIM(code) AS snt_id
FROM {{ source('ae_metadata', 'journal_metadata') }} jm,
UNNEST(SPLIT(jm.snt_discipline_code, ';')) AS code
WHERE code IS NOT NULL AND TRIM(code) != ''
