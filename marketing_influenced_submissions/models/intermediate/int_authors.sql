-- Layer 1 (identity resolution) — port of the Colab `mis_1_authors` step.
-- One row per submission x author (all author roles kept), enriched with journal
-- imprint and portfolio metadata. SNAPP + EM only, matching the Colab.
--
-- Incremental: monthly partitions on submission_date. insert_overwrite means a
-- re-run for a given window replaces exactly the months it produces, so back-
-- filling or re-processing a month is idempotent. Scope is driven by the
-- mis_start_date / mis_end_date vars (see dbt_project.yml).

{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'submission_date',
            'data_type': 'date',
            'granularity': 'month',
        },
        on_schema_change='sync_all_columns',
    )
}}

with submissions as (

    select
        submission_id,
        internal_submission_id,
        source_system,
        is_in_collection,
        submission_date,
        journal_id
    from {{ ref('stg_submissions') }}
    where source_system in ('SNAPP', 'EM')
      and submission_date >= date('{{ var("mis_start_date") }}')
      and submission_date <= date('{{ var("mis_end_date") }}')

),

journals as (

    select
        journal_id,
        imprint_code
    from {{ ref('stg_journals') }}

),

authors as (

    select
        submission_id,
        author_email,
        is_submitter,
        is_coauthor,
        is_corresponding_author
    from {{ ref('stg_authors') }}

),

portfolio as (

    select
        journal_id,
        business_model,
        main_group,
        portfolio
    from {{ ref('stg_journal_portfolio') }}

)

select
    s.submission_id,
    s.internal_submission_id,
    s.source_system,
    s.is_in_collection,
    s.submission_date,
    s.journal_id,
    j.imprint_code,
    a.author_email,
    a.is_submitter,
    a.is_coauthor,
    a.is_corresponding_author,
    p.business_model,
    p.main_group,
    p.portfolio
from submissions s
left join journals j
    on s.journal_id = j.journal_id
left join authors a
    on s.submission_id = a.submission_id
left join portfolio p
    on s.journal_id = p.journal_id
