{{ config(materialized='table') }}

/*
    SOZLUGUN 5. ADIMI - VECTOR SEARCH
    Her unvan, her rolun anchor'larina karsi aranir.
    Cikti: (unvan, rol) ciftinin en iyi benzerlik skoru.

    Institution matching'de yaptigin isin AYNISI - tek fark, burada
    hedef "standart kurum adi" degil "rol anchor'i".

    Esikler dbt_project.yml'de:
      >= sim_auto_accept  -> otomatik kabul
      >= sim_judge_floor  -> LLM hakemligi
      <  sim_judge_floor  -> red
*/

with matches as (

    select
        query.title_key,
        query.title,
        query.frequency,
        base.role_key,
        base.anchor_term,
        base.polarity,
        -- VECTOR_SEARCH mesafe dondurur; benzerlige cevir
        1 - distance     as similarity
    from vector_search(
        table {{ ref('int_anchor_embeddings') }}, 'embedding',
        table {{ ref('int_title_embeddings') }},  'embedding',
        top_k           => 5,
        distance_type   => 'COSINE',
        options         => '{"use_brute_force": false}'
    )

),

-- include ve exclude anchor'larini ayri ayri en iyi skora indir
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

)

select
    title_key,
    title,
    frequency,
    role_key,
    include_similarity,
    exclude_similarity,
    matched_anchors,

    /*
        exclude anchor'i include'dan daha yakinsa bu bir tuzak.
        Ornek: "data consultant" -> include:'consultant physician' 0.72
                                    exclude:'data consultant'      0.97
        Phase-1'deki exclusion kurallarinin vektor karsiligi.
    */
    coalesce(exclude_similarity, 0) > coalesce(include_similarity, 0)
        as blocked_by_exclusion,

    case
        when coalesce(exclude_similarity, 0) > coalesce(include_similarity, 0)
            then 'REJECTED_EXCLUSION'
        when include_similarity >= {{ var('sim_auto_accept') }}
            then 'AUTO_ACCEPT'
        when include_similarity >= {{ var('sim_judge_floor') }}
            then 'NEEDS_JUDGE'
        else 'REJECTED_LOW_SIMILARITY'
    end                                                  as match_decision,

    -- insan review kuyrugu: belirsiz VE cok kisiyi etkileyen unvanlar
    (     include_similarity >= {{ var('sim_judge_floor') }}
      and include_similarity <  {{ var('sim_review_floor') }} ) as needs_human_review

from best_per_role
where include_similarity is not null
