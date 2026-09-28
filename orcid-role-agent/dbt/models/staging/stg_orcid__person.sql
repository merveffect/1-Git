{{ config(materialized='view') }}

/*
    Kisi seviyesi alanlar. Bir satir = bir kisi.

    EMAIL NOTU: emails[] repeated ve her birinin kendi visibility'si var.
    ORCID'de email'ler cogunlukla PRIVATE. Braze contract'indaki
    contact_email buradan degil, CDP'den gelmeli - bu kolon sadece
    kapsama olcmek icin.
*/

with researchers as (

    select
        snid,
        orcid_id,
        created_at,
        last_updated_at,
        name,
        biography,
        emails,
        country_codes,
        keywords
    from {{ source('researcher_profiles', 'orcid_researchers') }}
    where snid is not null

)

select
    snid,
    orcid_id,
    created_at,
    last_updated_at,

    name.published_name                             as published_name,
    name.given_names                                as given_names,
    name.family_name                                as family_name,

    -- profil ulkesi (ordering = 1 birincil)
    (select c.value from unnest(country_codes) c
      where upper(c.visibility) = 'PUBLIC'
      order by c.ordering limit 1)                  as profile_country_code,

    -- ORCID'deki public email - kapsama olcumu icin, contract icin DEGIL
    (select e.value from unnest(emails) e
      where upper(e.visibility) = 'PUBLIC' and e.is_primary
      limit 1)                                      as orcid_public_email,

    (select count(*) from unnest(emails) e
      where upper(e.visibility) = 'PUBLIC')         as public_email_count,

    -- kisinin kendi beyan ettigi anahtar kelimeler: ek rol sinyali
    array(
        select {{ normalize_title('k.value') }}
        from unnest(keywords) k
        where upper(k.visibility) = 'PUBLIC'
          and k.value is not null
    )                                               as keywords,

    biography.value                                 as biography

from researchers
