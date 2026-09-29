{{ config(materialized='table') }}

/*
    HUMAN REVIEW QUEUE - the highest-leverage step in the project.

    Ambiguous titles ordered by FREQUENCY. Job title distributions are
    heavily skewed, so the top few hundred titles cover a large share of
    all people. Roughly two hours of reading buys accuracy across tens of
    thousands of records.

    This matters more than usual right now: the LLM judge is disabled
    (no Vertex connection), so this queue is the only verification
    mechanism in the pipeline.

    After deciding, add rows to seeds/role_title_overrides.csv and run
    dbt seed && dbt run -s dim_title_role+
*/

select
    title,
    role_key,
    frequency,
    round(include_similarity, 3)    as similarity,
    round(distractor_margin, 3)     as distractor_margin,
    round(distractor_similarity, 3) as distractor_similarity,
    matched_anchors,
    decision_source,
    is_role_member                  as current_decision,
    round(
        sum(frequency) over (order by frequency desc)
        / sum(frequency) over (), 4
    )                               as cumulative_coverage
from {{ ref('dim_title_role') }}
where needs_human_review
   or decision_source = 'LLM_JUDGE'
order by frequency desc
