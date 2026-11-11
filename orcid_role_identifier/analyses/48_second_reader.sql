/*
    ============================================================================
    48. SECOND READER - the queries, and the access the reader needs
    ============================================================================
    Written 2026-11-11, for an intern who has BigQuery and nothing else. The
    brief they read first is docs/INTERN-SECOND-READER.md; this file is the
    mechanics.

    WHY A SECOND READER AT ALL. Every accuracy figure this project reports was
    produced by one person reading a sample, and that person built the rules
    being tested. Exactly one of the nine has ever been reproduced: hcp_researcher
    read 90.0%, then 89.0% on a different 100 people. The other eight are single
    opinions presented as measurements, and the status document says so.

    ------------------------------------------------------------------------
    1. ACCESS THE READER NEEDS - nothing more than this
    ------------------------------------------------------------------------
    READ (BigQuery Data Viewer), one table only:

        dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles

    That one table carries the job title, organisation, department, the three
    axis scores and the audience label, which is everything a reading needs.
    Nothing in it is a per-person identifier beyond snid, which is an internal
    key rather than a name or an address.

    WRITE (BigQuery Data Editor) on ONE new dataset of their own:

        dat-analytics-eng-ec869189.dev_orcid_role_review

    Created by query 0 below. Their verdicts live there. Deliberately NOT in
    the pipeline's own datasets: nothing a reviewer writes should be able to
    reach a dbt model, and nothing dbt rebuilds should be able to drop a
    reviewer's work.

    DO NOT GRANT: write access to any dev_orcid_role_identifier_* dataset, and
    no repository access. The reader does not need either, and seed files are
    the one place where a single row moves nine audiences at once.

    ------------------------------------------------------------------------
    2. WHAT THIS FILE CANNOT DO YET, STATED PLAINLY
    ------------------------------------------------------------------------
    The first reader's verdicts were never stored per person - only the totals
    were, in docs/open-questions.md, because per-person rows are deliberately
    kept out of the repository. So the FIRST comparison is a comparison of
    RATES, not of rows: "you read 100 people and got 86%, the first reader read
    100 different people and got 83.3%".

    That is weaker than row-level agreement and it is what we have. It is also
    exactly how hcp_researcher was reproduced, so it is not worthless.

    From this file onward both readers write into the same table, so the NEXT
    comparison is row-level: query 5 computes Cohen's kappa and lists every row
    the two readers scored differently. Getting to that state is half the
    reason this file exists.
    ------------------------------------------------------------------------
*/


-- ----------------------------------------------------------------------------
-- 0. SETUP. Run once. The reader runs this themselves, in their own dataset.
--
--    The grain is (reader, audience, snid): one verdict per person per
--    audience per reader, so two readers coexist and a reader can revise
--    their own verdict without touching the other's.
-- ----------------------------------------------------------------------------
/*  The location MUST match the pipeline's own datasets, or no query can join
    across the two - BigQuery does not join across regions. Read it off
    dev_orcid_role_identifier_scoring in the console (Details -> Data location)
    and put it below. Do not guess it.  */
create schema if not exists `dat-analytics-eng-ec869189.dev_orcid_role_review`
options (location = 'REGION_OF_THE_SCORING_DATASET');

create table if not exists
`dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts`
(
    reader        string  not null,   -- who read it. free text, be consistent
    audience      string  not null,   -- role_key, e.g. 'faculty_head'
    sample_tag    string  not null,   -- which draw, e.g. 'reader2-2026-11-11'
    snid          int64   not null,
    verdict       string  not null,   -- CORRECT | WRONG | UNSURE
    reason_code   string,             -- required unless verdict = CORRECT
    note          string,             -- free text, encouraged on UNSURE
    read_at       timestamp default current_timestamp()
)
cluster by audience, reader;


