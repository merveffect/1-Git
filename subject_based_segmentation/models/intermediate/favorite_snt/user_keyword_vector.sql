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

with weighted as (

    select
        uk.snid,
        ke.embedding,
        greatest(1 - kc.distance, 0.05) as weight
    from {{ ref('users_and_keywords') }} uk
    join {{ ref('keyword_embeddings') }} ke on uk.keyword_id = ke.keyword_id
    join {{ ref('keyword_snt_confidence') }} kc on uk.keyword_id = kc.keyword_id

),

exploded as (

    select snid, off, val * weight as weighted_val, weight
    from weighted, unnest(embedding) as val with offset off

),

averaged as (

    select snid, off, sum(weighted_val) / sum(weight) as avg_val
    from exploded
    group by snid, off

)

select
    snid,
    array_agg(avg_val order by off) as embedding
from averaged
group by snid
