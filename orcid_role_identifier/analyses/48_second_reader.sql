/*
    ============================================================================
    48. SECOND READER - two queries, nothing else
    ============================================================================
    Rewritten 2026-11-11 on Merve's instruction. The reading is done by an AI,
    so everything that existed to compare one human reader against another is
    gone: no rate comparison against the first reading, no Cohen's kappa, no
    disagreement listing.

    What is left is the part that cannot be done any other way.

      0  the verdict table, run once
      1  the sample. Change the declare block and run it again.

    The reader changes TWO values at the top of query 1: the audience, and the
    round number. Five rounds per audience gives 500 distinct people, and the
    rounds are disjoint by construction rather than by luck.
*/


-- ----------------------------------------------------------------------------
-- 0. SETUP. Run once.
--
--    Verdicts live in their own dataset, outside the pipeline's: nothing a
--    reviewer writes should be able to reach a dbt model, and nothing a dbt
--    rebuild does should be able to drop a reviewer's work.
--
--    The location MUST match the pipeline's datasets or no query can join
--    across the two - BigQuery does not join across regions. Read it off
--    dev_orcid_role_identifier_scoring in the console (Details -> Data
--    location). Do not guess it.
-- ----------------------------------------------------------------------------
create schema if not exists `dat-analytics-eng-ec869189.dev_orcid_role_review`
options (location = 'REGION_OF_THE_SCORING_DATASET');

create table if not exists
`dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts`
(
    audience     string  not null,   -- role_key, e.g. 'faculty_head'
    round_no     int64   not null,   -- which draw: 1 to 5
    snid         int64   not null,
    verdict      string  not null,   -- CORRECT | WRONG | UNSURE
    reason_code  string,             -- required unless verdict = CORRECT
    reason       string,             -- why, in the reader's own words
    read_by      string,             -- model name, or the person's name
    read_at      timestamp default current_timestamp()
)
cluster by audience, round_no;


-- ----------------------------------------------------------------------------
-- 1. THE SAMPLE. Change the two values below and run it again.
--
--    target_audience  one of:
--        faculty_head  hcp_broad  hcp_researcher  hcp_practitioner
--        hcp_administrator  researcher  lecturer  librarian  pharmacist
--
--    round_no  1 to 5. Each round is a DIFFERENT 100 people and the rounds
--    never overlap: one hash order is cut into consecutive blocks of 100, so
--    round 1 is people 1-100, round 2 is 101-200, and five rounds give 500
--    distinct people whose union is itself a single random sample of 500.
--    That union is the point - 500 rows per audience is the first figure in
--    this project that would carry a real confidence interval.
--
--    WHY A HASH AND NOT rand(). Ordering by farm_fingerprint is random with
--    respect to the data and REPEATABLE with respect to the person: the same
--    round returns the same 100 people every time, so a reading can be
--    re-run after a pipeline change to ask whether those same people are
--    still in the audience. rand() throws that away and the sample can never
--    be drawn again.
--
--    Librarian has only 666 CONFIRMED people, so rounds 1-5 would take 500 of
--    them. Two rounds is the sensible limit there.
-- ----------------------------------------------------------------------------
declare target_audience string default 'faculty_head';
declare round_no        int64  default 1;
declare sample_size     int64  default 100;

with ranked as (
    select
        r.snid,
        r.evidence_title                        as job_title,
        r.evidence_org                          as organisation,
        r.evidence_dept                         as department,
        r.country_code,
        r.is_current,
        r.title_group,
        r.discipline,
        round(r.role_final_score, 3)            as score,
        round(coalesce(r.role_score, 0.0), 2)   as axis_title,
        round(coalesce(r.org_score,  0.0), 2)   as axis_org,
        round(coalesce(r.dept_score, 0.0), 2)   as axis_dept,
        /*  How many axes are actually carrying this person. A person held up
            by ONE axis is the interesting case: nothing contradicts a wrong
            title or a wrong department there, and that is where the errors
            concentrate.  */
        (case when coalesce(r.role_score, 0.0) > 0 then 1 else 0 end
       + case when coalesce(r.org_score,  0.0) > 0 then 1 else 0 end
       + case when coalesce(r.dept_score, 0.0) > 0 then 1 else 0 end) as axes_carrying,
        row_number() over (
            order by farm_fingerprint(cast(r.snid as string))
        )                                       as hash_position
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    where r.role_key   = target_audience
      and r.role_label = 'CONFIRMED'
)
select
    * except (hash_position),
    /*  Paste-ready. Fill in the three quoted values and the row is an INSERT.
        It exists so that snid is never retyped or copied: transcribing an
        eight-digit id across a hundred rows is the one step in this process
        that silently goes wrong, and a verdict written against the wrong snid
        is worse than no verdict at all.  */
    format(
      "(%d,'%s',%d,'VERDICT','REASON_CODE','REASON','READ_BY'),",
      snid, target_audience, round_no
    )                                           as insert_row
from ranked
where hash_position between (round_no - 1) * sample_size + 1
                        and  round_no      * sample_size
order by hash_position
;
