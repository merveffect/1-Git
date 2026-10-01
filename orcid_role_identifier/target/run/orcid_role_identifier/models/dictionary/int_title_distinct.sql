
  
    

    create or replace table `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_dictionary`.`int_title_distinct`
      
    
    

    
    OPTIONS(
      description="""Distinct titles and frequencies. All expensive work runs on this."""
    )
    as (
      

/*
    DICTIONARY STEP 1
    Distinct job titles and how many records use each one.

    Every expensive operation (embedding, LLM) runs on THIS table, not
    on the person-level table. That is where the cost saving comes from.

    The frequency column matters: the human review queue is ordered by
    it. Job title distributions are heavily skewed, so reviewing the top
    few hundred titles covers a large share of all people.
*/

with records as (

    select role_title, organisation, department
    from `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_staging`.`stg_role_records`
    where role_title is not null

),

agg as (

    select
        role_title                                  as title,
        count(*)                                    as frequency,
        count(distinct organisation)                as distinct_orgs,
        approx_top_count(organisation, 3)           as top_organisations,
        approx_top_count(department, 3)             as top_departments
    from records
    group by title

)

select
    to_hex(md5(title))  as title_key,
    title,
    frequency,
    distinct_orgs,
    top_organisations,
    top_departments,
    sum(frequency) over ()                                            as corpus_size,
    sum(frequency) over (order by frequency desc)
        / sum(frequency) over ()                                      as cumulative_coverage
from agg
order by frequency desc
    );
  