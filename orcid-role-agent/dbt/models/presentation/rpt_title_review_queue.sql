{{ config(materialized='table') }}

/*
    INSAN REVIEW KUYRUGU - projenin en yuksek getirili adimi.

    Belirsiz bolgedeki unvanlari FREKANSA gore siralar. Is unvani dagilimi
    cok dengesiz oldugu icin en tepedeki birkac yuz unvan, kisilerin
    buyuk kismini kapsar. ~2 saatlik goz gezdirme, on binlerce kisilik
    dogruluk kazanci demek.

    Karari verdikten sonra seeds/role_title_overrides.csv'ye satir ekle,
    dbt seed && dbt run -s dim_title_role+  calistir.
*/

select
    title,
    role_key,
    frequency,
    round(include_similarity, 3)    as similarity,
    matched_anchors,
    decision_source,
    is_role_member                  as current_decision,
    round(
        sum(frequency) over (order by frequency desc)
        / sum(frequency) over (), 4
    )                               as cumulative_coverage
from {{ ref('dim_title_role') }}
where needs_human_review
   or decision_source = 'LLM_JUDGE'
order by frequency desc
