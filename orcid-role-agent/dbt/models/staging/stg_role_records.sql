{{ config(materialized='view') }}

/*
    ⭐ TUM KAYNAKLARIN BIRLESTIGI TEK NOKTA

    GARANTI ALANLAR - her kaynakta olmak ZORUNDA:
        snid, role_title
    Geri kalan her sey OPSIYONEL. Kaynak tasimiyorsa NULL gelir; o kaynak
    icin skor agirliklari yeniden normalize edilir (bkz. macros/scoring.sql).

    Bu sayede web scraping gibi sadece (snid, role) tasiyan bir kaynak
    da pipeline'a girebiliyor ve esigi gecebiliyor.

    YENI KAYNAK EKLEMEK:
      1. stg_<kaynak>__role_records.sql - en az snid + role_title uret
      2. dbt_project.yml -> vars.sources altina bir blok
      3. dbt run
    Bu dosya dahil baska HICBIR sey degismez.

    Kaynak listesi: {{ source_keys() | join(', ') }}
*/

with unioned as (

    {%- for key in source_keys() %}

    -- ── {{ key }} ({{ source_config(key).display_name }}) ──
    -- tasidigi alanlar: {{ source_provides(key) | join(', ') or 'sadece snid + role_title' }}
    {{ role_record_select(key) }}

    {% if not loop.last %}union all{% endif %}
    {%- endfor %}

),

with_currency as (

    select
        *,
        case source_key
        {%- for key in source_keys() %}
            when '{{ key }}' then {{ is_current_expr(key) }}
        {%- endfor %}
        end                                         as is_current
    from unioned

)

select
    *,
    to_hex(md5(role_title))                         as title_key,
    row_number() over (
        partition by snid, source_key
        order by is_current desc,
                 start_date desc nulls last,
                 end_date   desc nulls last,
                 ordering   asc  nulls last
    )                                               as recency_rank
from with_currency
