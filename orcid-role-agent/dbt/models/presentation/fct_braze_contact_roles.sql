{{ config(materialized='table', cluster_by=['snid']) }}

/*
    ⭐ BRAZE DATA CONTRACT CIKTISI
    Bir satir = bir contact. Braze / MPC'ye giden nihai sema.

    ─────────────────────────────────────────────────────────────────────
    KRITIK: DORT DIZI POZISYONEL OLARAK HIZALI OLMAK ZORUNDA

        role_inferred[0]                        <-> Healthcare Professional
        role_detailed_inferred[0]               <-> Healthcare Professional - Practitioner
        role_inferred_data_source[0]            <-> Orcid
        role_inferred_data_source_last_updated[0] <-> 2026-09-23 10:00:00

    Dortu de AYNI siralanmis CTE'den, AYNI ORDER BY ile turetilir.
    Ayri ayri ARRAY_AGG yazmak sessiz hizalama bozulmasi uretir ve Braze
    bunu YAKALAYAMAZ - yanlis kisiye yanlis rol segmenti gider.

    Siralamayi degistirmek icin: dbt_project.yml -> contract.array_order
    ─────────────────────────────────────────────────────────────────────
*/

with audience as (

    select * from {{ ref('fct_role_audience') }}
    where role_label in ({{ sql_in_list(var('contract').include_labels) }})
      and {{ consent_predicate() }}

),

/*
    Ayni rol birden fazla kaynaktan gelebilir (ORCID + web scraping).
    Rol basina TEK satira indiriyoruz; kaynaklar birlestiriliyor.
*/
per_role as (

    select
        snid,
        role_key,
        {{ role_display_name_expr('role_key') }}    as role_inferred,

        -- "Healthcare Professional - Practitioner"
        concat(
            {{ role_display_name_expr('role_key') }},
            if(role_detail is null, '', concat('{{ var("contract").detail_separator }}', role_detail))
        )                                           as role_detailed_inferred,

        -- birden fazla kaynak: "Orcid + Web scraping"
        string_agg(
            distinct {{ source_display_name_expr('role_source') }},
            '{{ var("contract").detail_source_separator }}'
            order by {{ source_display_name_expr('role_source') }}
        )                                           as role_inferred_data_source,

        max(source_last_updated)                    as role_inferred_data_source_last_updated,
        max(role_final_score)                       as role_final_score,
        any_value(role_detail)                      as role_detail,
        any_value(country_code)                     as country_code,
        any_value(is_marketable)                    as is_marketable,
        any_value(is_advertisable)                  as is_advertisable,
        any_value(in_cdp)                           as in_cdp
    from audience
    group by snid, role_key, role_detail

),

/*
    TEK siralanmis kaynak. Butun diziler bundan cikar.
    role_inferred snid icinde benzersiz oldugu icin siralama TOTAL -
    beraberlik yok, dolayisiyla hizalama garanti.
*/
ordered as (

    select *
    from per_role
    -- ORDER BY burada degil; ARRAY_AGG icinde, hepsinde AYNI ifadeyle

),

contact as (

    select
        snid,

        -- ── contract alanlari ────────────────────────────────────────
        array_agg(role_inferred                             order by {{ contract_array_order() }})
            as role_inferred,
        array_agg(role_detailed_inferred                    order by {{ contract_array_order() }})
            as role_detailed_inferred,
        array_agg(role_inferred_data_source                 order by {{ contract_array_order() }})
            as role_inferred_data_source,
        array_agg(role_inferred_data_source_last_updated    order by {{ contract_array_order() }})
            as role_inferred_data_source_last_updated,

        -- ── ic kullanim: hizalamanin bozulamayacagi kanonik form ─────
        array_agg(
            struct(
                role_key,
                role_inferred,
                role_detailed_inferred,
                role_inferred_data_source           as data_source,
                role_inferred_data_source_last_updated as last_updated,
                round(role_final_score, 3)          as confidence
            )
            order by {{ contract_array_order() }}
        )                                           as roles_struct,

        any_value(country_code)                     as country_code,
        max(is_marketable)                          as is_marketable,
        max(is_advertisable)                        as is_advertisable,
        max(in_cdp)                                 as in_cdp
    from ordered
    group by snid

)

select
    /*
        contact_email CDP tarafindan gelir - bu pipeline email tutmaz.
        TODO: audience_builder_big'deki email kolonunun adi dogrulanacak.
    */
    cast(null as string)                            as contact_email,   -- TODO
    c.snid,
    c.role_inferred,
    c.role_detailed_inferred,
    c.role_inferred_data_source,
    c.role_inferred_data_source_last_updated,

    -- contract disi, bizim icin
    c.roles_struct,
    c.country_code,
    array_length(c.role_inferred)                   as role_count,
    case
        when c.is_marketable then 'marketing_opt_in'
        when c.in_cdp        then 'legitimate_interest'
    end                                             as consent_basis,
    c.is_marketable,
    c.is_advertisable,
    current_date()                                  as contract_date
from contact c
