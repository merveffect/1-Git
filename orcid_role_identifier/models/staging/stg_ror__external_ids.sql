{{ config(materialized='view') }}

/*
    Flattens ROR external_ids.

    Schema: external_ids ARRAY<STRUCT<type STRING, all ARRAY<STRING>, preferred STRING>>

    WHY IT IS NEEDED:
    Only 35% of ORCID employment records carry a ROR identifier. Another
    44% carry an identifier from a different system:
        RINGGOLD  31.7%
        GRID       7.8%
        FUNDREF    4.0%
    ROR stores those identifiers inside external_ids, so we can reach the
    ROR record through them and avoid falling back to name matching.

    'all' is an ARRAY: one organisation can hold several Ringgold ids.
    Each is expanded into its own row.

    NOTE: 'all' is a RESERVED WORD in BigQuery, so the field access needs
    backticks. Without them the model fails with a syntax error.
*/

select
    r.ror_id,
    upper(x.type)               as id_type,       -- RINGGOLD / GRID / FUNDREF / ISNI ...
    trim(id_value)              as id_value,
    x.preferred                 as preferred_id
from {{ ref('stg_ror__organisations') }} r,
unnest(r.external_ids) x,
unnest(x.`all`) as id_value          -- ALL is a reserved word in BigQuery
where id_value is not null
  and trim(id_value) != ''
