{{ config(materialized='table') }}

-- Final per-user embedding: channel-level average of the journal-SNT vector
-- and the keyword vector (each channel counted once, regardless of how many
-- journals/keywords fed into it) — so a user with hundreds of keywords but
-- few journals doesn't have the keyword channel drown out the journal
-- signal. A user missing one channel just gets the other's vector.

with combined as (

    select snid, embedding from {{ ref('user_journal_snt_vector') }}
    union all
    select snid, embedding from {{ ref('user_keyword_vector') }}

),

exploded as (

    select snid, off, val
    from combined, unnest(embedding) as val with offset off

),

averaged as (

    select snid, off, avg(val) as avg_val
    from exploded
    group by snid, off

)

select
    snid,
    array_agg(avg_val order by off) as embedding
from averaged
group by snid
