
{{config(
  materialized = 'table'
)
}}

WITH base AS (
  SELECT
    t.id AS pub_id,
    t.journal.title AS journal_title,
    t.journal.id AS journal_id,
    for2.id as for2id,
    for2.name AS for2
  FROM
  {{source('publications', 'publications') }} t
  LEFT JOIN
    UNNEST(t.categories.for_2020_v2022.second_level.full) AS for2
  WHERE
    t.journal.title LIKE 'Nature%'                         -- Nature-branded journals
    AND t.publisher.name = 'Springer Nature'
    AND LOWER(t.type) = 'article'
    AND t.year > 2022
    AND t.journal.title NOT IN (                          -- excluded as per Saori
      'Nature India',
      'Nature Italy',
      'Nature Communications',
      'Nature Africa'
    )
),

ranked AS (
  SELECT
    journal_id,
    journal_title,
    for2id,
    for2,
    COUNT(DISTINCT pub_id) AS no_of_articles,
    ROW_NUMBER() OVER (
      PARTITION BY journal_id
      ORDER BY COUNT(DISTINCT pub_id) DESC
    ) AS rank_within_journal
  FROM
    base
  WHERE
    LENGTH(for2) > 0
  GROUP BY
   all
)

SELECT
  journal_id,
  journal_title,
  for2,
for2id,
  no_of_articles,
  rank_within_journal
FROM
  ranked
WHERE
  rank_within_journal <= 10
ORDER BY
  journal_title,
  rank_within_journal


