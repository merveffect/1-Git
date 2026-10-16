/*
    Every role in the registry must have org_type_scores rows. The
    organisation axis carries 0.15-0.40 of the final score, so a role
    with no rows scores every organisation at the default and the weight
    is spent on nothing.

    Checks disabled roles too, via all_role_keys(). A role is normally
    switched off because it is not ready, and this is one of the things
    that has to be true before it can be switched on - librarian sat
    disabled with a title group that did not exist, so it could never
    have produced a single person.
*/

with registry as (
    {% for k in all_role_keys() %}
    select '{{ k }}' as role_key
    {%- if not loop.last %} union all {% endif %}
    {% endfor %}
),

scored as (
    select role_key, count(*) as org_type_rows
    from {{ ref('org_type_scores') }}
    group by 1
)

select
    r.role_key,
    coalesce(s.org_type_rows, 0) as org_type_rows
from registry r
left join scored s using (role_key)
where coalesce(s.org_type_rows, 0) = 0
