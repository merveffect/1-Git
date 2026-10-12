{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['snid', 'inferred_snt_id'],
        on_schema_change='append_new_columns',
        post_hook="delete from {{ this }} t where exists (select 1 from {{ this }} t2 where t2.snid = t.snid and t2.computed_at > ifnull(t.computed_at, timestamp('1970-01-01')))"
    )
}}

-- Top-10 favorite SNTs per user, ranked 1 (most favorite) to 10 (least).
--
-- Rolling refresh: each run takes the staleset users first — users with no
-- prediction yet (new), then the oldest computed_at — so predictions never
-- freeze as a user's reading behaviour changes. Batch size is tunable:
--   dbt run --select favorite_snt_predictions --vars '{"prediction_batch_size": 100000}'
--
-- The post_hook is required, not optional: merge on (snid, inferred_snt_id) updates
-- and inserts but never deletes, so an SNT that drops out of a refreshed
-- user's top-10 would linger as an orphan row. The hook removes any row
-- superseded by a newer computed_at for the same user, keeping exactly 10
-- rows per user. The ifnull guard matters during the column migration: rows
-- that predate computed_at carry NULL, and a bare `t2.computed_at > NULL`
-- evaluates to NULL, which would quietly leave those orphans behind.

with candidates as (

    select
        ue.snid,
        ue.embedding
        {% if is_incremental() %}
        , ap.last_computed_at
        {% endif %}
    from {{ ref('user_embedding') }} ue

    {% if is_incremental() %}
    left join (
        select snid, max(computed_at) as last_computed_at
        from {{ this }}
        group by snid
    ) ap
      on ue.snid = ap.snid
    order by ap.last_computed_at asc nulls first
    {% endif %}

    limit {{ var('prediction_batch_size', 250000) }}

),

batch as (
    select snid, embedding from candidates
),

vs_results as (

    select
        query.snid    as snid,
        base.snt_id   as inferred_snt_id,
        base.snt_name as inferred_snt_name,
        distance
    from vector_search(
        table {{ ref('snt_embeddings') }}, 'embedding',
        table batch, 'embedding',
        top_k => 10,
        distance_type => 'COSINE'
    )

)

select
    snid,
    inferred_snt_id,
    inferred_snt_name,
    distance,
    row_number() over (partition by snid order by distance asc) as favorite_rank,
    current_timestamp() as computed_at
from vs_results
