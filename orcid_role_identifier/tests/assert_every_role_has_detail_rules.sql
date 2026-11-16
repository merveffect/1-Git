{{ config(severity='warn') }}
/*
    Every role in the registry must have role_detail_map rows.

    THE SIBLING TEST THAT WAS NEVER WRITTEN. assert_every_role_has_org_scores
    checks the same thing for the organisation axis, and it has been green
    since it was written, because org_type_scores carries all ten ROR types
    for all ten roles. role_detail_map was written to no such standard and
    nothing checked it. Measured 2026-11-16:

        role_detail_map covers  9 roles, org_type_scores covers 10.
        lecturer has no rows at all - 423,975 people, every one of them
        shipping a null role_detail to Braze since the column existed.

    This is the SECOND defect in a week found in this seed and the second
    of the same shape: a rule file that looked complete because nothing
    compared it to anything. The first was the case-sensitive join in
    int_role_detail (docs/open-questions.md 2.19); assert_role_detail_map_
    rules_all_fire now covers that direction - every rule reaches somebody.
    This covers the other direction - every role has a rule.

    WARN, NOT ERROR, and deliberately. It fails today on lecturer and will
    keep failing until that is a decision rather than an omission. Promote
    it the day the lecturer rows land, the way assert_role_detail_map_rules_
    all_fire was promoted once its build returned zero rows.
*/

with registry as (
    {% for k in all_role_keys() %}
    select '{{ k }}' as role_key
    {%- if not loop.last %} union all {% endif %}
    {% endfor %}
),

mapped as (
    select role_key, count(*) as detail_rules
    from {{ ref('role_detail_map') }}
    group by 1
)

select
    r.role_key,
    coalesce(m.detail_rules, 0) as detail_rules
from registry r
left join mapped m using (role_key)
where coalesce(m.detail_rules, 0) = 0
