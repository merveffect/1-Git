-- Journal -> SNT id resolution, built fresh and independently from the
-- favorite_mpc_subject project (which resolves journal -> SNT against the
-- OLD snt reference table). This one is validated against the CURRENT
-- snt reference table (snts_full_list): 100% of journal_metadata's SNT
-- codes matched snts_full_list.snt_id as of 2026-09.

SELECT DISTINCT
  jm.journal_id,
  TRIM(code) AS snt_id
FROM {{ source('ae_metadata', 'journal_metadata') }} jm,
UNNEST(SPLIT(jm.snt_discipline_code, ';')) AS code
WHERE code IS NOT NULL AND TRIM(code) != ''
