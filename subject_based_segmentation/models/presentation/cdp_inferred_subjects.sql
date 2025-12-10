{{ config(materialized="table") }}

WITH deleted AS (
  SELECT snid
  FROM {{ source('prod_mpc_dbt_raw', 'raw_snid_deletions') }}
),

base AS (
  SELECT 
    snid,
    -- ARRAY of INT64
ARRAY(
  SELECT SAFE_CAST(TRIM(s) AS INT64)
  FROM UNNEST(SPLIT(top_3_marketing_pref_ids, ';')) AS s
  WHERE SAFE_CAST(TRIM(s) AS INT64) IS NOT NULL
) AS isubjects

  FROM {{ ref('snid_to_mktps_step2') }}
)

SELECT 
  base.snid,
  base.isubjects
FROM base
LEFT JOIN deleted USING (snid)
WHERE deleted.snid IS NULL 
