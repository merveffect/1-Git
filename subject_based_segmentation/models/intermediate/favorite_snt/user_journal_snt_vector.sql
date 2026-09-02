{{ config(materialized='table') }}

-- Journal-based SNT signal per user: average embedding across every SNT
-- linked to a journal the user has a reading-relationship signal for.
-- No embedding cost — reuses snt_embeddings via the journal->SNT join.

with user_snt as (

    select
        uj.snid,
        se.embedding
    from {{ ref('users_and_journal_ids') }} uj
    join {{ ref('journal_snt_codes') }} jsc on uj.journal_id = jsc.journal_id
    join {{ ref('snt_embeddings') }} se on jsc.snt_id = se.snt_id

),

exploded as (

    select snid, off, val
    from user_snt, unnest(embedding) as val with offset off

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
