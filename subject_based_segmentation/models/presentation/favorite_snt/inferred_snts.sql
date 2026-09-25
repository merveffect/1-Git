{{ config(materialized='table') }}

-- Final output for the CDI pipeline. Straight reshape of the already fully
-- computed favorite_snt_predictions — no batching/looping needed here,
-- this is a cheap read+rename of existing data, not a VECTOR_SEARCH.
--
-- CONTRACT: table name (inferred_snts) and column names (inferred_snt_id,
-- inferred_snt_name) are consumed directly by an external system (CDI) —
-- do not rename without coordinating with them first.

SELECT
    snid,
    snt_id AS inferred_snt_id,
    snt_name AS inferred_snt_name
FROM {{ ref('favorite_snt_predictions') }}
