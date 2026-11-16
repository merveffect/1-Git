{{ config(severity='warn') }}

/*
    Every rule in role_detail_map must reach at least one person.

    WHY THIS TEST EXISTS. Between whenever role_detail_map gained its
    org_type rules and 2026-11-16, NOT ONE of them had ever fired. The join
    compared ROR's lowercase `education` against the seed's capitalised
    `Education` with `=`, so it was false every time. Seven audiences have
    only org_type rules, so their role_detail column was null for every
    person in them, and role_detail ships - it is in fct_researcher_roles
    and goes to Braze as role_detailed_inferred.

    Nothing caught it because nothing looked. assert_every_role_has_org_scores
    checks that the SEED is complete; no test checked that the seed is
    REACHED. A seed row that matches nothing is indistinguishable from a seed
    row that does not exist, and the failure is silent in exactly the way
    that matters: the configuration looks done.

    This is the same shape as assert_title_patterns_all_match_something and
    assert_org_patterns_all_match_something. The lesson those two already
    record, and this is the third instance: a lookup table needs a test that
    it is hit, not only a test that it is well formed.

    A row that legitimately matches nobody should be deleted or given a note
    explaining why it is pre-emptive, the same convention role_title_overrides
    uses.

    SEVERITY IS 'warn' FOR THE FIRST RUN, DELIBERATELY. These rules have never
    once fired, so nobody knows which of the 44 are live and which were always
    dead - `librarian / Archive -> National Library` may well match nobody.
    Failing the build on its first sight of the truth would cost a build to
    learn something a warning tells us just as well. Once the list has been
    read and the dead rows removed or annotated, this becomes an error and
    stays one.
*/

with rules as (

    select role_key, match_type, match_value, detail_label
    from {{ ref('role_detail_map') }}

),

scored as (

    select snid, role_key, evidence_title, org_type
    from {{ ref('int_employment_scored') }}

),

hits as (

    select
        r.role_key,
        r.match_type,
        r.match_value,
        count(s.snid) as people
    from rules r
    left join scored s
           on s.role_key = r.role_key
          and (
                (r.match_type = 'org_type'
                 and upper(trim(coalesce(s.org_type, 'UNKNOWN'))) = upper(trim(r.match_value)))
             or (r.match_type = 'title'
                 and regexp_contains({{ normalize_title('s.evidence_title') }}, r.match_value))
              )
    group by r.role_key, r.match_type, r.match_value

)

select *
from hits
where people = 0
