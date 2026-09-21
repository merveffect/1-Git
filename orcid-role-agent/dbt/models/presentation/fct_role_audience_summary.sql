{{ config(materialized='table') }}

/*
    Agent'in kullaniciya gosterecegi ozet. "47.000 kisi buldum" demek
    yaniltici; iş birimini ilgilendiren sayi en alttaki.
*/

select
    role_key,
    role_label,
    country_code,
    count(*)                                            as identified,
    countif(in_cdp)                                     as in_cdp,
    countif(is_marketable)                              as marketable,
    countif(is_advertisable)                            as advertisable,
    safe_divide(countif(in_cdp), count(*))              as cdp_coverage,
    safe_divide(countif(is_marketable), count(*))       as marketable_rate,
    round(avg(role_final_score), 3)                     as avg_score,
    max(scored_date)                                    as scored_date
from {{ ref('fct_role_audience') }}
group by role_key, role_label, country_code
