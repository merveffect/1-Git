{{ config(materialized='table', cluster_by=['role_key']) }}

/*
    AUDIENCE CIKTISI - agent'in ve pazarlama ekibinin okudugu tablo.

    Consent bayraklari BURADA birlestirilir. Phase-1 analizinde gorulmustu:
    tespit edilen HCP'lerin sadece %22'si marketing, %13'u advertising
    izinli. Yani "kac kisi bulduk" degil, "kacina ULASABILIRIZ" onemli.
*/

with roles as (

    select * from {{ ref('fct_researcher_roles') }}

),

cdp as (

    select
        snid,
        mkt_pref_opt_in,
        advertising_opt_in,
        true as in_cdp
    from {{ source('cdp', 'audience_builder_big') }}

)

select
    r.snid,
    r.role_key,
    r.role_bucket,
    r.role_label,
    r.role_final_score,
    r.country_code,
    r.is_current,
    r.derived_from_role,

    -- kanit zinciri: bu kisi listeye NEDEN girdi
    r.evidence_title,
    r.evidence_org,
    r.evidence_dept,

    -- ulasilabilirlik
    coalesce(c.in_cdp, false)               as in_cdp,
    coalesce(c.mkt_pref_opt_in, false)      as is_marketable,
    coalesce(c.advertising_opt_in, false)   as is_advertisable,

    r.scored_date
from roles r
left join cdp c using (snid)
