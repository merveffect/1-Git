SELECT
    DISTINCT code AS g_code
  FROM
    {{ref('naming_conventions')}} g
  WHERE
    g.code_type = 'goal'