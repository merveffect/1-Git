-- Clean pass-through of the SNT taxonomy source (ae_metadata.snts_full_list):
-- null, empty, and literal string "NULL" snt_id/label values are filtered
-- out once here, so every downstream consumer (snt_embeddings and anything
-- else) gets clean data without repeating the filter.

SELECT DISTINCT
    CAST(snt_id AS STRING) AS snt_id,
    label AS snt_name
FROM {{ source('ae_metadata', 'snts_full_list') }}
WHERE snt_id IS NOT NULL
    AND TRIM(CAST(snt_id AS STRING)) != ''
    AND TRIM(CAST(snt_id AS STRING)) != 'NULL'
    AND label IS NOT NULL
    AND TRIM(label) != ''

