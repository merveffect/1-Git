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
    group in the source: 482,455 records, of which 219,925 - 153,611 people -
    resolve to nothing. An unresolved employer has no ROR type, which moves
    org_score, which is a weighted component of every composite score.

    MEASURING IT TURNED UP A SECOND, SEPARATE BUG THAT WAS FIXABLE. FUNDREF
    rows exist here - 29,988 of them - and yet not one FundRef record ever
    bridged either, because ORCID writes the id as the DOI that contains it
    and ROR stores it bare. int_org_resolved now takes the last path segment
    on the ORCID side, which recovered 64,514 of 65,195 records, 99.0% -
    verified after the build at exactly that, and three quarters of them
    resolve to ROR type education rather than funder, because universities
    fund research and so sit in the FundRef registry too. The Ringgold half
    has no such fix: there is nothing on the other side of the join to reach.

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
