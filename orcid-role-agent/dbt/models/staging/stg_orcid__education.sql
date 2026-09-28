{{ config(materialized='view') }}

/*
    educations[] duzlestirilir. Egitim SADECE bonus olarak skora girer;
    tek basina rol kazandirmaz (Phase-1 ile ayni ilke).
*/

with researchers as (

    select snid, orcid_id, educations
    from {{ source('researcher_profiles', 'orcid_researchers') }}
    where snid is not null

),

flattened as (

    select
        r.snid,
        r.orcid_id,
        d.visibility,
        d.ordering,

        d.degree                                        as degree_raw,
        d.department_name                               as edu_department_raw,
        d.organisation_name                             as edu_organisation_raw,

        {{ normalize_title('d.degree') }}               as degree,
        {{ normalize_title('d.department_name') }}      as edu_department,
        {{ normalize_title('d.organisation_name') }}    as edu_organisation,

        d.disambiguated_organisation_id                 as disambiguated_org_id,
        upper(d.disambiguated_organisation_source)      as disambiguated_org_source,
        d.organisation_address_country_code             as country_code,

        d.full_start_date                               as start_date,
        d.full_end_date                                 as end_date

    from researchers r,
    unnest(r.educations) d

),

ranked as (

    select
        *,
        row_number() over (
            partition by snid
            order by end_date desc nulls last,
                     start_date desc nulls last,
                     ordering asc nulls last
        ) as recency_rank
    from flattened

)

select * from ranked
where recency_rank = 1
  and (degree is not null or edu_department is not null)
  {% if var('public_visibility_only', true) %}
  and upper(visibility) = 'PUBLIC'
  {% endif %}
