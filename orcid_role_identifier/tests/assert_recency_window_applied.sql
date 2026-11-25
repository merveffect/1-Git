/*
    No record that ended longer ago than vars.recency_months may survive
    into scoring. Open-ended and undated records are exempt by design -
    an ongoing post is current, and a post with no dates has nothing in it
    to judge.

    This holds by construction: the window is a WHERE in the `records`
    CTE of int_employment_scored. The test exists because that position is
    load-bearing and easy to lose. recency_rank sorts on start_date before
    end_date, so the qualify at the bottom of that model does NOT keep the
    record that ended most recently; move this filter below the qualify
    and the model still compiles, still returns plausible numbers, and
    silently drops people who hold a qualifying post that ended last
    month. Nothing else in the project would notice.

    It also fails if end_date stops being carried out of staging, which is
    the other way the window becomes unverifiable while still appearing to
    work.

    Skipped rather than inverted when recency_months is null, so switching
    the rule off does not turn its test into a failure.
*/

{%- set months = var('recency_months', none) %}

{%- if months is none %}

/* rule disabled - nothing to assert */
select cast(null as string) as snid
where false

{%- else %}

select
    snid,
    role_key,
    evidence_title,
    end_date
from {{ ref('int_employment_scored') }}
where end_date is not null
  and end_date < date_sub(current_date(), interval {{ months }} month)

{%- endif %}
