-- A singular test fails if it returns any rows.
-- Predictions are derived personal data, so a deletion request must remove
-- them from this table too — filtering them out of the CDI-facing output
-- alone would still leave the data retained here.

SELECT p.snid
FROM {{ ref('favorite_snt_predictions') }} p
JOIN {{ source('prod_mpc_dbt_presentation', 'snid_deletions') }} d
  ON d.snid = p.snid
