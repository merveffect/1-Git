SELECT
    DISTINCT code AS p_code
  FROM
    {{ref('naming_conventions')}} p
  WHERE
    p.code_type = 'product'