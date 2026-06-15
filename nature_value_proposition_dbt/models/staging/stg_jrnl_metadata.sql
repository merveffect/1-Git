{{
config(
  materialized = 'table'
)
}}

SELECT
  `Product ID` AS journal_id,
  LOWER(TRIM(Title)) AS journal_title_clean,
  Title AS journal_title,
  `Launch Year` AS launch_year,
  `ISSN electronic` AS issn
FROM
    {{ source('journal_metadata', 'nature_title_list') }}
