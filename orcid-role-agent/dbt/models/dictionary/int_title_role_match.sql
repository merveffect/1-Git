{{ config(materialized='table') }}

/*
    ============================================================================
    VECTOR SEARCH SONUCU + KARAR
    ============================================================================
    Kalibrasyon (analyses/02) sunu gosterdi:

      MUTLAK BENZERLIK TEK BASINA AYIRMIYOR
        dogru eslesmeler   0.682 - 1.000
        yanlis eslesmeler  0.519 - 0.953     <-- buyuk ortusme
        "pharmacologist" eczaciya 0.953 benziyor ama eczaci DEGIL.

      AYIRAN SEY: DISTRACTOR MARJI
        '__distractor' = hedef rollerimizden hicbiri olmayan yaygin
        meslekler (software engineer, hr manager, lawyer, ...).
        Soru artik "bu unvan role ne kadar benziyor" degil:
        "bu unvan role, hedef-disi mesleklere oldugundan NE KADAR
         DAHA FAZLA benziyor?"
        dogru eslesmelerde min +0.13 / yanlislarda cogu NEGATIF.

      COK ETIKETLILIK KORUNMALI
        "Professor of Cardiology" hem hcp hem researcher. En iyi rolun
        sim_tie_band kadar yakinindaki TUM roller kabul edilir; ikinci
        rolu cezalandirmiyoruz cunku ayni anda dogru olabilirler.
    ============================================================================
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
        top_k           => 20,
        distance_type   => 'COSINE'
    )

),

-- hedef roller: include / exclude anchor'larinin en iyileri
per_role as (

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
    where role_key != '__distractor'
    group by title_key, title, frequency, role_key

),

-- referans noktasi: unvan hedef-disi mesleklere ne kadar benziyor?
distractor as (

    select
        title_key,
        max(similarity)                                  as distractor_similarity,
        array_agg(anchor_term order by similarity desc limit 2) as nearest_distractors
    from matches
    where role_key = '__distractor'
    group by title_key

),

combined as (

    select
        r.*,
        coalesce(d.distractor_similarity, 0.0)          as distractor_similarity,
        d.nearest_distractors,

        -- ⭐ ASIL OLCU
        r.include_similarity
            - coalesce(d.distractor_similarity, 0.0)    as distractor_margin,

        -- unvan icinde en iyi rol (cok etiketlilik bandi icin)
        max(r.include_similarity) over (partition by r.title_key) as best_role_similarity

    from per_role r
    left join distractor d using (title_key)
    where r.include_similarity is not null

)

select
    title_key,
    title,
    frequency,
    role_key,
    include_similarity,
    exclude_similarity,
    distractor_similarity,
    distractor_margin,
    best_role_similarity,
    nearest_distractors,
    matched_anchors,

    -- rol-ozel exclude anchor'i include'dan yakinsa bu bir tuzak
    coalesce(exclude_similarity, 0) > include_similarity as blocked_by_exclusion,

    -- en iyi rolun bandi icinde mi? (cok etiketlilik)
    include_similarity >= best_role_similarity - {{ var('sim_tie_band') }}
                                                        as within_tie_band,

    case
        when frequency >= {{ var('tier_a_min_frequency') }} then 'A'
        when frequency >= {{ var('tier_b_min_frequency') }} then 'B'
        else 'C'
    end                                                 as frequency_tier,

    case
        -- 1. rol-ozel exclude bloklar (kalibrasyonda 15 yanlistan 9'unu yakaladi)
        when coalesce(exclude_similarity, 0) > include_similarity
            then 'REJECTED_EXCLUSION'

        -- 2. taban filtre
        when include_similarity < {{ var('sim_floor') }}
            then 'REJECTED_LOW_SIMILARITY'

        -- 3. hedef-disi mesleklere daha yakin veya marj yetersiz
        when include_similarity - distractor_similarity < {{ var('sim_min_margin') }}
            then 'REJECTED_DISTRACTOR'

        -- 4. en iyi rolden cok uzak (baska bir rol acikca daha uygun)
        when include_similarity < best_role_similarity - {{ var('sim_tie_band') }}
            then 'REJECTED_BETTER_ROLE_EXISTS'

        else 'ACCEPTED'
    end                                                 as match_decision,

    /*
        Insan review kuyrugu: marj sinira yakinsa karar kirilgan.
        LLM hakemi kapali oldugu icin tek dogrulama mekanizmasi bu -
        ve sadece SIK gecen unvanlar icin (tier A).
    */
    (     include_similarity - distractor_similarity >= {{ var('sim_min_margin') }}
      and include_similarity - distractor_similarity <  {{ var('sim_review_margin') }}
      and frequency >= {{ var('tier_a_min_frequency') }} ) as needs_human_review

from combined
