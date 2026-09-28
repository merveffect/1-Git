{{ config(materialized='view') }}

/*
    ROR external_ids duzlestirilmesi.

    Sema:  external_ids  ARRAY<STRUCT<type STRING, all ARRAY<STRING>, preferred STRING>>

    NEDEN LAZIM:
    ORCID employment kayitlarinin sadece %35'i ROR kimligi tasiyor.
    Geri kalan %44 baska sistemlerin kimligini tasiyor:
        RINGGOLD  %31.7
        GRID      % 7.8
        FUNDREF   % 4.0
    ROR bu kimlikleri external_ids icinde saklıyor - yani ROR kaydina
    bu kimlikler uzerinden de ulasabiliyoruz. Isim eslestirmeye
    dusmeden once bu koprulerden geciyoruz.

    'all' bir DIZI: ayni kurumun birden fazla Ringgold kimligi olabilir.
    Hepsini ayri satira aciyoruz.
*/

select
    r.ror_id,
    upper(x.type)               as id_type,       -- RINGGOLD / GRID / FUNDREF / ISNI ...
    trim(id_value)              as id_value,
    x.preferred                 as preferred_id
from {{ ref('stg_ror__organisations') }} r,
unnest(r.external_ids) x,
unnest(x.all) as id_value
where id_value is not null
  and trim(id_value) != ''
