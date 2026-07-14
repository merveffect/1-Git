-- Phase 2 submissions: GA-observed SNAPP submissions (Colab mis_1_subs_clientids_1).
-- Maps successful SNAPP submissions to the GA user_pseudo_id from the funnel, for the
-- processing window. Incremental insert_overwrite on the submission month.

{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={'field': 'ga_submission_date', 'data_type': 'date', 'granularity': 'month'},
        on_schema_change='sync_all_columns',
    )
}}

select
    submission_id as ga_submission_id,
    user_pseudo_id,
    journal_id as ga_journal_id,
    journal_title as ga_journal_title,
    min(full_date) as ga_submission_date
from {{ ref('stg_snapp_submission_funnel') }}
where snapp_process = 'snapp_success'
  and full_date >= date('{{ var("mis_start_date") }}')
  and full_date <= date('{{ var("mis_end_date") }}')
  and submission_id is not null
  and user_pseudo_id is not null
group by 1, 2, 3, 4
