{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['snid', 'snt_id'],
        on_schema_change='fail'
    )
}}

-- Top-5 favorite SNTs per user: nearest SNTs to their reading-behaviour
-- embedding (see user_embedding). This is a real SNT-level prediction —
-- NOT rolled up to MPC subjects (that happens downstream, only for
-- evaluation against the MPC-level ground truth we actually have).
--
-- Incremental, capped at 5k users per run — user_embedding has ~2.1M rows
-- and VECTOR_SEARCH scales with query_rows x base_rows, so a single
-- uncapped run is very slow. Re-running dbt run --select
-- favorite_snt_predictions repeatedly (or on a schedule) just keeps
-- picking up the next batch of users until fully caught up. unique_key is
-- (snid, snt_id) — NOT snid alone — since each user produces 5 rows
-- (top-5 SNTs); a non-unique unique_key would make dbt dedupe the merge
-- source down to 1 row per snid, silently dropping 4 of every user's 5
-- predictions.

with new_candidates as (

    select
        ue.snid,
        ue.embedding
    from {{ ref('user_embedding') }} ue

    {% if is_incremental() %}
    where not exists (
        select 1
        from {{ this }} m
        where m.snid = ue.snid
    )
    {% endif %}

    limit 5000

),

vs_results as (

    select
        query.snid      as snid,
        base.snt_id      as snt_id,
        base.snt_name    as snt_name,
        distance
    from vector_search(
        table {{ ref('snt_embeddings') }}, 'embedding',
        table new_candidates, 'embedding',
        top_k => 5,
        distance_type => 'COSINE'
    )

)

select
    snid,
    snt_id,
    snt_name,
    distance
from vs_results
