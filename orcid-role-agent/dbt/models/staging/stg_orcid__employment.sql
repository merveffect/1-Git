{{ config(materialized='view') }}

/*
    employments[] dizisi duzlestirilir. Bir satir = bir kisi x bir is kaydi.

    ORCID GERCEKLERI:
      - role serbest metin, cok dilli, 355.803 farkli deger
      - full_end_date NULL ise gorev halen devam ediyor
      - ordering: ORCID profilindeki siralama (1 = en ustte)
      - disambiguated_organisation_id: ROR / GRID / RINGGOLD kimligi -
        kurum eslestirmesinin BEDAVA gelen kismi
      - visibility: PUBLIC / LIMITED / REGISTERED_ONLY / PRIVATE
        !! Pazarlama kullanimi icin PUBLIC disinda veri kullanilmamali
*/

with researchers as (

    select
        snid,
        orcid_id,
        last_updated_at,
        employments
    from {{ source('researcher_profiles', 'orcid_researchers') }}
    where snid is not null

),

flattened as (

    select
        r.snid,
        r.orcid_id,
        r.last_updated_at,

        e.visibility                                        as visibility,
        e.ordering                                          as ordering,

        -- ham metinler (kanit / izlenebilirlik)
        e.role                                              as role_title_raw,
        e.organisation_name                                 as organisation_raw,
        e.department_name                                   as department_raw,

        -- normalize (tum eslestirme bunlarin uzerinden)
        {{ normalize_title('e.role') }}                     as role_title,
        {{ normalize_title('e.organisation_name') }}        as organisation,
        {{ normalize_title('e.department_name') }}          as department,

        -- kurum kimligi: ORCID'in kendi disambiguation'i
        e.disambiguated_organisation_id                     as disambiguated_org_id,
        upper(e.disambiguated_organisation_source)          as disambiguated_org_source,

        -- kayit bazli ulke (profil ulkesinden daha dogru)
        e.organisation_address_country_code                 as country_code,
        e.organisation_address_city                         as city,
        e.organisation_address_region                       as region,

        -- tarihler
        e.full_start_date                                   as start_date,
        e.full_end_date                                     as end_date,
        e.full_end_date is null                             as is_current,

        -- kaynak: kisinin kendi beyani mi, kurum mu dogrulamis?
        e.source.source_name                                as assertion_source_name,
        e.source.source_orcid_id                            as assertion_source_orcid_id,
        e.source.source_orcid_id = r.orcid_id               as is_self_asserted

    from researchers r,
    unnest(r.employments) e

),

ranked as (

    select
        *,
        -- en guncel kayit: once devam edenler, sonra en yeni, sonra profil sirasi
        row_number() over (
            partition by snid
            order by is_current desc,
                     start_date desc nulls last,
                     end_date   desc nulls last,
                     ordering   asc  nulls last
        ) as recency_rank
    from flattened

)

select * from ranked
where role_title is not null
  {% if var('public_visibility_only', true) %}
  and upper(visibility) = 'PUBLIC'
  {% endif %}
