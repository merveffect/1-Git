
-- STEP 2: Aggregate and extract top 3 marketing preferences per SNID
WITH final_cte AS (
  SELECT
    snid,
    STRING_AGG(DISTINCT CAST(journal_id AS STRING)) AS all_journal_ids,
    STRING_AGG(DISTINCT snt_code) AS all_snt_codes,
    STRING_AGG(DISTINCT snt_label) AS all_snt_labels,
    STRING_AGG(DISTINCT marketing_preference_id, ',') AS all_marketing_ids,
    STRING_AGG(DISTINCT marketing_preference, ';') AS all_marketing_preferences
  FROM {{ ref('snid_to_mktps_step1') }}
  GROUP BY snid
),

ranked_cte AS (
  SELECT
    snid,
    marketing_preference_id,
    marketing_preference,
    COUNT(*) AS freq,
    -- marketing_preference_id breaks ties so the top 3 is deterministic across
    -- runs; without it, equal-frequency subjects at rank 3 swap arbitrarily.
    -- The id is a STRING, so it is cast to INT64 first: a plain string sort
    -- puts '10' before '9' and the "lower id wins" rule would not hold. The
    -- raw string stays as a last key in case an id is ever non-numeric.
    ROW_NUMBER() OVER(
      PARTITION BY snid
      ORDER BY COUNT(*) DESC,
               SAFE_CAST(marketing_preference_id AS INT64),
               marketing_preference_id
    ) AS rn
  FROM {{ ref('snid_to_mktps_step1') }}
  WHERE marketing_preference IS NOT NULL
  GROUP BY snid, marketing_preference_id, marketing_preference
)

SELECT
  f.snid,
  f.all_journal_ids,
  f.all_snt_codes,
  f.all_snt_labels,
  f.all_marketing_ids,
  f.all_marketing_preferences,
  -- ORDER BY rn keeps the list in rank order. Without it the order of the 3
  -- ids is arbitrary, and a reshuffled array looks like a profile change
  -- downstream (Braze) even when the set is the same.
  STRING_AGG(r.marketing_preference_id, ';' ORDER BY r.rn) AS top_3_marketing_pref_ids,
  STRING_AGG(r.marketing_preference, ';' ORDER BY r.rn) AS top_3_marketing_prefs
FROM final_cte f
LEFT JOIN ranked_cte r
  ON f.snid = r.snid AND r.rn <= 3
GROUP BY
  f.snid,
  f.all_journal_ids,
  f.all_snt_codes,
  f.all_snt_labels,
  f.all_marketing_ids,
  f.all_marketing_preferences
ORDER BY f.snid

