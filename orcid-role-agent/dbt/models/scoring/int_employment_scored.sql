{{ config(materialized='table') }}

/*
    Kisi x rol x KAYNAK bazinda role / org / dept alt skorlari.

    Kaynak boyutu neden var:
    Ayni kisi hakkinda ORCID "Professor of Cardiology", web scraping
    "Dean of Medicine" diyebilir. Ikisi farkli rollere isaret ediyorsa
    IKISI DE tutulur (kisi gercekten ikisi birden). Ayni role isaret
    ediyorlarsa sunum katmaninda birlestirilir ve kaynaklar
    'Orcid + Web scraping' olarak yazilir.

    Kaynak tasimadigi alanlar NULL gelir; agirliklar o kaynak icin
    yeniden normalize edilir (macros/scoring.sql -> normalized_weights).
*/

with records as (

    select * from {{ ref('stg_role_records') }}

),

-- 1) kurumu ROR uzerinden tanimla (ORCID'in ROR kimligi varsa dogrudan)
with_org as (

    select
        r.*,
        o.ror_id,
        o.canonical_name        as org_canonical_name,
        o.ror_types,
        o.resolution_method     as org_resolution_method
    from records r
    left join {{ ref('int_org_resolved') }} o
           on r.organisation = o.organisation
          and r.org_id is not distinct from o.org_id

),

-- 2) unvani sozluk uzerinden rollere bagla (multi-label: 1 -> N satir)
with_roles as (

    select
        w.*,
        t.role_key,
        t.role_score
    from with_org w
    join {{ ref('dim_title_role') }} t
      on w.title_key = t.title_key
    where t.is_role_member

),

/*
    3) org skoru: (rol, kurum tipi) ciftinden.
       ROR 'types' bir DIZI - universite hastanesi hem Education hem
       Healthcare. Rol icin EN YUKSEK skoru veren tipi aliyoruz.
*/
with_org_score as (

    select
        w.*,
        case
            when w.organisation is null then null      -- kaynak kurum tasimiyor
            else coalesce((
                select max(s.org_score)
                from unnest(coalesce(w.ror_types, ['UNKNOWN'])) as t
                join {{ ref('org_type_scores') }} s
                  on s.role_key = w.role_key and s.org_type = t
            ), (
                select s.org_score from {{ ref('org_type_scores') }} s
                where s.role_key = w.role_key and s.org_type = 'UNKNOWN'
            ), 0.0)
        end                                             as org_score,
        coalesce(w.ror_types[safe_offset(0)], 'UNKNOWN') as org_type
    from with_roles w

),

-- 4) dept skoru: (rol, departman deseni), en yuksegi kazanir
with_dept_score as (

    select
        w.snid,
        w.source_key,
        w.role_key,
        w.role_score,
        w.org_score,
        case when max(w.department) is null then null
             else max(coalesce(d.dept_score, 0.0)) end  as dept_score,
        any_value(w.role_title_raw)         as evidence_title,
        any_value(w.organisation_raw)       as evidence_org,
        any_value(w.department_raw)         as evidence_dept,
        any_value(w.org_canonical_name)     as evidence_org_canonical,
        any_value(w.org_type)               as org_type,
        any_value(w.ror_id)                 as ror_id,
        any_value(w.org_resolution_method)  as org_resolution_method,
        any_value(w.country_code)           as country_code,
        max(w.is_current)                   as is_current,
        min(w.recency_rank)                 as recency_rank,
        max(w.source_last_updated)          as source_last_updated
    from with_org_score w
    left join {{ ref('dept_signals') }} d
           on w.role_key = d.role_key
          and regexp_contains(coalesce(w.department, ''), d.dept_pattern)
    group by w.snid, w.source_key, w.role_key, w.role_score, w.org_score

)

/*
    Kisi + rol + kaynak basina TEK kayit: once guncel gorev, sonra
    en yuksek skor. (Phase-1'deki "most recent, preferring current")
*/
select * from with_dept_score
qualify row_number() over (
    partition by snid, source_key, role_key
    order by is_current desc, role_score desc, recency_rank asc
) = 1
