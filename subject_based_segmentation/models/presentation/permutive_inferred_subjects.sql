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

subject_source AS (
    SELECT
        snid,
        top_3_marketing_pref_ids AS inferred_subjects
    FROM {{ ref('snid_to_mktps_step2') }}
    WHERE snid IS NOT NULL
      AND top_3_marketing_pref_ids IS NOT NULL
),

-- 🔥 Burada ID’lerin başına "isnt" prefix'i ekliyoruz
prefixed AS (
    SELECT
        snid,
        ARRAY_TO_STRING(
            ARRAY(
                SELECT CONCAT('isnt', TRIM(id))
                FROM UNNEST(
                    SPLIT(
                        REPLACE(REPLACE(inferred_subjects, ';', ','), ':', ','),
                        ','
                    )
                ) AS id
                WHERE TRIM(id) != ''
            ),
            ','
        ) AS prefixed_inferred_subjects
    FROM subject_source
),


joined AS (
    SELECT DISTINCT
        s.snid,
        s.prefixed_inferred_subjects
    FROM prefixed s
    JOIN optin_snids o
      ON s.snid = o.snid
)

SELECT
    CONCAT(CAST(snid AS STRING), ' ', prefixed_inferred_subjects) AS snid_and_subjects
FROM joined

