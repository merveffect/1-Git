{#-
    SCORING
    -------
    Weights and thresholds live ONLY in dbt_project.yml. These macros
    read the registries and emit SQL. Adding a role or a source changes
    nothing in this file.
-#}

{#-
    Weighted composite score per role.

        score = role*w_role + org*w_org + dept*w_dept

    Weights are per role and live in dbt_project.yml. They encode which
    axis leads: hcp is discipline-led (dept 0.40), researcher is title-led
    (dept 0.00).

    For a field-agnostic role the dept weight is 0 and dept_score arrives
    NULL, so the discipline is ignored rather than counted as missing
    evidence. That is what "all fields" means in practice.

    Worked, for hcp at 0.35 / 0.25 / 0.40:
        "consultant cardiologist", no department
            1.00*0.35 + 1.00*0.25 + 0*0.40 = 0.60   CONFIRMED
        "professor", department Cardiology
            0*0.35 + 1.00*0.25 + 1.00*0.40 = 0.65   CONFIRMED
    Both routes reach the threshold, which is the point of reading both
    axes.
-#}
{% macro composite_score_expr() %}
    CASE role_key
    {%- for k in role_keys() %}
    {%- set w = role(k).weights %}
        WHEN '{{ k }}' THEN
            LEAST(1.0,
                  COALESCE(role_score, 0.0) * {{ w.role }}
                + COALESCE(org_score, 0.0)  * {{ w.org }}
                {%- if w.dept > 0 %}
                + COALESCE(dept_score, 0.0) * {{ w.dept }}
                {%- endif %}
            )
    {%- endfor %}
        ELSE NULL
    END
{% endmacro %}


{#- CONFIRMED / PROBABLE / NOT_QUALIFIED using per-role thresholds -#}
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
    Drops historical records for roles configured as current_only.
    Used in a WHERE clause.
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
    Parent roll-up rows.
    Example: pharmacist -> the same person is also written as
    hcp / PRACTITIONER. Relationships come from roles.*.parent.
    Expects a CTE named <cte_name> at the call site.
-#}
{% macro parent_rollup_union(cte_name) %}
    {%- for m in roles_with_parent() %}

    UNION ALL

    -- {{ m.child }} -> {{ m.parent }} ({{ m.bucket }}) roll-up
    SELECT
        snid,
        '{{ m.parent }}'                       AS role_key,
        '{{ m.bucket_label }}'                 AS role_detail,
        role_final_score,
        role_label,
        -- the child's component scores, kept so the parent row stays
        -- auditable; derived_from_role says which child they came from
        role_score,
        org_score,
        dept_score,
        title_group,
        discipline,
        evidence_title,
        evidence_org,
        evidence_dept,
        country_code,
        is_current,
        source_key,
        source_last_updated,
        '{{ m.child }}'                        AS derived_from_role
    FROM {{ cte_name }}
    WHERE role_key = '{{ m.child }}'
      AND role_label IN ('CONFIRMED', 'PROBABLE')
    {%- endfor %}
{% endmacro %}


{#-
    Wide (pivoted) flag columns for the presentation layer.
    Used with GROUP BY snid.
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
