/*
    ============================================================================
    33. DID THE ROSTER REVIEW LAND, AND WHAT DID IT COST
    ============================================================================
    On 30 October Merve read the full faculty_head roster and named two families
    that must not be in the audience:

      "Fellow ve asistan rolleri - kesinlikle girmemeli"
          vice chancellor's fellow, chancellor's fellow, dean's prize fellow,
          director's fellow, chief minister fellow, assistant to the dean,
          dean assistant, dean's office, department assistant, department
          secretary, department member, chief assistant

      "Gurultu ve anlamsiz eslesmeler"
          pro, de, di, dev, deq, des, degree, vice, deputy, executive,
          committee, department, governance, leadership, public university,
          department of biology, ph d stdent, ed d graduate, proessor,
          professot, profossor, proff

    108 rows went into role_title_overrides, and NOT all of them are rejections.
    The mechanism was chosen per family, because what removes a title from
    faculty_head is not always a rejection and the dictionary has to stay true:

        24  -> researcher_early    a fellowship NAMED AFTER an office is not
                                   that office. `fellow` precedent, 29 Oct
        21  -> support_technical   assistants and secretaries are real jobs,
                                   just not ones any audience is built for -
                                   which is what that group holds
        14  -> teaching_academic   `proessor`, `professot`, `profossor` are
                                   MISSPELLINGS of an academic rank, not
                                   meaningless strings. Rejecting them would
                                   throw away a reading we are sure of and cost
                                   Lecturer a real person
         3  -> teaching_academic   `chief assistant` is the Bulgarian academic
                                   rank glaven asistent, as Merve noted
         1  -> student             `ph d stdent`
        48  -> REJECT              names no profession at all: pro, de, di,
                                   committee, governance, leadership, a bare
                                   department name

    EVERY ONE CARRIES [pre-emptive], AND THAT IS DELIBERATE AND TEMPORARY.
    The rows were written from a roster read by eye rather than from a query, so
    the exact normalised spelling is not guaranteed - `chancellors fellow` and
    `chancellor s fellow` are different dictionary entries and only one of them
    exists. assert_overrides_take_effect fails the build on a row that matches
    nothing, which is exactly what it is for; but failing on a spelling would
    hide the hundred-odd rows that are right. Query 1 below says which landed.
    Delete the ones that did not, take the marker off the rest, and the guard is
    back to full strength after one build.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- 1. WHICH OF THE 108 LANDED. Run this first. Anything in the MISSED list is a
--    spelling that does not exist in ORCID - delete the row, do not re-guess it.
-- ----------------------------------------------------------------------------
with mine as (
    select title, title_group as intended_group, decision
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.role_title_overrides`
    where reviewed_at = '2026-10-30'
      and contains_substr(note, '[pre-emptive]')
)

select
    case when d.title_key is null then '*** MISSED - delete this row ***'
         else 'landed' end                      as outcome,
    m.decision,
    coalesce(m.intended_group, 'REJECT')        as intended_group,
    count(*)                                    as rows,
    sum(coalesce(d.frequency, 0))               as records,
    array_agg(m.title order by d.frequency desc nulls last limit 15) as titles
from mine m
left join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
    on d.title = m.title
group by outcome, m.decision, intended_group
order by outcome, records desc;

-- ----------------------------------------------------------------------------
-- 2. WHAT IT COST faculty_head, AND WHAT IT COST EVERYONE ELSE.
--
--    The point of choosing a group per family rather than rejecting everything
--    is that nobody should lose a correct label on the way out of this audience.
--    So this reports both sides: people who leave faculty_head, and people who
--    arrive somewhere they belong.
-- ----------------------------------------------------------------------------
with touched as (
    select d.title_key, d.title, d.title_group, d.decision_source, d.is_assigned, d.frequency
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_seeds.role_title_overrides` o
        on o.title = d.title
    where o.reviewed_at = '2026-10-30'
      and contains_substr(o.note, '[pre-emptive]')
),

holders as (
    select distinct r.snid, t.title_group, t.is_assigned
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
    join touched t using (title_key)
)

select
    coalesce(h.title_group, 'rejected - no group') as now_reads_as,
    h.is_assigned,
    count(distinct h.snid)                         as people_holding_one,
    count(distinct fh.snid)                        as still_in_faculty_head,
    count(distinct lec.snid)                       as in_lecturer,
    count(distinct res.snid)                       as in_researcher
from holders h
left join (select distinct snid from
    `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'faculty_head') fh using (snid)
left join (select distinct snid from
    `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'lecturer') lec using (snid)
left join (select distinct snid from
    `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'researcher') res using (snid)
group by now_reads_as, h.is_assigned
order by people_holding_one desc;

-- ----------------------------------------------------------------------------
-- 3. AND THE ACCURACY AGAIN. 5.7% of this audience had no leadership word in
--    any title. These 108 rows were aimed straight at that figure, so it is the
--    one number that says whether the review was worth the reading.
--    Same three buckets as analyses/31 query 12.
-- ----------------------------------------------------------------------------
with survey as (
    select lower(trim(email)) as email, survey_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
    where map_status = 'mapped'
),

ours as (
    select distinct snid, lower(trim(contact_email)) as email
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'faculty_head' and role_label = 'CONFIRMED'
      and contact_email is not null
),

disagreed as (
    select o.snid
    from ours o
    join survey s using (email)
    group by o.snid
    having logical_or(s.survey_group = 'leadership') = false
),

judged as (
    select
        d.snid,
        logical_or(regexp_contains(r.role_title,
            r'(?i)(head of|\bdean\b|decano|dekan|rector|provost|chancellor|'
         || r'leiter|科主任|hod\b)'))                                   as trusted,
        logical_or(regexp_contains(r.role_title,
            r'(?i)(\bchair\b|\bdirector\b|\bchief\b|\bhead\b|coordinator|'
         || r'coordenador|president|principal)'))                      as untrusted
    from disagreed d
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
         using (snid)
    group by d.snid
)

select
    case
        when trusted   then 'CORRECT - a title names a faculty-level post'
        when untrusted then 'UNCERTAIN - only chair/director/head'
        else                '*** OUR ERROR - no leadership word at all  (was 101, 6.5%) ***'
    end                                                     as reading,
    count(*)                                                as people,
    round(count(*) / sum(count(*)) over (), 3)              as share
from judged
group by reading
order by people desc;

/*
    ============================================================================
    MEASURED 2026-11-02. 106 OF 108 LANDED, AND THE MARKER IS OFF.
    ============================================================================
        landed  REJECT              47 rows   4,231 records
                researcher_early    23         1,057
                support_technical   21           817
                teaching_academic   14         1,017
                student              1             4
                                   ---         -----
                                   106         7,126

        missed  vice chancellors fellow     deleted
                department of marketing     deleted

    THE TWO MISSES ARE THE EXACT RISK THE MARKER WAS FOR, and both are spelling
    rather than judgement. `vice-chancellors fellow` and `vice chancellors
    senior fellow` both exist; the plain unhyphenated `vice chancellors fellow`
    does not. `department of marketing` is not a title anybody wrote, though
    eight other bare department names are. Both rows are deleted rather than
    re-guessed, and [pre-emptive] is off the other 106 - so
    assert_overrides_take_effect is back at full strength and will fail the
    build on the next dead row, which is what it is for.

    98.1% of a list written by eye matched exactly. Worth recording, because it
    prices the method: reading a roster and writing overrides from it is
    reliable enough to be worth doing, and not reliable enough to do without a
    guard.

    WHAT 7,126 RECORDS DOES NOT TELL US. Four of the five families moved to a
    group rather than being rejected, so most of those records did not leave the
    dictionary - they left faculty_head and landed somewhere they belong. Query
    2 is what reports that, and query 3 the 6.5% these rows were aimed at.
    ============================================================================
*/

