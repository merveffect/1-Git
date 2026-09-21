{{ config(materialized='table') }}

/*
    SOZLUGUN 2. ADIMI - ANCHOR'LAR
    Her rol icin "bu role ait olan unvan nasil gorunur" ornekleri.

    Iki kaynaktan beslenir:
      1. seeds/role_anchors.csv  - elle yazilmis cekirdek terimler (cok dilli)
      2. ESCO occupations        - ISCO grubuna gore filtrelenmis, 27 dilde
                                   preferredLabel + altLabels

    Institution matching'deki "standart isim listesi"nin karsiligi budur.
*/

with seed_anchors as (

    select
        role_key,
        {{ normalize_title('anchor_term') }}    as anchor_term,
        polarity,                               -- 'include' | 'exclude'
        language_code,
        'seed'                                  as anchor_source
    from {{ ref('role_anchors') }}
    where role_key in ({{ sql_in_list(role_keys()) }})

),

{# ESCO henuz yuklenmediyse bu blok bos doner - pipeline kirilmaz #}
esco_anchors as (

    {% if var('use_esco', false) %}
    select
        m.role_key,
        {{ normalize_title('e.label') }}        as anchor_term,
        'include'                               as polarity,
        e.language_code,
        'esco'                                  as anchor_source
    from {{ ref('stg_esco__occupation_labels') }} e
    join (
        {%- for k in role_keys() %}
        {%- for g in role(k).get('isco_groups', []) %}
        select '{{ k }}' as role_key, '{{ g }}' as isco_prefix
        {% if not loop.last or not loop.parent.last %}union all{% endif %}
        {%- endfor %}
        {%- endfor %}
    ) m
      on starts_with(e.isco_group, m.isco_prefix)
    {% else %}
    select
        cast(null as string) as role_key,
        cast(null as string) as anchor_term,
        cast(null as string) as polarity,
        cast(null as string) as language_code,
        cast(null as string) as anchor_source
    where false
    {% endif %}

),

unioned as (
    select * from seed_anchors
    union all
    select * from esco_anchors
)

select
    to_hex(md5(concat(role_key, '|', anchor_term)))  as anchor_key,
    role_key,
    anchor_term,
    polarity,
    language_code,
    anchor_source
from unioned
where anchor_term is not null
  and role_key   is not null
-- ayni terim hem seed hem esco'dan gelirse: seed kazanir, exclude include'u ezer
qualify row_number() over (
    partition by role_key, anchor_term
    order by if(anchor_source = 'seed', 0, 1), if(polarity = 'exclude', 0, 1)
) = 1
