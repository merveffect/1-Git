{{ config(
    materialized = 'incremental',
    unique_key   = ['title_key', 'role_key']
) }}

/*
    SOZLUGUN 6. ADIMI - LLM HAKEMLIGI
    SADECE 'NEEDS_JUDGE' olan (unvan, rol) ciftleri Gemini'ye gider.

    Ekonomi: 50.000 unvan x 5 rol = 250.000 cift ama bunlarin
    belki 5.000'i belirsiz bolgede. Geri kalani bedava karara baglandi.

    incremental: ayni cift ikinci kez LLM'e sorulmaz.
*/

with to_judge as (

    select
        m.title_key,
        m.title,
        m.role_key,
        m.frequency,
        m.include_similarity,
        m.matched_anchors
    from {{ ref('int_title_role_match') }} m
    where m.match_decision = 'NEEDS_JUDGE'

    {% if is_incremental() %}
      and not exists (
          select 1 from {{ this }} t
          where t.title_key = m.title_key and t.role_key = m.role_key
      )
    {% endif %}

),

role_definitions as (
    {%- for k in role_keys() %}
    select
        '{{ k }}'                                           as role_key,
        '''{{ role(k).label }}'''                           as role_label,
        '''{{ role(k).description | replace("'", "") | replace("\n", " ") | trim }}'''
                                                            as role_description
    {% if not loop.last %}union all{% endif %}
    {%- endfor %}
),

prompted as (

    select
        j.*,
        d.role_label,
        concat(
            'Sen bir meslek siniflandirma uzmanisin. ',
            'ROL TANIMI: ', d.role_label, ' - ', d.role_description, ' ',
            'SORU: "', j.title, '" is unvanina sahip bir kisi bu role girer mi? ',
            'Sadece unvana bak; emin degilsen HAYIR de. ',
            'Yonetim/danismanlik unvanlari ilgili alanda degilse HAYIR.'
        )                                                   as judge_prompt
    from to_judge j
    join role_definitions d using (role_key)

)

judged as (

    -- AI.GENERATE_BOOL TEK kez cagrilir; struct acilarak kolonlara yayilir
    select
        *,
        {{ ai_generate_bool('judge_prompt') }}  as judge_result
    from prompted

)

select
    title_key,
    title,
    role_key,
    frequency,
    include_similarity,
    matched_anchors,
    judge_prompt,
    judge_result.result     as judge_accepted,
    judge_result.status     as judge_status,
    current_timestamp()     as judged_at
from judged