/*
    ============================================================================
    QUERIES 2 AND 3 CAME BACK 2026-11-03. THE DICTIONARY MOVED; THE ERROR RATE
    DID NOT.
    ============================================================================
    QUERY 2 - the cost, both sides. 478 people held one of the 106 titles:

        now reads as        held by  still in faculty_head  left
        leadership/REJECT      289          161             128
        researcher_early        66           37              29
        support_technical       65           38              27
        teaching_academic       57           40              17
        student                  1            1               0
                               ---          ---             ---
                               478          277             201

    So 201 people left faculty_head and 277 stayed - they hold a real leadership
    title as well as the one we removed. The same pattern as every correction
    this project has made.

    A LIMIT ON READING THE LAST TWO COLUMNS. 47 of the people whose fellowship
    moved to researcher_early are in the Researcher audience and 35 in Lecturer,
    but those memberships may well come from their other employment records.
    The query cannot attribute them to the move and neither can I.

    QUERY 3 - AND THIS IS THE FINDING. The error rate did not improve:

        CORRECT - a title names a faculty-level post   1,185   76.3%
        UNCERTAIN - only chair/director/head             267   17.2%
        OUR ERROR - no leadership word at all            102    6.6%   <-- was 101, 6.5%

    106 corrections, 7,126 records, 201 people out of the audience, and the
    measured error moved by ONE PERSON - in the wrong direction, which at this
    sample size is noise either way.

    WHY, AND IT IS THE FIFTH TIME. The 102 people with no leadership word are
    not in faculty_head through the titles we removed. They are there through
    SOME OTHER title, and the titles we removed were mostly held by people who
    also hold a real leadership title - 277 of 478 of them. Cleaning the
    dictionary and cleaning the audience are different jobs. Measured now on
    `associate`, on pharmacist (91 people), on the Lecturer corrections (one
    person), on the compound patterns (one person) and here.

    WHICH MEANS THE ROSTER REVIEW WAS WORTH DOING FOR THE DICTIONARY AND NOT
    FOR THIS NUMBER. 7,126 records are read correctly that were not before, and
    that is permanent and feeds every audience built from here. But to move the
    6.6% we have to look at what those 102 people are actually in faculty_head
    FOR - which is their evidence_title, not the titles we happened to review.
    Query 4 asks that, and it is the only query left that can move the figure.
    ============================================================================
*/

