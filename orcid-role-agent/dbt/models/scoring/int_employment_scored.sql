{{ config(materialized='table') }}

/*
    Kisi x rol bazinda role / org / dept alt skorlari.
    Phase-1'in genellestirilmis hali. Iki onemli fark:

      - role_score artik yuzlerce satirlik regex degil, dim_title_role
        sozlugunden geliyor (cok dilli, dereceli).
      - org_score artik kurum adinda kelime aramiyor; ROR canonical
        kurum TIPINDEN geliyor. "St. Mary's Hosp." gibi regex'in
        kacirdigi varyantlar artik yakalaniyor.

    org/dept skorlari ROLE BAGLI: hastane HCP icin 1.0, kutuphaneci icin
    dusuk; universite kutuphaneci icin 1.0, HCP icin kosullu.
*/

with employment as (

    select * from {{ ref('stg_orcid__employment') }}
    where role_title is not null

),

-- 1) kurumu ROR uzerinden canonical tipe cevir
--    ORCID zaten ROR kimligi tasiyorsa dogrudan; yoksa isim eslestirme
with_org as (

    select
        e.*,
        o.ror_id,
        o.canonical_name        as org_canonical_name,
        o.ror_types,
        o.resolution_method     as org_resolution_method
    from employment e
    left join {{ ref('int_org_resolved') }} o
           on e.organisation = o.organisation
          and e.disambiguated_org_id is not distinct from o.disambiguated_org_id

),

-- 2) unvani sozluk uzerinden rollere bagla (multi-label: 1 -> N satir)
with_roles as (

    select
        o.*,
        t.role_key,
        t.role_score
    from with_org o
    join {{ ref('dim_title_role') }} t
      on to_hex(md5(o.role_title)) = t.title_key
    where t.is_role_member

),

/*
    3) org skoru: (rol, kurum tipi) ciftinden.

    ROR 'types' bir DIZI - universite hastanesi hem Education hem
    Healthcare olabilir. Rol icin EN YUKSEK skoru veren tipi aliyoruz:
    tip cakismasi bilgi kaybi degil, avantaj.
*/
with_org_score as (

    select
        w.*,
        coalesce((
            select max(s.org_score)
            from unnest(coalesce(w.ror_types, ['UNKNOWN'])) as t
            join {{ ref('org_type_scores') }} s
              on s.role_key = w.role_key
             and s.org_type = t
        ), (
            -- ROR eslesmesi yok: UNKNOWN satirindan dusuk skor
            select s.org_score from {{ ref('org_type_scores') }} s
            where s.role_key = w.role_key and s.org_type = 'UNKNOWN'
        ), 0.0)                             as org_score,
        coalesce(w.ror_types[safe_offset(0)], 'UNKNOWN')  as org_type
    from with_roles w

),

-- 4) dept skoru: (rol, departman deseni) ciftinden, en yuksegi alinir
with_dept_score as (

    select
        w.snid,
        w.role_key,
        w.role_score,
        w.org_score,
        max(coalesce(d.dept_score, 0.0))    as dept_score,
        any_value(w.role_title_raw)         as evidence_title,
        any_value(w.organisation_raw)       as evidence_org,
        any_value(w.department_raw)         as evidence_dept,
        any_value(w.org_canonical_name)     as evidence_org_canonical,
        any_value(w.org_type)               as org_type,
        any_value(w.ror_id)                 as ror_id,
        any_value(w.org_resolution_method)  as org_resolution_method,
        any_value(w.country_code)           as country_code,
        max(w.is_current)                   as is_current,
        min(w.recency_rank)                 as recency_rank
    from with_org_score w
    left join {{ ref('dept_signals') }} d
           on w.role_key = d.role_key
          and regexp_contains(coalesce(w.department, ''), d.dept_pattern)
    group by w.snid, w.role_key, w.role_score, w.org_score

)

/*
    Kisi + rol basina TEK kayit: once guncel gorev, sonra en yuksek skor.
    (Phase-1'deki "most recent employment record, preferring current" kurali)
*/
select * from with_dept_score
qualify row_number() over (
    partition by snid, role_key
    order by is_current desc, role_score desc, recency_rank asc
) = 1
