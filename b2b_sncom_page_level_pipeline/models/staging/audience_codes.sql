SELECT
    DISTINCT code AS a_code,
    CURRENT_DATE() AS event_date,
    version
  FROM
    {{ref('naming_conventions')}} a
  WHERE
    a.code_type = 'audience'