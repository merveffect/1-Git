-- Layer 1 (identity resolution) — port of the Colab `repeated_author_flag` step.
-- Flags, per submission, whether any of its authors was seen on an EARLIER
-- submission. Author identity is COALESCE(author_email, snid, author_id).
--
-- Business rule (Giorgia 2026-07-16):
--   repeated_author = 0 if ALL authors on a submission are brand new
--   repeated_author = 1 if at least one author has previously submitted
-- The "previously submitted" lookback should span FULL history up to the submission
-- date, controlled by the repeated_author_full_history var:
--   true  -> earliest submission per author across ALL submissions (<= mis_end_date)
--   false -> repetition within the processed window only (original Colab INSERT INTO)
-- A submission can re-enter with the same id and multiple submission_dates; the final
-- group-by collapses that to a single flag per (submission, source_system).
--
-- Incremental: monthly partitions on `month`. insert_overwrite replaces the month
-- partitions produced by the current window.

{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'month',
            'data_type': 'date',
            'granularity': 'month',
        },
        on_schema_change='sync_all_columns',
    )
}}

with base as (

    select
        s.internal_submission_id,
        s.source_system,
        s.submission_date,
        date_trunc(s.submission_date, month) as month,
        coalesce(a.author_email, a.snid, a.author_id) as author_identifier
    from {{ ref('stg_submissions') }} s
    left join {{ ref('stg_authors') }} a
        on s.submission_id = a.submission_id
    where s.submission_date >= date('{{ var("mis_start_date") }}')
      and s.submission_date <= date('{{ var("mis_end_date") }}')

),

author_first_seen as (

    select
        author_identifier,
        min(submission_date) as first_seen_date
    from (
        {% if var('repeated_author_full_history') %}
        -- Full history: earliest submission per author across ALL submissions up to the
        -- end of the processing window (as-of, so re-runs stay idempotent).
        select
            s.submission_date,
            coalesce(a.author_email, a.snid, a.author_id) as author_identifier
        from {{ ref('stg_submissions') }} s
        left join {{ ref('stg_authors') }} a
            on s.submission_id = a.submission_id
        where s.submission_date <= date('{{ var("mis_end_date") }}')
        {% else %}
        -- Window only (original Colab behaviour).
        select submission_date, author_identifier from base
        {% endif %}
    )
    group by author_identifier

),

enriched as (

    select
        b.internal_submission_id,
        b.source_system,
        b.submission_date,
        b.month,
        b.author_identifier,
        af.first_seen_date
    from base b
    left join author_first_seen af
        on b.author_identifier = af.author_identifier

)

select
    internal_submission_id,
    source_system,
    any_value(month) as month,
    max(if(first_seen_date < submission_date, 1, 0)) as repeated_author
from enriched
group by 1, 2