-- ----------------------------------------------------------------------------
-- 1. THE READING WORKSHEET. Change ONE word and run it again.
--
--    target_audience takes one of:
--      faculty_head  hcp_broad  hcp_researcher  hcp_practitioner
--      hcp_administrator  researcher  lecturer  librarian  pharmacist
--
--    WHY THE HASH. Ordering by farm_fingerprint makes the sample random with
--    respect to the data and REPEATABLE with respect to the person: the same
--    100 people come back every time this is run with the same tag. That is
--    what lets two readers read the same rows, and what lets a reading be
--    re-run after a pipeline change to see whether the same people are still
--    there.
--
--    sample_tag is mixed INTO the hash, so changing the tag draws a different
--    100 people. Leave it alone to read the same sample as another reader;
--    change it to draw a fresh one.
-- ----------------------------------------------------------------------------
declare target_audience string default 'faculty_head';
declare sample_tag      string default 'reader2-2026-11-11';
declare sample_size     int64  default 100;

select
    r.snid,
    r.evidence_title                        as job_title,
    r.evidence_org                          as organisation,
    r.evidence_dept                         as department,
    r.country_code,
    r.is_current,
    /*  The decision's own trail. A person carried by ONE axis is the
        interesting case: nothing contradicts a wrong title or a wrong
        department there, and that is where errors concentrate.  */
    r.title_group,
    r.discipline,
    round(r.role_final_score, 3)            as score,
    round(coalesce(r.role_score, 0.0), 2)   as axis_title,
    round(coalesce(r.org_score,  0.0), 2)   as axis_org,
    round(coalesce(r.dept_score, 0.0), 2)   as axis_dept,
    (case when coalesce(r.role_score, 0.0) > 0 then 1 else 0 end
   + case when coalesce(r.org_score,  0.0) > 0 then 1 else 0 end
   + case when coalesce(r.dept_score, 0.0) > 0 then 1 else 0 end) as axes_carrying,
    /*  Paste-ready: fill in the two quoted values and the row becomes an
        INSERT. Saves retyping snid, which is the one thing that must not be
        mistyped.  */
    format(
      "('%s','%s','%s',%d,'VERDICT','REASON',NULL),",
      'READER_NAME', target_audience, sample_tag, r.snid
    )                                       as insert_row
from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
where r.role_key   = target_audience
  and r.role_label = 'CONFIRMED'
qualify row_number() over (
    order by farm_fingerprint(concat(cast(r.snid as string), '|', sample_tag))
) <= sample_size
;


-- ----------------------------------------------------------------------------
-- 2. RECORDING THE VERDICTS.
--
--    Paste the insert_row column from query 1, replace VERDICT and REASON in
--    each line, drop the trailing comma on the last line. One statement for
--    all 100 rows - a hundred separate INSERTs costs a hundred times as much
--    and is a hundred chances to mistype a snid.
--
--    verdict     CORRECT | WRONG | UNSURE
--    reason_code title_wrong | field_wrong | uninformative | ambiguous_word
--                | ended_role | too_junior | language | other
--                (NULL when the verdict is CORRECT)
-- ----------------------------------------------------------------------------
insert into `dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts`
    (reader, audience, sample_tag, snid, verdict, reason_code)
values
    ('READER_NAME','faculty_head','reader2-2026-11-11', 12345678, 'CORRECT', NULL),
    ('READER_NAME','faculty_head','reader2-2026-11-11', 12345679, 'WRONG',   'title_wrong'),
    ('READER_NAME','faculty_head','reader2-2026-11-11', 12345680, 'UNSURE',  'ambiguous_word')
;


