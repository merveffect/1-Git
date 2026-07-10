-- Layer 1 (identity resolution) — port of the Colab `repeated_author_flag` step.
-- Flags, per submission, whether any of its authors was seen on an EARLIER
-- submission. Author identity is COALESCE(author_email, snid, author_id).
--
-- IMPORTANT (parity note / SN question): "first seen" is computed only within the
-- loaded window (see base CTE), exactly as the Colab does. So the flag detects
-- repetition WITHIN the processed window, not across full history. Changing this
-- to a full-history lookback would alter the numbers vs prod — deferred to SN.
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
    from base
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
