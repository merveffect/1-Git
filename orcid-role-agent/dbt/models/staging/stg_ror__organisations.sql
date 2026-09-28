{{ config(materialized='view') }}

/*
    ROR KURUM KAYIT DEFTERI

    NE ISE YARIYOR:
    Skorlamada kurumun TIPI lazim. "Bu kisi hastanede mi calisiyor,
    universitede mi, bankada mi?" Cunku ayni unvan farkli kurumda
    farkli sey demek:

        "Director" + hastane      -> saglik yoneticisi
        "Director" + banka        -> alakasiz

    Kurum ADINDAN tip cikarmak zor ("St. Mary's Hosp." hastane mi?).
    ROR bunu hazir veriyor: her kurumun bir kimligi ve bir TIPI var.

        ror_id: 013czdx64
        name:   Heidelberg University Hospital
        types:  [Education, Healthcare]       <-- ihtiyacimiz olan

    Bu tipleri org_type_scores.csv'deki skorlarla eslestiriyoruz.

    ror_data_refresh = ROR'un KENDI registry dump'i (Merve'nin eski
    eslestirme ciktisi degil) - dogrulandi.

    !! KOLON ADLARI DOGRULANACAK:
       bq show --schema ri-data-engineering-dd4c0eca:ror.ror_data_refresh
*/

select
    id                                          as ror_id,
    name                                        as canonical_name,
    {{ normalize_title('name') }}               as organisation,     -- isim eslestirme anahtari

    -- types bir DIZI: universite hastanesi hem Education hem Healthcare
    types                                       as ror_types,

    country.country_code                        as ror_country_code

from {{ ref('raw_ror_data_refresh') }}
