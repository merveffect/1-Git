SELECT * EXCEPT(country),
REPLACE(LOWER(country), '&', 'and') AS country
FROM {{ ref('channel_grouping') }}