{{ config(
    materialized = "incremental",
    partition_by = {"field": "date"}
)}}

with base as (

    select
        *,
        case
            when Journal_ID___GA4__Google_Analytics in ("(not set)", "ghostery", "false", "(not+set)", "(notset)") then "0"
            else Journal_ID___GA4__Google_Analytics
        end as JournalID
    from {{ ref('b2c_googleanalytics_static') }}

    {% if is_incremental() %}
  WHERE date BETWEEN 
        COALESCE(
          DATE('{{ var("backfill_start_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
        AND
        COALESCE(
          DATE('{{ var("backfill_end_date", "") }}') ,
          DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
        )
{% else %}
  WHERE date BETWEEN DATE('{{ var("start_date", "2024-01-01") }}')
                  AND DATE('{{ var("end_date", "2025-12-31") }}')
{% endif %}
),

b_sheet as (
    select
        * except(journal_title, main_discipline)
    from {{source('dbt_dev_ga4_ria_researcher_report', 'journal_table') }}
),

c_jflow as (
    select distinct
        journal_id,
        journal_title,
        main_discipline
    from {{ source('zz_content_hub','jflow_journals') }}
)

select
    a.* except(JournalID),
    c.journal_title,
    b.business_model,
    b.main_group,
    b.portfolio,
    c.main_discipline,
    coalesce(safe_cast(a.JournalID as int64), b.journal_id) as journal_id
from base a
full join b_sheet b
    on safe_cast(a.JournalID as int64) = b.journal_id
left join c_jflow c
    on coalesce(safe_cast(a.JournalID as int64), b.journal_id) = c.journal_id
