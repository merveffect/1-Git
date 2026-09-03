{{ config(materialized='table') }}

-- Journal-based SNT signal per user: average embedding across every SNT
-- linked to a journal the user has a reading-relationship signal for.
-- No embedding cost — reuses snt_embeddings via the journal->SNT join.
--
-- Averaging strategy: group into one array-of-arrays per user first
-- (array_agg), then average per-offset inside a per-row correlated
-- subquery. A naive UNNEST(embedding) WITH OFFSET + GROUP BY (snid, off)
-- over the whole table blows up row count by 768x (embedding dim) before
-- the global shuffle — this keeps the explosion local to each user's own
-- (small) set of vectors instead.

with user_snt as (

    select
        uj.snid,
        se.embedding
    from {{ ref('users_and_journal_ids') }} uj
    join {{ ref('journal_snt_codes') }} jsc on uj.journal_id = jsc.journal_id
    join {{ ref('snt_embeddings') }} se on jsc.snt_id = se.snt_id

),

grouped as (

    -- BigQuery ARRAY_AGG can't aggregate an array-typed column directly
    -- (nested arrays aren't allowed) — wrap in a STRUCT
    select snid, array_agg(struct(embedding as embedding)) as items
    from user_snt
    group by snid

)

select
    snid,
    (
        
        select array_agg(avg_val order by off)
        from (
            select off, avg(val) as avg_val
            from unnest(items) as item, unnest(item.embedding) as val with offset off
            group by off
        )
    ) as embedding
from grouped
