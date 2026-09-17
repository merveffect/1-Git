{{ config(materialized='table') }}

-- Final per-user embedding: channel-level average of the journal-SNT,
-- keyword, and collection-recommendation vectors (each channel counted
-- once, regardless of how many journals/keywords/collections fed into it)
-- — so a user with hundreds of keywords but few journals doesn't have the
-- keyword channel drown out the journal signal. A user missing one or two
-- channels just gets the average of whichever they have.
--
-- Averaging strategy: array_agg per user first (no row explosion), then
-- average per-offset inside a per-row correlated subquery — see
-- user_journal_snt_vector.sql for why this avoids a 768x-per-channel row
-- explosion + global shuffle, which matters more now with 3 channels
-- across ~2.1M+ users.

with combined as (

    select snid, embedding from {{ ref('user_journal_snt_vector') }}
    union all
    select snid, embedding from {{ ref('user_keyword_vector') }}
    union all
    select snid, embedding from {{ ref('user_collection_vector') }}

),

grouped as (

    -- BigQuery ARRAY_AGG can't aggregate an array-typed column directly
    -- (nested arrays aren't allowed) — wrap in a STRUCT
    select snid, array_agg(struct(embedding as embedding)) as items
    from combined
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
