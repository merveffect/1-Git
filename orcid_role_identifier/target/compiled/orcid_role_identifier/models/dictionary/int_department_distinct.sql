

/*
    Distinct department names and how many records use each.

    The same economics as int_title_distinct: the department is embedded
    once per distinct value, not once per person.

    The length filter keeps unusable strings out of the model. Values that
    normalise to nothing come back as an empty vector, and one empty
    vector breaks an entire VECTOR_SEARCH run.
*/

select
    to_hex(md5(department))     as department_key,
    department,
    count(*)                    as frequency,
    sum(count(*)) over (order by count(*) desc)
        / sum(count(*)) over ()  as cumulative_coverage
from `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_staging`.`stg_role_records`
where department is not null
  and length(department) between 2 and 200
group by department
order by frequency desc