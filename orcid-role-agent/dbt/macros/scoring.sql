{#-
    SKORLAMA
    --------
    Agirliklar / esikler SADECE dbt_project.yml'de. Buradaki makrolar
    rol kayit defterinden okuyup SQL ifadesi uretir.
    Yeni rol eklenince bu dosyada HICBIR sey degismez.
-#}

{#-
    role_score / org_score / dept_score / education_score kolonlari
    mevcutken, rol bazli agirlikli kompozit skoru uretir.

    Formul (Phase-1 HCP dokumaninin genellestirilmis hali):
        LEAST(1.0, role*w_role + org*w_org + dept*w_dept)
          + education_score * education_bonus
-#}
{#-
    KAYNAK BAZLI AGIRLIK NORMALIZASYONU

    Phase-1 formulu: role*0.50 + org*0.30 + dept*0.20
    Ama her kaynak bu uc alani tasimiyor. Web scraping sadece unvan
    veriyorsa, sabit agirliklarla o kisi en fazla 0.50 alabilir ve
    0.60 esigini ASLA gecemez - yani o kaynak ise yaramaz olur.

    Cozum: kaynagin TASIYABILDIGI alanlarin agirliklarini 1.0'a
    yeniden dagit.

        orcid        (role+org+dept) -> 0.50 / 0.30 / 0.20
        web_scraping (role+org)      -> 0.625 / 0.375 / -
        cdp          (sadece role)   -> 1.00 / - / -

    ONEMLI AYRIM: ORCID'de departman alani BOS olmasi ile, kaynagin
    departman alanini HIC tasimamasi farkli seyler. Birincisi gercek
    kanit eksikligi (skoru dusurmeli, Phase-1 davranisi korunur),
    ikincisi yapisal (normalize edilmeli). Bu makro sadece ikincisini
    duzeltiyor.
-#}
{% macro normalized_weights(role_key, source_key) %}
    {%- set w = role(role_key).weights -%}
    {%- set has = source_provides(source_key) -%}
    {%- set w_role = w.role -%}
    {%- set w_org  = w.org  if 'organisation' in has else 0.0 -%}
    {%- set w_dept = w.dept if 'department'   in has else 0.0 -%}
    {%- set total  = w_role + w_org + w_dept -%}
    {{ return({
        'role': (w_role / total) | round(4),
        'org':  (w_org  / total) | round(4),
        'dept': (w_dept / total) | round(4)
    }) }}
{% endmacro %}


{#-
    role_score / org_score / dept_score / education_score kolonlari
    mevcutken, (rol x kaynak) bazli agirlikli kompozit skoru uretir.
-#}
{% macro composite_score_expr() %}
    CASE
    {%- for k in role_keys() %}
    {%- for s in source_keys() %}
    {%- set w = normalized_weights(k, s) %}
        WHEN role_key = '{{ k }}' AND source_key = '{{ s }}' THEN
            LEAST(1.0,
                  COALESCE(role_score, 0.0)  * {{ w.role }}
                {%- if w.org > 0 %}
                + COALESCE(org_score, 0.0)   * {{ w.org }}
                {%- endif %}
                {%- if w.dept > 0 %}
                + COALESCE(dept_score, 0.0)  * {{ w.dept }}
                {%- endif %}
            )
            + COALESCE(education_score, 0.0) * {{ role(k).get('education_bonus', 0.0) }}
    {%- endfor %}
    {%- endfor %}
        ELSE NULL
    END
{% endmacro %}


{#- Rol bazli esiklerle CONFIRMED / PROBABLE / NOT_QUALIFIED -#}
{% macro role_label_expr(score_col='role_final_score') %}
    CASE
    {%- for k in role_keys() %}
        {%- set t = role(k).thresholds %}
        WHEN role_key = '{{ k }}' AND {{ score_col }} >= {{ t.confirmed }} THEN 'CONFIRMED'
        WHEN role_key = '{{ k }}' AND {{ score_col }} >= {{ t.probable }}  THEN 'PROBABLE'
    {%- endfor %}
        ELSE 'NOT_QUALIFIED'
    END
{% endmacro %}


{#-
    current_only = true olan roller icin gecmis kayitlari eler.
    WHERE cumlesinde kullanilir.
-#}
{% macro current_only_predicate(is_current_col='is_current') %}
    {%- set keys = current_only_role_keys() -%}
    {%- if keys | length == 0 -%}
        TRUE
    {%- else -%}
        NOT (role_key IN ({{ sql_in_list(keys) }}) AND NOT COALESCE({{ is_current_col }}, FALSE))
    {%- endif -%}
{% endmacro %}


{#-
    Ebeveyn roll-up satirlari.
    Ornek: pharmacist -> ayni kisi hcp/PRACTITIONER olarak da yazilir.
    Cagrildigi yerde <scored_cte> adinda bir CTE beklenir.
-#}
{% macro parent_rollup_union(cte_name) %}
    {%- for m in roles_with_parent() %}

    UNION ALL

    -- {{ m.child }} -> {{ m.parent }} ({{ m.bucket }}) roll-up
    SELECT
        snid,
        source_key,
        '{{ m.parent }}'                       AS role_key,
        '{{ m.bucket_label }}'                 AS role_detail,
        role_final_score,
        role_label,
        evidence_title,
        evidence_org,
        evidence_dept,
        country_code,
        is_current,
        source_last_updated,
        '{{ m.child }}'                        AS derived_from_role
    FROM {{ cte_name }}
    WHERE role_key = '{{ m.child }}'
      AND role_label IN ('CONFIRMED', 'PROBABLE')
    {%- endfor %}
{% endmacro %}


{#-
    Presentation katmani icin genis (wide) bayrak kolonlari uretir.
    GROUP BY snid ile kullanilir.
-#}
{% macro role_flag_columns(qualified_labels=['CONFIRMED', 'PROBABLE']) %}
    {%- for k in role_keys() %}
    MAX(IF(role_key = '{{ k }}' AND role_label IN ({{ sql_in_list(qualified_labels) }}), TRUE, FALSE))
        AS is_{{ k }},
    MAX(IF(role_key = '{{ k }}', role_final_score, NULL))
        AS {{ k }}_score,
    MAX(IF(role_key = '{{ k }}', role_label, NULL))
        AS {{ k }}_label{% if not loop.last %},{% endif %}
    {%- endfor %}
{% endmacro %}