-- ----------------------------------------------------------------------------
-- 4. THE 102. What is each of them in faculty_head FOR.
--
--    Not their other titles - the one the pipeline used as evidence. Grouped,
--    so a repeated cause shows up as a row rather than as 102 separate
--    sentences. Anything with a count above about five is a fixable family;
--    the long tail of ones and twos is the cost of free text and will not be
--    fixed by reading more titles.
-- ----------------------------------------------------------------------------
with survey as (
    select lower(trim(email)) as email, survey_group
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_raw.survey_self_declared_roles`
    where map_status = 'mapped'
),

ours as (
    select distinct snid, lower(trim(contact_email)) as email,
           evidence_title, evidence_org, evidence_dept, role_final_score
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_presentation.fct_role_audience`
    where role_key = 'faculty_head' and role_label = 'CONFIRMED'
      and contact_email is not null
),

the_102 as (
    select o.snid, o.evidence_title, o.evidence_dept, o.role_final_score
    from ours o
    join survey s using (email)
    group by o.snid, o.evidence_title, o.evidence_dept, o.role_final_score
    having logical_or(s.survey_group = 'leadership') = false
       and logical_or(regexp_contains(lower(o.evidence_title),
               r'(head of|\bdean\b|decano|dekan|rector|provost|chancellor|leiter|hod\b)')) = false
),

their_titles as (
    select
        t.snid,
        t.evidence_title,
        t.evidence_dept,
        round(t.role_final_score, 3)                            as score,
        array_agg(distinct r.role_title ignore nulls limit 6)   as every_title_they_have
    from the_102 t
    join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_staging.stg_role_records` r
         using (snid)
    /* NOT t.score - that is this SELECT's own alias, and BigQuery will not
       accept it qualified. Group by the underlying column. */
    group by t.snid, t.evidence_title, t.evidence_dept, t.role_final_score
)

select
    evidence_title              as what_put_them_in_the_audience,
    count(*)                    as people,
    round(avg(score), 3)        as avg_score,
    array_agg(distinct evidence_dept ignore nulls limit 3)       as departments,
    any_value(every_title_they_have)                            as example_full_title_list
from their_titles
group by what_put_them_in_the_audience
order by people desc, what_put_them_in_the_audience;
