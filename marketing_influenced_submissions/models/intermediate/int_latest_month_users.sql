-- Phase 5 combination: distinct GA users on this month's submissions (Colab
-- mis_2_latest_month_users_1). Feeds the genuine-researcher behaviour filter.

{{ config(materialized='table', tags=['ga']) }}

select distinct
    user_pseudo_id
from {{ ref('int_sub_details') }}
where submission_date_min >= date('{{ var("mis_start_date") }}')
  and submission_date_min <= date('{{ var("mis_end_date") }}')
  and user_pseudo_id is not null
