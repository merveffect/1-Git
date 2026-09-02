-- alias and the "isnt" ID prefix are an existing contract with Permutive's
-- segment feed — kept unchanged so the live integration doesn't break
{{ config(
    alias = "permutive_inferred_subjects",
    tags = ["poc"]
) }}

WITH optin_snids AS (
    SELECT DISTINCT
        snid
    FROM {{ source('prod_audience_explorer_analytics_dbt_presentation', 'audience_builder_big') }}
    WHERE snid IS NOT NULL
),


mpc_subject_source AS (
    SELECT
        snid,
        top_3_marketing_pref_ids AS inferred_mpc_subject_ids
    FROM {{ ref('snid_to_mktps_step2') }}
    WHERE snid IS NOT NULL
      AND top_3_marketing_pref_ids IS NOT NULL
),


prefixed AS (
    SELECT
        snid,
        ARRAY_TO_STRING(
            ARRAY(
                SELECT CONCAT('isnt', TRIM(id))
                FROM UNNEST(
                    SPLIT(
                        REPLACE(REPLACE(inferred_mpc_subject_ids, ';', ','), ':', ','),
                        ','
                    )
                ) AS id
                WHERE TRIM(id) != ''
            ),
            ','
        ) AS prefixed_mpc_subject_ids
    FROM mpc_subject_source
),


joined AS (
    SELECT DISTINCT
        s.snid,
        s.prefixed_mpc_subject_ids
    FROM prefixed s
    JOIN optin_snids o
      ON s.snid = o.snid
)

SELECT
    CONCAT(CAST(snid AS STRING), ' ', prefixed_mpc_subject_ids) AS snid_and_mpc_subjects
FROM joined