-- ----------------------------------------------------------------------------
-- 3. THE READER'S OWN RESULT, and the figure to report.
--
--    accuracy_of_decided EXCLUDES unsure, which is how every figure in the
--    status document is computed - so this is the number that compares
--    directly against 83.3%, 90.6% and the rest.
--
--    unsure_rate is reported BESIDE it and never folded in. In faculty_head
--    the first reader's unsure rate was about a third of the sample, and that
--    third is the open marketing question, not noise.
-- ----------------------------------------------------------------------------
select
    audience,
    reader,
    count(*)                                            as rows_read,
    countif(verdict = 'CORRECT')                        as correct,
    countif(verdict = 'WRONG')                          as wrong,
    countif(verdict = 'UNSURE')                         as unsure,
    round(safe_divide(countif(verdict = 'CORRECT'),
                      countif(verdict in ('CORRECT','WRONG'))) * 100, 1)
                                                        as accuracy_of_decided,
    round(safe_divide(countif(verdict = 'UNSURE'), count(*)) * 100, 1)
                                                        as unsure_rate,
    /*  The standard error on a proportion, so nobody reports a 5-point move
        at n=100 as a real one. At 90% and n=100 it is about 3 points, which
        means two readings 6 points apart are not separable.  */
    round(sqrt(
        safe_divide(countif(verdict = 'CORRECT'),
                    countif(verdict in ('CORRECT','WRONG')))
      * (1 - safe_divide(countif(verdict = 'CORRECT'),
                         countif(verdict in ('CORRECT','WRONG'))))
      / nullif(countif(verdict in ('CORRECT','WRONG')), 0)
    ) * 100, 1)                                         as std_error_points
from `dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts`
group by audience, reader
order by audience, reader
;


-- ----------------------------------------------------------------------------
-- 3a. BY CAUSE - the more useful half of the output.
--
--    "11 wrong out of 100" says almost nothing. "7 of the 11 are field_wrong
--    in veterinary departments" says what to fix. The department bug that
--    moved hcp_researcher by 5 points was found this way, not from the
--    percentage.
-- ----------------------------------------------------------------------------
select
    audience,
    verdict,
    coalesce(reason_code, '(none)')                     as reason_code,
    count(*)                                            as people,
    round(count(*) / sum(count(*)) over (partition by audience) * 100, 1)
                                                        as pct_of_sample,
    string_agg(note, ' | ' order by note limit 5)       as example_notes
from `dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts`
where verdict in ('WRONG', 'UNSURE')
group by audience, verdict, reason_code
order by audience, people desc
;


-- ----------------------------------------------------------------------------
-- 4. RATE COMPARISON against the first reading.
--
--    The first reader's figures are hard-coded because they were never stored
--    per person - see section 2 of this file's header. Each is 100 people
--    except librarian, where all 692 were read.
--
--    HOW TO READ THE VERDICT COLUMN. Two readings of 100 people, each with a
--    standard error near 3 points, are not separable unless they differ by
--    more than about 8 points. So 'consistent' does not mean the two readers
--    agree row by row - it means the two rates are not distinguishable, which
--    is the strongest claim this comparison can support.
-- ----------------------------------------------------------------------------
with first_reading as (
    select 'faculty_head'      as audience, 83.3 as rate_1 union all
    select 'hcp_broad',               90.6 union all
    select 'hcp_practitioner',        93.4 union all
    select 'hcp_researcher',          94.3 union all
    select 'hcp_administrator',       94.9 union all
    select 'pharmacist',              95.7 union all
    select 'librarian',               98.5 union all
    select 'lecturer',                98.7 union all
    select 'researcher',              99.0
),
second_reading as (
    select
        audience,
        round(safe_divide(countif(verdict = 'CORRECT'),
                          countif(verdict in ('CORRECT','WRONG'))) * 100, 1) as rate_2,
        countif(verdict in ('CORRECT','WRONG'))                             as decided_2
    from `dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts`
    group by audience
)
select
    f.audience,
    f.rate_1,
    s.rate_2,
    s.decided_2,
    round(s.rate_2 - f.rate_1, 1)                       as gap_points,
    case
        when s.rate_2 is null                   then 'not read yet'
        when abs(s.rate_2 - f.rate_1) <= 8.0    then 'consistent - rates not separable at n=100'
        else 'DIVERGES - investigate before quoting either figure'
    end                                                 as verdict
from first_reading f
left join second_reading s using (audience)
order by f.rate_1
;


