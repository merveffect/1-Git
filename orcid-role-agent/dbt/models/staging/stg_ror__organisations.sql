{{ config(materialized='view') }}

/*
    ROR kurum kayit defteri (AYRI PROJE: ri-data-engineering-dd4c0eca).

    Iki kullanim yolu var:
      1. DOGRUDAN - ORCID zaten disambiguated_organisation_id tasiyor.
         source = 'ROR' ise eslestirmeye HIC gerek yok, bedava.
      2. ISIM ESLESTIRME - ROR kimligi yoksa, kurum adindan.
         (Merve'nin daha once yaptigi is)

    !! KOLON ADLARI DOGRULANACAK - ROR semasi surume gore degisiyor.
       `bq show --schema ri-data-engineering-dd4c0eca:ror.ror_data_refresh`
       ciktisina gore duzeltilecek.
*/

with source as (

    select * from {{ source('ror', 'ror_data_refresh') }}

)

select
    id                                          as ror_id,
    name                                        as canonical_name,
    {{ normalize_title('name') }}               as organisation,     -- join anahtari

    /*
        ROR 'types' bir DIZI: Education, Healthcare, Company, Archive,
        Nonprofit, Government, Facility, Other.
        Bir kurum birden fazla tip tasiyabilir (orn. universite hastanesi
        hem Education hem Healthcare) - org_type_scores.csv'de en yuksek
        skoru alani seciyoruz, asagidaki primary_type sadece raporlama icin.
    */
    types                                       as ror_types,
    types[safe_offset(0)]                       as primary_type,

    country.country_code                        as ror_country_code,
    country.country_name                        as ror_country_name

from source
