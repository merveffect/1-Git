-- alias kept as the original physical table name (cdp_inferred_subjects) so
-- existing CDP consumers of this table are not broken by the rename
{{ config(materialized="table", alias="cdp_inferred_subjects") }}

WITH deleted AS (
  SELECT snid
  FROM {{ source('prod_mpc_dbt_presentation', 'snid_deletions') }}
),

base AS (
  SELECT
    snid,
    -- ARRAY of INT64: inferred MPC (marketing preference center) subject IDs,
    -- derived from journal SNTs via the SNT->MKTP mapping table
    ARRAY(
      SELECT SAFE_CAST(TRIM(s) AS INT64)
      FROM UNNEST(SPLIT(top_3_marketing_pref_ids, ';')) AS s
      WHERE SAFE_CAST(TRIM(s) AS INT64) IS NOT NULL
    ) AS inferred_mpc_subjects

  FROM {{ ref('snid_to_mktps_step2') }}
)

SELECT
  base.snid,
  base.inferred_mpc_subjects
FROM base
LEFT JOIN deleted USING (snid)
WHERE deleted.snid IS NULL
