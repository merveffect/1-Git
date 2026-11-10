/*
    ============================================================================
    45. WHICH TWO OVERRIDES STOPPED TAKING EFFECT
    ============================================================================
    The build of 2026-11-10 13:35 failed on assert_overrides_take_effect
    with 2 results. 29 nodes skipped, nothing landed.

    WHAT HAS ALREADY BEEN RULED OUT, so this query is not a fifth guess:

      the axis filters hold. int_title_group_match filters
      `base.axis = 'title'` and int_discipline_match filters
      `base.axis = 'discipline'`, so the 16 new discipline anchors cannot
      reach title matching at all. That was the worst case and it is not
      this.

      no duplicate overrides. The researcher_early + researcher_established
      merge renamed 195 override rows to `researcher`, which could have
      created two rows for one title. Counted: 0 titles carry more than one
      override row.

      a pattern cannot defeat an override. dim_title_group resolves with
      coalesce(o.title_group, pt.title_group, m.title_group) and
      decision_source reads 'HUMAN' whenever o.human_decision is not null,
      so the 1.17 student pattern cannot take a title an override claims.

    So the remaining candidate is the test's FIRST branch - an override
    whose title is not in the dictionary at all and is not marked
    [pre-emptive]. That does not depend on anchors either, which would
    mean the test has been failing since the merge and build 2 never ran
    it. Either way this query names the rows and the guessing stops.

    title_key is rebuilt here in literal SQL because an analysis file
    cannot call the normalize_title macro. All 22 abbreviations from
    dbt_project.yml are reproduced in the same order.

    AND THAT RECONSTRUCTION IS NOT RELIABLE - RUN 2026-11-10, READ THIS
    BEFORE TRUSTING QUERY 1.

        query 2   584 override rows, 573 matched, 11 unmatched, 3 of
                  those marked [pre-emptive]
        query 1   9 failing rows
        the test  2

    Query 2 exists to catch exactly this and it did. The test is
    authoritative and my normalisation is wrong somewhere, so SIX OR
    SEVEN of query 1's nine rows are my reconstruction failing to match a
    title the macro matches. Which two are real cannot be read off this
    file.

    DO NOT PATCH THE EXPRESSION. dbt already has the feature:

        dbt test --select assert_overrides_take_effect --store-failures

    writes the failing rows to a table in the
    <schema>_dbt_test__audit dataset, computed by the macro itself. That
    is the answer, and this file is how not to get it.

    ONE ROW IS WORTH KEEPING FROM QUERY 1 because it does not depend on
    the normalisation - it matched a dictionary row, so the join worked:

        pi | ACCEPT | researcher | actual researcher | VECTOR | 1.0

    Right group, right score, wrong provenance. The override says a human
    decided `pi` is a researcher; the dictionary says the vector did.
    `pi` expands to `principal investigator` through the abbreviation
    list, which is almost certainly an exact anchor match at 1.0, so the
    two agree and nothing is mislabelled - but the test is right to fail,
    because an override that silently stops being the reason is the one
    failure mode this test was written for.
    ============================================================================
*/


-- ----------------------------------------------------------------------------
-- 1. THE FAILING ROWS, NAMED. The test's own logic, nothing added.
-- ----------------------------------------------------------------------------
with expected as (
    select
        title,
        nullif(trim(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(trim(regexp_replace(regexp_replace(lower(normalize_and_casefold(coalesce(title, ''), nfkc)), r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')), r'\bprof\b', 'professor'), r'\bassoc\b', 'associate'), r'\basst\b', 'assistant'), r'\bsr\b', 'senior'), r'\bjr\b', 'junior'), r'\bdept\b', 'department'), r'\bdiv\b', 'division'), r'\bdir\b', 'director'), r'\bmgr\b', 'manager'), r'\bres\b', 'research'), r'\bsci\b', 'scientist'), r'\bphys\b', 'physician'), r'\bpharm\b', 'pharmacy'), r'\bmed\b', 'medical'), r'\bclin\b', 'clinical'), r'\buniv\b', 'university'), r'\bhosp\b', 'hospital'), r'\blib\b', 'library'), r'\bpi\b', 'principal investigator'), r'\bpdra\b', 'postdoctoral research associate'), r'\bpost doc\b', 'postdoc'), r'\bpost-doc\b', 'postdoc'), r'\s+', ' ')), '') as title_key_text,
        title_group  as expected_group,
        decision,
        coalesce(note, '') as note
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.role_title_overrides`
),
actual as (
    select title, title_group, decision_source, is_assigned, group_score
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
)
select
    e.title,
    e.decision,
    e.expected_group,
    a.title_group        as actual_group,
    a.decision_source,
    a.is_assigned,
    a.group_score,
    case
        when a.title is null then 'NO SUCH TITLE in the dictionary, and not [pre-emptive]'
        when e.decision = 'ACCEPT' and a.decision_source != 'HUMAN'
            then 'ACCEPT: decision_source is ' || a.decision_source || ', not HUMAN'
        when e.decision = 'ACCEPT' and a.title_group != e.expected_group
            then 'ACCEPT: landed in ' || a.title_group || ', not ' || e.expected_group
        when e.decision = 'REJECT' then 'REJECT did not take effect'
        else 'unclassified'
    end as failure,
    e.note
from expected e
left join actual a on a.title = e.title_key_text
where (a.title is null and not contains_substr(e.note, '[pre-emptive]'))
   or (e.decision = 'ACCEPT' and (a.decision_source != 'HUMAN'
                                  or a.title_group != e.expected_group))
   or (e.decision = 'REJECT' and (a.decision_source != 'HUMAN'
                                  or a.is_assigned
                                  or a.group_score != 0.0))
;


-- ----------------------------------------------------------------------------
-- 2. SANITY ON THE NORMALISATION. If query 1 returns far more than 2 rows,
--    the title_key expression above is wrong rather than the pipeline, and
--    this says so: matched should be nearly all of the override seed.
-- ----------------------------------------------------------------------------
with expected as (
    select title, nullif(trim(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(trim(regexp_replace(regexp_replace(lower(normalize_and_casefold(coalesce(title, ''), nfkc)), r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')), r'\bprof\b', 'professor'), r'\bassoc\b', 'associate'), r'\basst\b', 'assistant'), r'\bsr\b', 'senior'), r'\bjr\b', 'junior'), r'\bdept\b', 'department'), r'\bdiv\b', 'division'), r'\bdir\b', 'director'), r'\bmgr\b', 'manager'), r'\bres\b', 'research'), r'\bsci\b', 'scientist'), r'\bphys\b', 'physician'), r'\bpharm\b', 'pharmacy'), r'\bmed\b', 'medical'), r'\bclin\b', 'clinical'), r'\buniv\b', 'university'), r'\bhosp\b', 'hospital'), r'\blib\b', 'library'), r'\bpi\b', 'principal investigator'), r'\bpdra\b', 'postdoctoral research associate'), r'\bpost doc\b', 'postdoc'), r'\bpost-doc\b', 'postdoc'), r'\s+', ' ')), '') as title_key_text, coalesce(note, '') as note
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.role_title_overrides`
)
select
    count(*)                                                  as override_rows,
    countif(a.title is not null)                              as matched_in_dictionary,
    countif(a.title is null)                                  as unmatched,
    countif(a.title is null and contains_substr(e.note, '[pre-emptive]')) as unmatched_but_preemptive
from expected e
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` a
    on a.title = e.title_key_text
;