-- ----------------------------------------------------------------------------
-- 5. ROW-LEVEL AGREEMENT. Only works once TWO readers have written verdicts
--    on the SAME sample_tag. Not usable for the first reading; usable from
--    the second onward, which is the point of storing verdicts at all.
--
--    Cohen's kappa rather than raw agreement, because raw agreement is
--    inflated by the base rate: on an audience that is 99% correct, two
--    readers who both say CORRECT to everything agree 99% of the time while
--    measuring nothing. Kappa subtracts the agreement chance alone would give.
--
--      < 0.20  no better than chance - the rubric is not usable as written
--      0.21-0.40  poor        0.41-0.60  moderate
--      0.61-0.80  good        > 0.80     strong
-- ----------------------------------------------------------------------------
declare reader_a string default 'READER_A';
declare reader_b string default 'READER_B';

with paired as (
    select
        a.audience,
        a.snid,
        a.verdict      as verdict_a,
        b.verdict      as verdict_b,
        a.reason_code  as reason_a,
        b.reason_code  as reason_b
    from `dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts` a
    join `dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts` b
      on  a.audience   = b.audience
      and a.snid       = b.snid
      and a.sample_tag = b.sample_tag
    where a.reader = reader_a
      and b.reader = reader_b
),
counts as (
    select
        audience,
        count(*)                                                as n,
        countif(verdict_a = verdict_b)                          as agreed,
        /*  expected agreement from the marginals: sum over each class of
            P(a picks it) * P(b picks it)  */
        sum(case when verdict_a = 'CORRECT' then 1 else 0 end) / count(*)
          * sum(case when verdict_b = 'CORRECT' then 1 else 0 end) / count(*)
      + sum(case when verdict_a = 'WRONG'   then 1 else 0 end) / count(*)
          * sum(case when verdict_b = 'WRONG'   then 1 else 0 end) / count(*)
      + sum(case when verdict_a = 'UNSURE'  then 1 else 0 end) / count(*)
          * sum(case when verdict_b = 'UNSURE'  then 1 else 0 end) / count(*)
                                                                as p_expected
    from paired
    group by audience
)
select
    audience,
    n,
    agreed,
    round(agreed / n, 3)                                        as p_observed,
    round(p_expected, 3)                                        as p_expected,
    round((agreed / n - p_expected) / (1 - p_expected), 3)       as cohens_kappa
from counts
order by audience
;


-- ----------------------------------------------------------------------------
-- 5a. THE DISAGREEMENTS THEMSELVES - the real output of the whole exercise.
--
--    A row two careful readers score differently is usually not an error. It
--    is a place where the DEFINITION is unclear, and definitions belong to
--    marketing. Every row this returns is a candidate question.
--
--    Read the rows here; do not export them. Job title + organisation +
--    department together point at a real ORCID profile, which is why
--    validation_samples/ was removed from the repository on 2026-11-05.
--    What leaves BigQuery is the pattern, not the people.
-- ----------------------------------------------------------------------------
declare reader_a_d string default 'READER_A';
declare reader_b_d string default 'READER_B';

select
    a.audience,
    r.evidence_title                        as job_title,
    r.evidence_org                          as organisation,
    r.evidence_dept                         as department,
    r.title_group,
    r.discipline,
    round(r.role_final_score, 3)            as score,
    a.verdict                               as verdict_a,
    a.reason_code                           as reason_a,
    b.verdict                               as verdict_b,
    b.reason_code                           as reason_b,
    concat(coalesce(a.note, ''), ' // ', coalesce(b.note, '')) as notes
from `dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts` a
join `dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts` b
  on  a.audience   = b.audience
  and a.snid       = b.snid
  and a.sample_tag = b.sample_tag
join `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
  on  r.snid     = a.snid
  and r.role_key = a.audience
where a.reader  = reader_a_d
  and b.reader  = reader_b_d
  and a.verdict != b.verdict
order by a.audience, score desc
;
