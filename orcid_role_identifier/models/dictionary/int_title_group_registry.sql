{{ config(materialized='view') }}

/*
    The valid title groups, which is not the same list as the anchor seed.

    A group is real if it has anchors OR patterns. Since librarian became
    pattern-defined it has zero anchors, so a relationships test pointed at
    title_group_anchors would reject an ACCEPT override naming it - exactly
    the case we invited by saying archivists could be added by override.
    This exists so that test has something true to point at.

    ONE ROW PER GROUP, which needed collapsing on 2026-10-30. The union
    below was written when a group had anchors or patterns but never both,
    so one row per group fell out of it by accident. leadership is the
    first group to have both - thirteen anchors and ten patterns scoped to
    teaching_academic - and it arrived here twice, which failed the unique
    test on title_group. The failure was this model's, not the seed's: the
    registry is a list of valid groups and a group is not more valid for
    being defined two ways, so defined_by is aggregated rather than
    allowed to multiply the rows.
*/

with sources as (

    select distinct title_group, 'ANCHORS'  as defined_by
    from {{ ref('title_group_anchors') }}

    union distinct

    select distinct title_group, 'PATTERNS' as defined_by
    from {{ ref('title_group_patterns') }}

)

select
    title_group,
    string_agg(defined_by, ' + ' order by defined_by)   as defined_by
from sources
group by title_group
