SELECT
    DISTINCT code AS g_code,
    CURRENT_DATE() AS event_date,
    version
  FROM
    {{ref('naming_conventions')}} g
  WHERE
    g.code_type = 'goal'