{{ config(materialized='table') }}

/*
    HUMAN REVIEW QUEUE — the highest-leverage step in the project.

    Ambiguous values from BOTH axes, ordered by frequency. Job title and
    department distributions are heavily skewed, so the top few hundred
    entries cover a large share of all people: roughly two hours of
    reading buys accuracy across tens of thousands of records.

    This matters more than usual because the LLM adjudication step has no
    Vertex connection, making this queue the only verification mechanism
    in the pipeline.

    After deciding, add rows to seeds/role_title_overrides.csv and run
    dbt seed && dbt run -s dim_title_group+
*/

select
    'title'                         as axis,
    title                           as value,
    title_group                     as assigned_group,
    runner_up,
    frequency,
    round(similarity, 3)            as similarity,
    round(margin, 3)                as margin,
    matched_anchors,
    is_assigned
from {{ ref('dim_title_group') }}
where needs_human_review

union all

select
    'discipline',
    department,
    discipline,
    runner_up,
    frequency,
    round(similarity, 3),
    round(margin, 3),
    matched_anchors,
    is_assigned
from {{ ref('dim_department_discipline') }}
where needs_human_review

order by frequency desc
