{{ config(materialized='table') }}

-- Top-5 favorite SNTs per user: nearest SNTs to their reading-behaviour
-- embedding (see user_embedding). This is a real SNT-level prediction —
-- NOT rolled up to MPC subjects (that happens downstream, only for
-- evaluation against the MPC-level ground truth we actually have).

select
    query.snid as snid,
    base.snt_id as snt_id,
    base.snt_name as snt_name,
    distance
from vector_search(
    table {{ ref('snt_embeddings') }}, 'embedding',
    table {{ ref('user_embedding') }}, 'embedding',
    top_k => 5,
    distance_type => 'COSINE'
)
