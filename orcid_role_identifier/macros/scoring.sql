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
    Drops employment records whose post ended longer ago than
    vars.recency_months. Open-ended and undated records always survive -
    there is nothing in them to judge. Used in a WHERE clause, and it
    applies to every role: unlike current_only_predicate it does not
    switch on role_key.

    WHERE THIS GOES MATTERS, and it is not interchangeable with
    current_only_predicate's position. int_employment_scored ends with

        qualify row_number() over (partition by snid, role_key
                                   order by is_current desc, recency_rank asc) = 1

    and recency_rank (stg_role_records) orders by start_date BEFORE
    end_date. So a post that ran 2010-2012 outranks one that ran
    2005-2024, and the record this model keeps is not necessarily the one
    that ended most recently. Filter after the qualify and a person is
    dropped because the kept record is old, while another qualifying post
    of theirs ended last month. Filter before it - in the `records` CTE -
    and the qualify chooses from records that already passed. The measured
    per-audience costs in dbt_project.yml assume the early position.

    Pass null for recency_months to disable the rule.
-#}
{% macro recency_predicate(end_date_col='end_date') %}
    {%- set months = var('recency_months', none) -%}
    {%- if months is none -%}
        TRUE
    {%- else -%}
        ({{ end_date_col }} IS NULL
         OR {{ end_date_col }} >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ months }} MONTH))
    {%- endif -%}
{% endmacro %}


{#-
    Parent roll-up rows.
    Example: pharmacist -> the same person is also written as
    hcp / PRACTITIONER. Relationships come from roles.*.parent.
    Expects a CTE named <cte_name> at the call site.
-#}
{#-
    Roll a child role up into its parent, so hcp_practitioner also appears
    as hcp_broad.

    A person therefore carries BOTH names in the Braze role_inferred array -
    "Healthcare Professional (broad)" and "HCP - Practitioner". That is
    intended, not redundancy: a child is always a strict subset of its
    parent, so the pair is a hierarchy marketing can filter at either
    level. Confirmed as wanted on 2026-10-09; do not "fix" it by emitting
    only the most specific role.
-#}
{% macro parent_rollup_union(cte_name) %}
    {%- for m in roles_with_parent() %}

    UNION ALL

    -- {{ m.child }} -> {{ m.parent }} ({{ m.bucket }}) roll-up
    SELECT
        snid,
        '{{ m.parent }}'                       AS role_key,
        role_final_score,
        -- role_label is deliberately NOT carried. A child's label was
        -- computed against the CHILD's thresholds, and the parent's are
        -- different - hcp_broad confirms at 0.60 while its children
        -- confirm at 0.70 - so copying it labelled 5,528 people PROBABLE
        -- in hcp_broad who cleared its own threshold, and PROBABLE does
        -- not ship. fct_researcher_roles recomputes it after the union,
        -- where role_key is already the parent.
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
