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

    MEASURED 2026-11-27 AND THE CLAIM ABOVE IS WRONG. The id_type column of
    this model holds GRID 103,687 rows, WIKIDATA 64,427, ISNI 60,912 and
    FUNDREF 29,988. THERE IS NOT ONE RINGGOLD ROW. ROR's open data does not
    publish Ringgold identifiers, so they cannot be reached this way and the
    sentence above has never been true.

    WHAT THAT COSTS. int_org_resolved joins this model on
    id_type = org_id_source, so every ORCID record whose employer is
    identified by a Ringgold id misses route 2 entirely and falls through to
    NAME_EXACT or to no resolution at all. Ringgold is the LARGEST identifier
    group in the source at 31.7%, so the bridge delivers GRID 7.8% plus
    FUNDREF 4.0% - about 11.8%, not the 43.5% the comment promised. An
    unresolved employer has no ROR type, which moves org_score, which is a
    weighted component of every composite score.

    NOT FIXED HERE, BECAUSE IT MAY NOT BE FIXABLE IN CODE. If ROR genuinely
    does not publish Ringgold ids then this is a SOURCING problem - it needs
    another mapping, not another join. The numbers are recorded here so the
    next person does not re-derive them, and so nobody reads 43.5% and
    believes it.

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
