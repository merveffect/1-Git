-- A singular test fails if it returns any rows.
-- Every predicted id must be a real MPC subject, i.e. a marketing_preference_id
-- in the SNT -> MPC mapping table. An unknown id would reach Braze as a
-- subject that no campaign can target.

WITH valid AS (
  SELECT DISTINCT SAFE_CAST(marketing_preference_id AS INT64) AS id
  FROM {{ source('subject_based_segmentation', 'snts_mktps_mapped_final') }}
  WHERE marketing_preference_id IS NOT NULL
)

SELECT c.snid, id AS unknown_mpc_subject_id
FROM {{ ref('cdp_inferred_mpc_subjects') }} c,
UNNEST(c.inferred_mpc_subjects) AS id
WHERE id NOT IN (SELECT id FROM valid WHERE id IS NOT NULL)
