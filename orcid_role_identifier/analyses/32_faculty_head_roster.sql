/*
    ============================================================================
    32. EVERY HEAD OF FACULTY MATCH, PERSON BY PERSON
    ============================================================================
    The full roster, for reading rather than for measuring. Two queries on the
    same population:

      Q1  ONE ROW PER PERSON. The evidence that put them in the audience -
          title, organisation, department - next to EVERY job title they hold
          and the group each one landed in. If a label looks wrong, this row
          shows whether the evidence record or the dictionary is the cause.

      Q2  ONE ROW PER EMPLOYMENT RECORD, for drilling into a person from Q1.
          Carries the similarity, the matched anchors and the decision source,
          so it shows WHY each title was read the way it was.

    THREE THINGS TO KNOW BEFORE READING IT.

    1. evidence_title IS THE RAW STRING, not the normalised one. The audience
       tables carry role_title_raw, while the dictionary is keyed on the
       normalised title. So these queries go through stg_role_records, which
       holds both and the title_key, rather than trying to re-normalise
       evidence_title - the normalisation applies an abbreviation list from
       dbt_project.yml and hand-rewriting it here would quietly disagree with
       the pipeline.

    2. ONE PERSON, ONE EVIDENCE RECORD. int_employment_scored keeps the most
       recent employment per person per role, so evidence_* describes one
       record while all_titles below describes every record they have. A person
       can perfectly well be confirmed on a 2019 record and hold four others.

    3. 5.7% OF THIS AUDIENCE IS WRONG and 15.2% is uncertain, measured in
       analyses/31 query 12. The wrong ones have no leadership word in any
       title; the uncertain ones have only `chair`, `director` or `head`. Both
       flags are computed below so they can be sorted to the top.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- Q1. ONE ROW PER PERSON.
-- ----------------------------------------------------------------------------
with audience as (

    select
        snid,
        contact_email,
        role_detail,
        role_label,
        role_final_score,
        country_code,
        is_current,
        evidence_title,
        evidence_org,
        evidence_dept,
        in_cdp,
        is_marketable
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'faculty_head'

),

their_records as (

    select
        r.snid,
        r.role_title_raw,
        r.role_title,
        r.organisation_raw,
        r.department_raw,
        r.is_current                            as record_is_current,
        r.start_date,
        r.end_date,
        d.title_group,
        d.decision_source,
        d.similarity,
        d.is_assigned
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
        using (title_key)
    where r.snid in (select snid from audience)

),

rolled as (

    select
        snid,
        count(*)                                                    as employment_records,
        countif(title_group = 'leadership' and is_assigned)         as leadership_records,
        /* what we matched, and what each title was read as */
        array_agg(
            struct(
                role_title_raw      as title,
                title_group         as we_read_it_as,
                decision_source     as decided_by,
                round(similarity, 3) as similarity,
                organisation_raw    as organisation,
                department_raw      as department,
                record_is_current   as is_current
            )
            order by (title_group = 'leadership') desc, record_is_current desc
            limit 12
        )                                                           as all_titles,

        /* the two flags from analyses/31 query 12 */
        logical_or(regexp_contains(role_title, r'(?i)(head of|\bdean\b|decano|dekan|'
                                             || r'rector|provost|chancellor|leiter|科主任|hod\b)'))
                                                                    as has_a_trusted_leadership_word,
        logical_or(regexp_contains(role_title, r'(?i)(\bchair\b|\bdirector\b|\bchief\b|'
                                             || r'\bhead\b|coordinator|coordenador|president|principal)'))
                                                                    as has_only_an_untrusted_one
    from their_records
    group by snid

)

select
    a.snid,
    a.contact_email,
    a.country_code,
    a.role_detail,
    a.role_label,
    round(a.role_final_score, 3)                as score,
    a.in_cdp,
    a.is_marketable,

    -- the evidence that put them in the audience
    a.evidence_title,
    a.evidence_org,
    a.evidence_dept,
    a.is_current                                as evidence_is_current,

    -- everything we matched for this person
    r.employment_records,
    r.leadership_records,
    r.all_titles,

    case
        when not r.has_a_trusted_leadership_word
             and not r.has_only_an_untrusted_one   then '*** NO LEADERSHIP WORD ANYWHERE ***'
        when not r.has_a_trusted_leadership_word   then 'UNCERTAIN - only chair/director/head'
        else                                            'ok - a title names a faculty-level post'
    end                                         as reading
from audience a
left join rolled r using (snid)
order by
    case
        when not r.has_a_trusted_leadership_word and not r.has_only_an_untrusted_one then 0
        when not r.has_a_trusted_leadership_word then 1
        else 2
    end,
    r.employment_records desc,
    a.snid;

-- ----------------------------------------------------------------------------
-- Q2. ONE ROW PER EMPLOYMENT RECORD. Put a snid from Q1 in the filter at the
--     bottom to drill into one person, or leave it out for the whole roster -
--     it is roughly 33,000 people and about 90,000 records, so export it
--     rather than reading it in the console.
-- ----------------------------------------------------------------------------
select
    r.snid,
    r.role_title_raw                            as title_as_written,
    r.role_title                                as title_normalised,
    d.title_group                               as we_read_it_as,
    d.decision_source                           as decided_by,
    round(d.similarity, 3)                      as similarity,
    d.matched_anchors                           as matched_against,
    d.is_assigned,
    d.frequency                                 as this_title_appears_n_times_in_orcid,
    r.organisation_raw                          as organisation,
    r.department_raw                            as department,
    r.country_code,
    r.start_date,
    r.end_date,
    r.is_current,
    r.recency_rank
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
    using (title_key)
where r.snid in (
    select distinct snid
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'faculty_head'
)
-- and r.snid = 'PUT A SNID HERE'
order by r.snid, r.recency_rank;
