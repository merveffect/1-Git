
  
    

    create or replace table `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`journal_mapping`
      
    partition by date
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

with base as (

    select
        *,
        case
            when Journal_ID___GA4__Google_Analytics in ("(not set)", "ghostery", "false", "(not+set)", "(notset)") then "0"
            else Journal_ID___GA4__Google_Analytics
        end as JournalID
    from `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`b2c_googleanalytics_static`

    
  WHERE date BETWEEN DATE('2024-01-01')
                  AND DATE('2025-09-30')

),

b_sheet as (
    select
        * except(journal_title, main_discipline)
    from `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`journal_table`
),

c_jflow as (
    select distinct
        journal_id,
        journal_title,
        main_discipline
    from `snproject52c6e272`.`zz_content_hub`.`jflow_journals`
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
    );
  