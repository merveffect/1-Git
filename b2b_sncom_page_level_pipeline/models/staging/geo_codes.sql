SELECT
    DISTINCT code AS ge_code,
    CURRENT_DATE() AS event_date,
    version
  FROM
    {{ref('naming_conventions')}} g
  WHERE
    g.code_type = 'geography'