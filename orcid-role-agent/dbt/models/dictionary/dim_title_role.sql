{{ config(materialized='table') }}

/*
    ⭐ SOZLUK - PROJENIN EN DEGERLI VARLIGI

    "Hangi is unvani hangi role ait?"  Bir satir = (unvan, rol) cifti.
    Bir unvan birden fazla role ait OLABILIR (multi-label).

    Bir kez uretilir, sonra 204.000 kisilik tabloya sadece JOIN atilir.
    Bu tablodan sonra hicbir yerde AI calismaz.
*/

with matched as (

    select * from {{ ref('int_title_role_match') }}

),

judged as (

    select title_key, role_key, judge_accepted, judge_status
    from {{ ref('int_title_role_judged') }}

),

overrides as (

    -- Insan kararlari her zaman kazanir. Bos birakilabilir.
    select
        to_hex(md5({{ normalize_title('title') }}))  as title_key,
        role_key,
        decision                                     as human_decision,
        reviewer,
        reviewed_at
    from {{ ref('role_title_overrides') }}

),

combined as (

    select
        m.title_key,
        m.title,
        m.role_key,
        m.frequency,
        m.include_similarity,
        m.exclude_similarity,
        m.matched_anchors,
        m.match_decision,
        m.needs_human_review,
        j.judge_accepted,
        o.human_decision,
        o.reviewer,

        case
            when o.human_decision is not null then o.human_decision = 'ACCEPT'
            when m.match_decision = 'AUTO_ACCEPT' then true
            when m.match_decision = 'NEEDS_JUDGE' then coalesce(j.judge_accepted, false)
            else false
        end                                          as is_role_member,

        case
            when o.human_decision is not null then 'HUMAN'
            when m.match_decision = 'AUTO_ACCEPT' then 'VECTOR'
            when m.match_decision = 'NEEDS_JUDGE' then 'LLM_JUDGE'
            else 'REJECTED'
        end                                          as decision_source

    from matched m
    left join judged    j using (title_key, role_key)
    left join overrides o using (title_key, role_key)

)

select
    *,
    /*
        Unvanin rol skoru (Phase-1'deki role_score'un karsiligi).
        Ikili degil, dereceli - ciddi bir iyilestirme: "consultant
        cardiologist" ile "clinical fellow" artik ayni skoru almiyor.
    */
    case
        when not is_role_member then 0.0
        when decision_source = 'HUMAN'  then 1.0
        when decision_source = 'VECTOR' then 1.0
        else least(1.0, 0.60 + (include_similarity - {{ var('sim_judge_floor') }}))
    end                                              as role_score
from combined
where is_role_member
   or needs_human_review        -- review kuyrugu icin reddedilenler de kalir
