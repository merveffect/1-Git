{{ config(materialized='view') }}

/*
    The valid title groups, which is not the same list as the anchor seed.

    A group is real if it has anchors OR patterns. Since librarian became
    pattern-defined it has zero anchors, so a relationships test pointed at
    title_group_anchors would reject an ACCEPT override naming it - exactly
    the case we invited by saying archivists could be added by override.
    This exists so that test has something true to point at.
*/

select distinct title_group, 'ANCHORS'  as defined_by
from {{ ref('title_group_anchors') }}

union distinct

select distinct title_group, 'PATTERNS' as defined_by
from {{ ref('title_group_patterns') }}
