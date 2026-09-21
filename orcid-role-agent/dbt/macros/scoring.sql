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
{% macro composite_score_expr() %}
    CASE role_key
    {%- for k in role_keys() %}
        {%- set r = role(k) %}
        WHEN '{{ k }}' THEN
            LEAST(1.0,
                  COALESCE(role_score, 0.0)  * {{ r.weights.role }}
                + COALESCE(org_score, 0.0)   * {{ r.weights.org }}
                + COALESCE(dept_score, 0.0)  * {{ r.weights.dept }}
            )
            + COALESCE(education_score, 0.0) * {{ r.get('education_bonus', 0.0) }}
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
        '{{ m.parent }}'                       AS role_key,
        '{{ m.bucket }}'                       AS role_bucket,
        role_final_score,
        role_label,
        evidence_title,
        evidence_org,
        evidence_dept,
        country_code,
        is_current,
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
