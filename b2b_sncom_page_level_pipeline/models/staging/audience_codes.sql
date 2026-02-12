SELECT
    DISTINCT code AS a_code
  FROM
    {{ref('naming_conventions')}} a
  WHERE
    a.code_type = 'audience'