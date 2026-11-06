-- A singular test fails if it returns any rows.
-- snid_to_mktps_step1 should have one row per (snid, journal_id, snt_code,
-- marketing_preference_id). An exact duplicate is counted twice by the
-- frequency ranking in snid_to_mktps_step2 and can push a subject into the
-- top 3 on its own.
--
-- marketing_preference_id is part of the key because one SNT can legitimately
-- roll up to more than one MPC subject through the hierarchy fallback.
--
-- History: the first run of this test (2026-11-06, dev) found 10,901,586
-- duplicate groups, from two causes since fixed in the model: the hierarchy
-- fallback also firing when a direct match existed, and 17 journals listed
-- twice in journal_metadata.

SELECT snid, journal_id, snt_code, marketing_preference_id, COUNT(*) AS n
FROM {{ ref('snid_to_mktps_step1') }}
GROUP BY snid, journal_id, snt_code, marketing_preference_id
HAVING COUNT(*) > 1
