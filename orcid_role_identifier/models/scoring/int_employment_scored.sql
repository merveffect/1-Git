{{ config(materialized='table') }}

/*
    Role / org / dept sub-scores per person x role.

    Every role reads BOTH axes and fires from either. That matters: a
    consultant cardiologist whose department is empty - 11.6% of records
    have no department - carries an unmistakable title and would be lost
    if the discipline were the only route.

        role_score  does the TITLE support this role?
        The two axes are combined with OR by default and with AND for a
        role declaring "match: all" - see role_match_mode().
        dept_score  does the DISCIPLINE support this role?
        org_score   does the ROR organisation type support this role?

    A role with no disciplines listed is field-agnostic (researcher,
    lecturer, faculty_head). Its dept weight is 0, so the discipline is
    ignored rather than counted as missing evidence.

    NOTE ON COMMENTS INSIDE THE JINJA BRANCHES BELOW:
    use block comments (slash-star ... star-slash), never --.
    The whitespace-stripping tags join the next line onto the same line, so
    a -- comment swallows the alias that follows it and the column comes
    out unnamed. That cost a run with "Unrecognized name: dept_score".
*/

with records as (
    select * from {{ ref('stg_role_records') }}
),

-- title -> position group
with_title_group as (
    select
        r.*,
        t.title_group,
        t.group_score       as title_group_score
    from records r
    left join {{ ref('dim_title_group') }} t
           on r.title_key = t.title_key
          and t.is_assigned
),

-- department -> discipline
with_discipline as (
    select
        w.*,
        d.discipline,
        d.discipline_score
    from with_title_group w
    left join {{ ref('dim_department_discipline') }} d
           on to_hex(md5(w.department)) = d.department_key
          and d.is_assigned
),

-- organisation -> ROR type
with_org as (
    select
        w.*,
        o.ror_id,
        o.canonical_name    as org_canonical_name,
        o.ror_types,
        o.resolution_method as org_resolution_method
    from with_discipline w
    left join {{ ref('int_org_resolved') }} o
           on w.organisation = o.organisation
          and w.org_id is not distinct from o.org_id
),

/*
    Fan out to one row per (record, role). A record qualifies for a role
    if its title group supports that role, or its discipline does.
*/
per_role as (
    {%- for k in role_keys() %}
    {%- set tg = role_title_groups(k) %}
    {%- set dg = role_disciplines(k) %}

    select
        w.*,
        '{{ k }}'                                   as role_key,
        {% if tg | length > 0 -%}
        if(w.title_group in ({{ sql_in_list(tg) }}), coalesce(w.title_group_score, 0.0), 0.0)
        {%- else -%}
        0.0
        {%- endif %}                                as role_score,
        {% if dg | length > 0 -%}
        if(w.discipline in ({{ sql_in_list(dg) }}), coalesce(w.discipline_score, 0.0), 0.0)
        {%- else -%}
        /* field-agnostic role: the discipline is ignored */ cast(null as float64)
        {%- endif %}                                as dept_score
    from with_org w
    where
        {% if tg | length > 0 -%}
        w.title_group in ({{ sql_in_list(tg) }})
        {%- endif %}
        {%- if tg | length > 0 and dg | length > 0 %} {{ role_match_mode(k) | replace('all', 'and') | replace('any', 'or') }} {% endif %}
        {%- if dg | length > 0 %}
        w.discipline in ({{ sql_in_list(dg) }})
        {%- endif %}

    {% if not loop.last %}union all{% endif %}
    {%- endfor %}
),

/*
    org score from the (role, ROR type) pair. ROR types is an ARRAY - a
    university hospital is both Education and Healthcare - so we take the
    type that scores HIGHEST for the role. Overlap is an advantage.
*/
with_org_score as (
    select
        p.*,
        coalesce((
            select max(s.org_score)
            from unnest(coalesce(p.ror_types, ['UNKNOWN'])) as t
            join {{ ref('org_type_scores') }} s
              on s.role_key = p.role_key
             and upper(trim(s.org_type)) = upper(trim(t))
        ), (
            select s.org_score from {{ ref('org_type_scores') }} s
            where s.role_key = p.role_key and s.org_type = 'UNKNOWN'
        ), 0.0)                                     as org_score_ror,
        coalesce(p.ror_types[safe_offset(0)], 'UNKNOWN') as org_type
    from per_role p
),

/*
    Organisation fallback. 21% of records carry no resolvable identifier,
    and organisation_name is 100% populated, so a small pattern list
    rescues most of them. This is what Phase-1 did, and it worked.
    Only used when ROR produced nothing better.
*/
with_org_fallback as (
    select
        w.*,
        greatest(
            w.org_score_ror,
            coalesce((
                select max(f.org_score)
                from {{ ref('org_name_patterns') }} f
                where f.role_key = w.role_key
                  and regexp_contains(coalesce(w.organisation, ''), f.name_pattern)
            ), 0.0)
        )                                           as org_score
    from with_org_score w
    where w.ror_id is null

    union all

    select w.*, w.org_score_ror as org_score
    from with_org_score w
    where w.ror_id is not null
)

select
    snid,
    role_key,
    role_score,
    org_score,
    dept_score,
    title_group,
    discipline,
    org_type,
    ror_id,
    org_resolution_method,
    role_title_raw      as evidence_title,
    organisation_raw    as evidence_org,
    department_raw      as evidence_dept,
    org_canonical_name  as evidence_org_canonical,
    country_code,
    is_current,
    source_key,
    source_last_updated,
    recency_rank
from with_org_fallback
-- one record per person per role: current posts first, then best score
qualify row_number() over (
    partition by snid, role_key
    order by is_current desc, role_score desc, recency_rank asc
) = 1
