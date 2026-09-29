{{ config(materialized='table', cluster_by=['snid']) }}

/*
    WIDE VIEW - one row per person.
    For BI tools and quick filtering. The columns are generated from the
    role registry, so a new role automatically becomes a new column.

        WHERE is_hcp AND is_researcher   -> clinical academics
        WHERE is_librarian               -> library audience
*/

select
    snid,
    any_value(country_code)  as country_code,

    {{ role_flag_columns() }},

    array_agg(distinct role_key order by role_key)  as roles,
    count(distinct role_key)                        as role_count
from {{ ref('fct_researcher_roles') }}
group by snid
