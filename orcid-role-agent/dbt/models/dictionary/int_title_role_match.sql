{{ config(materialized='table') }}

/*
    VECTOR SEARCH SONUCU + KARAR

    Her unvan, her rolun anchor'larina karsi aranir.

    IKI OLCU KULLANIYORUZ:
      1. MUTLAK benzerlik  - "bu unvan bu role ne kadar yakin?"
      2. MARJ              - "en iyi rol, ikinciyi ne kadar geride birakti?"

    Marj neden lazim: bu modelin taban benzerligi yuksek (alakasiz iki
    terim bile 0.57 aliyor). Mutlak esik tek basina kirilgan kaliyor.
    Marj taban kaymasindan etkilenmiyor.
*/

with matches as (

    select
        query.title_key,
        query.title,
        query.frequency,
        base.role_key,
        base.anchor_term,
        base.polarity,
        1 - distance     as similarity
    from vector_search(
        table {{ ref('int_anchor_embeddings') }}, 'embedding',
        table {{ ref('int_title_embeddings') }},  'embedding',
        top_k           => 10,
        distance_type   => 'COSINE'
    )

),

-- include / exclude anchor'larini ayri ayri en iyi skora indir
best_per_role as (

    select
        title_key,
        title,
        frequency,
        role_key,
        max(if(polarity = 'include', similarity, null))  as include_similarity,
        max(if(polarity = 'exclude', similarity, null))  as exclude_similarity,
        array_agg(
            if(polarity = 'include', anchor_term, null) ignore nulls
            order by similarity desc limit 3
        )                                                as matched_anchors
    from matches
    group by title_key, title, frequency, role_key

),

-- unvan icinde roller arasi siralama -> marj
with_margin as (

    select
        *,
        include_similarity - coalesce(
            max(include_similarity) over (
                partition by title_key
                order by include_similarity desc
                rows between 1 following and 1 following
            ), 0.0
        )                                                as role_margin,
        row_number() over (
            partition by title_key order by include_similarity desc
        )                                                as role_rank
    from best_per_role
    where include_similarity is not null

)

select
    title_key,
    title,
    frequency,
    role_key,
    include_similarity,
    exclude_similarity,
    role_margin,
    role_rank,
    matched_anchors,

    /*
        exclude anchor'i include'dan daha yakinsa bu bir tuzak.
        Ornek: "data consultant" -> include:'consultant physician' 0.74
                                    exclude:'data consultant'      0.97
        Phase-1'deki exclusion kurallarinin vektor karsiligi.
    */
    coalesce(exclude_similarity, 0) > coalesce(include_similarity, 0)
        as blocked_by_exclusion,

    -- 355.803 unvanin hepsine ayni islem gereksiz; frekans katmani
    case
        when frequency >= {{ var('tier_a_min_frequency') }} then 'A'
        when frequency >= {{ var('tier_b_min_frequency') }} then 'B'
        else 'C'
    end                                                  as frequency_tier,

    case
        when coalesce(exclude_similarity, 0) > coalesce(include_similarity, 0)
            then 'REJECTED_EXCLUSION'

        -- yuksek benzerlik VE net marj -> tartisma yok
        when include_similarity >= {{ var('sim_auto_accept') }}
         and role_margin        >= {{ var('sim_min_margin') }}
            then 'AUTO_ACCEPT'

        -- belirsiz bolge
        when include_similarity >= {{ var('sim_judge_floor') }}
            then
            {%- if var('use_llm_judge') %}
                case when frequency >= {{ var('tier_b_min_frequency') }}
                     then 'NEEDS_JUDGE'
                     else 'AUTO_ACCEPT_TAIL' end
            {%- else %}
                -- LLM hakemi kapali: marj yeterliyse kabul, degilse red
                case when role_margin >= {{ var('sim_min_margin') }}
                     then 'AUTO_ACCEPT_TAIL'
                     else 'REJECTED_AMBIGUOUS' end
            {%- endif %}

        else 'REJECTED_LOW_SIMILARITY'
    end                                                  as match_decision,

    /*
        Insan review kuyrugu: belirsiz VE cok kisiyi etkileyen unvanlar.
        LLM hakemi kapaliyken bu kuyruk daha da onemli - tek dogrulama
        mekanizmasi bu.
    */
    (     include_similarity >= {{ var('sim_judge_floor') }}
      and (   include_similarity < {{ var('sim_review_floor') }}
           or role_margin       < {{ var('sim_min_margin') }} )
      and frequency >= {{ var('tier_a_min_frequency') }} )  as needs_human_review

from with_margin
