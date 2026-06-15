SELECT * EXCEPT(country),
REGEXP_REPLACE(country, '&(.)', 'and ') AS country
FROM {{ ref('channel_grouping') }}

 