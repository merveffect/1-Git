SELECT
    DISTINCT code AS ge_code
  FROM
    {{ref('naming_conventions')}} g
  WHERE
    g.code_type = 'geography'