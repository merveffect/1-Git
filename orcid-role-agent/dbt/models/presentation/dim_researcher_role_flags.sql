{{ config(materialized='table', cluster_by=['snid']) }}

/*
    GENIS (WIDE) GORUNUM - kisi basina tek satir.
    BI araclari ve hizli filtreleme icin. Kolonlar rol kayit defterinden
    Jinja ile uretilir; yeni rol eklenince otomatik yeni kolon gelir.

        WHERE is_hcp AND is_researcher   -> akademisyen hekimler
        WHERE is_librarian               -> kutuphane audience'i
*/

select
    snid,
    any_value(country_code)  as country_code,

    {{ role_flag_columns() }},

    array_agg(distinct role_key order by role_key)  as roles,
    count(distinct role_key)                        as role_count
from {{ ref('fct_researcher_roles') }}
group by snid
