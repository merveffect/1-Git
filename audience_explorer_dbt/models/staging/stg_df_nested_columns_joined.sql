WITH base AS (
    SELECT *
    FROM {{ ref('stg_df_audience_explorer_base') }}
),
subs AS (
    SELECT * 
    FROM {{ ref('stg_submissions') }}
),
life AS (
    SELECT * 
    FROM {{ ref('stg_lifetime_aggregations') }}
)

SELECT
    base.*,
    subs.submissions AS submissions,
    life.* EXCEPT(canonical_segment_id)
FROM base
LEFT JOIN subs USING (canonical_segment_id)
LEFT JOIN life USING (canonical_segment_id)

