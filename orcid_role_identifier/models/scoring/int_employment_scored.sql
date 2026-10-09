{{ config(materialized='table') }}

/*
    Role / org / dept sub-scores per person x role.

    Every role reads BOTH axes and fires from either. That matters: a
    consultant cardiologist whose department is empty - 11.6% of records
    have no department - carries an unmistakable title and would be lost
    if the discipline were the only route.

        role_score  does the TITLE support this role?
        How a record gets in is set per role by "match" - see
        role_match_mode(). The default, title_required, means the title
        is the only way in and the field only adds score.
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
    {#- written out per mode rather than splicing a keyword in: the old
        version built the operator with a replace() chain, which is the
        kind of cleverness that hides a missing bracket -#}
    {%- set mode = role_match_mode(k) %}
    where
        {%- if tg | length > 0 and dg | length > 0 and mode == 'title_and_field' %}
        -- both axes required
        w.title_group in ({{ sql_in_list(tg) }})
        and w.discipline in ({{ sql_in_list(dg) }})
        {%- elif tg | length > 0 and dg | length > 0 and mode == 'title_or_field' %}
        -- either axis is enough
        (   w.title_group in ({{ sql_in_list(tg) }})
         or w.discipline  in ({{ sql_in_list(dg) }}) )
        {%- elif tg | length > 0 %}
        -- the title is the only way in; the discipline only adds score
        w.title_group in ({{ sql_in_list(tg) }})
        {%- else %}
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
    Organisation fallback. A fifth of records carry no resolvable
    identifier, and organisation_name is always populated, so a small
    pattern list rescues most of them. This is what Phase-1 did, and it
    worked. Only used when ROR produced nothing better.

    "NOTHING BETTER" USED TO MEAN "no ROR id", WHICH IS NOT THE SAME
    THING. ROR can match an organisation and still carry no `types` array
    for it, and then org_score_ror falls back to the role's UNKNOWN value
    while ror_id is not null - so the old split sent the row down the
    branch with no fallback, and a name that plainly says what it is got
    the unknown score anyway.

    That is how "Deakin University - Geelong Campus at Waurn Ponds",
    "Istanbul University-Cerrahpasa" and "Universiti Malaysia Sabah" all
    ended up on lecturer's UNKNOWN score of 0.25, in the bottom band of
    the role, beside a zoo educator and a bank economist. The pattern list
    has matched "universit" since the first version; it was simply never
    consulted for them.

    The condition is now the one the comment always claimed: the patterns
    are consulted exactly when ROR produced no usable type, which is what
    org_type = 'UNKNOWN' means - it is
    coalesce(ror_types[safe_offset(0)], 'UNKNOWN'). Written as one branch
    rather than a union of two, so the predicate cannot drift apart again.
*/
with_org_fallback as (
    select
        w.*,
        case
            when w.org_type != 'UNKNOWN' then w.org_score_ror
            else greatest(
                w.org_score_ror,
                coalesce((
                    select max(f.org_score)
                    from {{ ref('org_name_patterns') }} f
                    where f.role_key = w.role_key
                      and regexp_contains(coalesce(w.organisation, ''), f.name_pattern)
                ), 0.0)
            )
        end                                         as org_score
    from with_org_score w
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
/*
    ONE RECORD PER PERSON PER ROLE: THE MOST RECENT ONE.

    This used to order by role_score, picking whichever of a person's
    posts matched the role best. It now orders purely by recency, so a
    person is always described by their CURRENT occupation.

    Note what this does NOT do. The per_role filter above has already
    thrown out every record that cannot support this role, so the choice
    here is only ever between posts that DO support it. Nobody loses a
    role by holding a newer unrelated job - they are still found through
    the clinical or academic post they hold, it is just represented by the
    most recent one of those rather than the best-matching one.

    What it costs: where someone has two qualifying posts and the older
    one matches the title anchors more strongly, the score now comes from
    the weaker, newer one. Expect average scores to dip slightly and some
    CONFIRMED to move to PROBABLE.

    What it buys, which is worth more: evidence_title, evidence_org and
    evidence_dept now describe where the person works today. Marketing
    acts on those fields, and a role sourced from a post someone left in
    2015 is wrong however well its title scored. It also makes a person's
    evidence coherent across roles - before, the same person could be
    represented by a 2015 post for hcp and a 2023 post for lecturer.

    recency_rank is itself ordered current-first (end_date is null desc,
    then start_date desc, then end_date desc, then ORCID's own ordering),
    so is_current is redundant here. It stays because it makes the intent
    readable and survives a change to recency_rank's definition.

    fct_researcher_roles still breaks its own ties on score. That is a
    different question - it chooses between a role's own row and a
    roll-up row from a child role, where the strongest evidence is what
    should win, and recency is not defined across roles.
*/
qualify row_number() over (
    partition by snid, role_key
    order by is_current desc, recency_rank asc
) = 1
