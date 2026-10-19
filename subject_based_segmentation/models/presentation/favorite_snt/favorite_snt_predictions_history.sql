{{
    config(
        materialized='incremental',
        on_schema_change='append_new_columns',
        partition_by={
            'field': 'updated_at',
            'data_type': 'timestamp',
            'granularity': 'day'
        },
        post_hook="delete from {{ this }} t where exists (select 1 from {{ source('prod_mpc_dbt_presentation', 'snid_deletions') }} d where d.snid = t.snid)"
    )
}}

-- Change log of favourite-SNT predictions: one row per user per change.
-- A user only appears when they are genuinely new, or when their top-10
-- actually changed — a refresh that produces the same 10 SNTs in the same
-- order writes nothing.
--
-- Change is detected by fingerprinting the ordered inferred_snt_id sequence,
-- so a reordering of the same 10 SNTs also counts as a change.
--
-- Append-only (no unique_key): every row is an event, kept for history.
-- Never --full-refresh this model. Every other table in the project can be
-- rebuilt from source; the change history cannot.
--
-- The post_hook is the one exception to append-only. top_10_snt_names is a
-- record of what a user read, so a deletion request has to reach this table
-- too — otherwise we would be clearing a user's predictions and embedding
-- while keeping a history of their interests.

with current_state as (

    select
        snid,
        string_agg(inferred_snt_id, ',' order by favorite_rank) as inferred_snt_id_sequence,
        string_agg(inferred_snt_name, ' > ' order by favorite_rank) as top_10_snt_names,
        max(computed_at) as computed_at
    from {{ ref('favorite_snt_predictions') }}
    group by snid

),

fingerprinted as (

    select
        snid,
        top_10_snt_names,
        to_hex(md5(inferred_snt_id_sequence)) as fingerprint,
        computed_at
    from current_state

)

{% if is_incremental() %}

, last_recorded as (

    select snid, fingerprint, first_seen_at
    from {{ this }}
    qualify row_number() over (partition by snid order by updated_at desc) = 1

)

select
    f.snid,
    case when lr.snid is null then 'new' else 'changed' end as change_type,
    f.top_10_snt_names,
    f.fingerprint,
    coalesce(lr.first_seen_at, f.computed_at) as first_seen_at,
    f.computed_at as updated_at
from fingerprinted f
left join last_recorded lr
  on f.snid = lr.snid
where lr.snid is null
   or lr.fingerprint != f.fingerprint

{% else %}

select
    snid,
    'new' as change_type,
    top_10_snt_names,
    fingerprint,
    computed_at as first_seen_at,
    computed_at as updated_at
from fingerprinted

{% endif %}
