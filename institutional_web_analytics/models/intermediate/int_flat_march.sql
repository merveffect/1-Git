{{ config(
    materialized = 'incremental',
    schema = 'Institutional_analysisGA4_EU',
    description = 'Flattens all necessary event parameters and user properties, handling multiple BPID formats.'
) }}

WITH source_data AS (

    SELECT *
    FROM {{ ref('stg_base_table_2025') }}

    WHERE user_pseudo_id IS NOT NULL

    {% if is_incremental() %}
      AND DATE(event_timestamp) = DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY))
    {% else %}
      AND DATE(event_timestamp) >= DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY))
    {% endif %}

),

/* ---------- BPID stored as INT ---------- */
temp1_standard_bpid AS (

    SELECT
        DATE(TIMESTAMP_TRUNC(event_timestamp, DAY)) AS event_date,
        user_pseudo_id,
        event_name,
        hostname,
        medium,
        source,
        medium1,
        source1,
        medium2,
        source2,
        city,
        country,
        continent,
        sub_continent,

        (SELECT MAX(CASE WHEN key = 'content_type' THEN value.string_value END)
         FROM UNNEST(event_params)) AS content_type,

        (SELECT MAX(CASE WHEN key = 'search_term' THEN value.string_value END)
         FROM UNNEST(event_params)) AS search_term,

        (SELECT value.int_value
         FROM UNNEST(event_params)
         WHERE key = 'ga_session_id') AS ga_session_id,

        (SELECT MAX(CASE WHEN key = 'session_engaged' THEN value.string_value END)
         FROM UNNEST(event_params)) AS session_engaged,

        (SELECT MAX(CASE WHEN key = 'engagement_time_msec' THEN value.int_value END)
         FROM UNNEST(event_params)) AS engagement_time_msec,

        CAST(
            (SELECT up.value.int_value
             FROM UNNEST(user_properties) up
             WHERE up.key = 'bpid'
               AND up.value.int_value IS NOT NULL)
            AS STRING
        ) AS bpid

    FROM source_data
),

/* ---------- BPID stored as STRING (pipe / comma / semicolon separated) ---------- */
temp2_string_bpid AS (

    SELECT
        *,
        SPLIT(
            REGEXP_REPLACE(
                REGEXP_REPLACE(raw_bpid_string, '\\|', ','),
                ';',
                ','
            ),
            ','
        ) AS bpidarray
    FROM (
        SELECT
            DATE(TIMESTAMP_TRUNC(event_timestamp, DAY)) AS event_date,
            user_pseudo_id,
            event_name,
            hostname,
            medium,
            source,
            medium1,
            source1,
            medium2,
            source2,
            city,
            country,
            continent,
            sub_continent,

            (SELECT MAX(CASE WHEN key = 'content_type' THEN value.string_value END)
             FROM UNNEST(event_params)) AS content_type,

            (SELECT MAX(CASE WHEN key = 'search_term' THEN value.string_value END)
             FROM UNNEST(event_params)) AS search_term,

            (SELECT value.int_value
             FROM UNNEST(event_params)
             WHERE key = 'ga_session_id') AS ga_session_id,

            (SELECT MAX(CASE WHEN key = 'session_engaged' THEN value.string_value END)
             FROM UNNEST(event_params)) AS session_engaged,

            (SELECT MAX(CASE WHEN key = 'engagement_time_msec' THEN value.int_value END)
             FROM UNNEST(event_params)) AS engagement_time_msec,

            (SELECT up.value.string_value
             FROM UNNEST(user_properties) up
             WHERE up.key = 'bpid'
               AND up.value.string_value IS NOT NULL
            ) AS raw_bpid_string

        FROM source_data
        WHERE (SELECT up.value.string_value
               FROM UNNEST(user_properties) up
               WHERE up.key = 'bpid'
                 AND up.value.string_value IS NOT NULL
        ) IS NOT NULL
    )
)

/* ---------- FINAL UNION ---------- */
SELECT
    t1.event_date,
    t1.user_pseudo_id,
    t1.event_name,
    t1.hostname,
    t1.source,
    t1.medium,
    t1.source1,
    t1.medium1,
    t1.source2,
    t1.medium2,
    t1.city,
    t1.country,
    t1.continent,
    t1.sub_continent,
    t1.content_type,
    t1.search_term,
    t1.bpid,
    t1.ga_session_id,
    t1.session_engaged,
    t1.engagement_time_msec
FROM temp1_standard_bpid t1
WHERE t1.bpid IS NOT NULL

UNION ALL

SELECT
    t2.event_date,
    t2.user_pseudo_id,
    t2.event_name,
    t2.hostname,
    t2.source,
    t2.medium,
    t2.source1,
    t2.medium1,
    t2.source2,
    t2.medium2,
    t2.city,
    t2.country,
    t2.continent,
    t2.sub_continent,
    t2.content_type,
    t2.search_term,
    bpid,
    t2.ga_session_id,
    t2.session_engaged,
    t2.engagement_time_msec
FROM temp2_string_bpid t2,
UNNEST(t2.bpidarray) AS bpid
WHERE bpid IS NOT NULL
