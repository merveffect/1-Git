{{ config(materialized='table') }}

-- Keyword-based signal per user: confidence-weighted average embedding
-- across the user's own keywords. Confidence weight = 1 - nearest_snt
-- distance (floored at 0.05 so no keyword is ever fully zeroed out) —
-- ambiguous/niche keywords (spot-checked misses like "Mpro", "Ciona",
-- distance > ~0.33) count less than confident matches like "Alport
-- Syndrome" (distance ~0.007) instead of contributing equally.
--
-- Only keywords that already have a keyword_snt_confidence row are used —
-- this table backfills incrementally, so coverage grows over time as that
-- backfill completes.
--
-- Averaging strategy: group into one array of (embedding, weight) structs
-- per user first (array_agg), then compute the weighted average per-offset
-- inside a per-row correlated subquery — see user_journal_snt_vector.sql
-- for why this avoids a 768x row explosion + global shuffle.

with weighted as (

    select
        uk.snid,
        ke.embedding,
        greatest(1 - kc.distance, 0.05) as weight
    from {{ ref('users_and_keywords') }} uk
    join {{ ref('keyword_embeddings') }} ke on uk.keyword_id = ke.keyword_id
    join {{ ref('keyword_snt_confidence') }} kc on uk.keyword_id = kc.keyword_id

),

grouped as (

    select snid, array_agg(struct(embedding, weight)) as items
    from weighted
    group by snid

)

select
    snid,
    (
        select array_agg(w_avg order by off)
        from (
            select off, sum(val * item.weight) / sum(item.weight) as w_avg
            from unnest(items) as item, unnest(item.embedding) as val with offset off
            group by off
        )
    ) as embedding
from grouped
