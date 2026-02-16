SELECT
    DISTINCT code AS p_code,
    CURRENT_DATE() AS event_date,
    version
  FROM
    {{ref('naming_conventions')}} p
  WHERE
    p.code_type = 'product'