{{ config(materialized='view') }}

/*
    ⭐ TUM KAYNAKLARIN BIRLESTIGI TEK NOKTA

    Bu modelin ustundeki HICBIR sey verinin nereden geldigini bilmiyor.
    Sozluk, skorlama ve sunum katmanlari sadece bu semayi goruyor.

    YENI KAYNAK EKLEMEK:
      1. stg_<kaynak>__role_records.sql yaz - ayni kolonlari uret
      2. dbt_project.yml -> sources.<kaynak>.enabled: true
                            sources.<kaynak>.staging_model: '<model adi>'
      3. dbt run
    Baska hicbir dosya degismez.
*/

with unioned as (

    {%- for key in source_keys() %}
    {%- set src = var('sources')[key] %}

    select
        '{{ key }}'             as source_key,
        snid,
        role_title_raw,
        role_title,
        organisation_raw,
        organisation,
        department_raw,
        department,
        org_id,
        org_id_source,
        country_code,
        start_date,
        end_date,
        is_current,
        ordering,
        source_last_updated
    from {{ ref(src.staging_model) }}

    {% if not loop.last %}union all{% endif %}
    {%- endfor %}

)

select
    *,
    to_hex(md5(role_title))                     as title_key,

    -- kisi + kaynak icinde en guncel kayit
    row_number() over (
        partition by snid, source_key
        order by is_current desc,
                 start_date desc nulls last,
                 end_date   desc nulls last,
                 ordering   asc  nulls last
    )                                           as recency_rank
from unioned
