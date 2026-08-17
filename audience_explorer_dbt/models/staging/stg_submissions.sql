SELECT
  t.canonical_segment_id,
  ARRAY(
    SELECT AS STRUCT
      JSON_VALUE(item, '$.imprint')       AS imprint,
      JSON_VALUE(item, '$.journal_id')    AS journal_id,
      JSON_VALUE(item, '$.journal_title') AS journal_title,
      SAFE_CAST(JSON_VALUE(item, '$.submission_timestamp') AS TIMESTAMP) AS submission_timestamp
    FROM UNNEST(JSON_EXTRACT_ARRAY(t.value, '$')) AS item
    ORDER BY SAFE_CAST(JSON_VALUE(item, '$.submission_timestamp') AS TIMESTAMP) DESC
  ) AS submissions
FROM {{ ref('raw_user_traits') }} AS t
WHERE t.name = 'submissions'
qualify row_number() over (
    partition by t.canonical_segment_id
    order by t.received_at desc
) = 1