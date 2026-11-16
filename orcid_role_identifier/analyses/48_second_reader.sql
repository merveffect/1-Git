-- ============================================================================
-- SECOND READER - A RUNBOOK YOU CAN PASTE INTO BIGQUERY
-- ============================================================================
-- Everything you need is in this one file. Read the comments top to bottom,
-- then run STEP 1 once and STEP 2 as many times as the plan below says.
--
-- ----------------------------------------------------------------------------
-- WHY THIS JOB EXISTS
-- ----------------------------------------------------------------------------
-- This pipeline reads ORCID, the public researcher registry, and sorts about
-- twelve million employment records into nine marketing audiences - Researcher,
-- Lecturer, Librarian, Pharmacist, Head of Faculty and four healthcare
-- audiences.
--
-- ORCID has NO profession field. There is nothing to compare our answer
-- against automatically, and no ground truth anywhere in this problem. So the
-- only quality measure that exists is somebody reading a sample - pull the
-- people an audience claims, look at the job title, employer and department
-- each one typed, and say whether the label is right.
--
-- Every accuracy figure we report today comes from ONE reader going through
-- ONE sample of 100 per audience. Your job produces the second reading, and at
-- five rounds per audience it produces 500 rows instead of 100 - which is the
-- first figure in this project that would carry a real confidence interval.
--
-- You are not looking for bugs. You are a second measuring instrument.
--
-- ----------------------------------------------------------------------------
-- WHAT YOU DO, IN FIVE STEPS
-- ----------------------------------------------------------------------------
--   STEP 1   Create the verdict table. Once, ever.
--   STEP 2   Pull 100 people. Change two values at the top and run it.
--   STEP 3   Send those 100 rows to the AI with the prompt in this file.
--   STEP 4   Write the AI's verdicts back into the table.
--   STEP 5   Repeat STEP 2 to STEP 4 with the next round number.
--
-- THE PLAN. Five rounds per audience, in this order. Stop whenever you run out
-- of time - one audience done properly is worth more than four done quickly.
--
--   1  faculty_head        our figure 83.3 percent - the weakest audience,
--                          and the one marketing is deciding about this week
--   2  hcp_broad           90.6 percent - the largest healthcare audience,
--                          93,377 reachable people
--   3  hcp_researcher      94.3 percent - read three times by one reader, so
--                          it is the only audience with a reproduced figure
--   4  hcp_practitioner    93.4 percent - its high-similarity band has never
--                          been examined by anybody
--
-- Those percentages are there so you know which audience matters. They are NOT
-- a target. If you come back and say faculty_head is 70 percent, that is a
-- better outcome than coming back with 83.
--
-- ============================================================================
-- THE RUBRIC - HOW TO JUDGE A ROW
-- ============================================================================
-- Judge against the rule, not against your own sense of the job. The question
-- is never "is this a good person to email". It is "does the evidence in this
-- row satisfy this audience's definition".
--
--   researcher          The JOB TITLE names research work - researcher,
--                       scientist, postdoc, research fellow, principal
--                       investigator. THE FIELD IS IRRELEVANT. A plant
--                       pathologist and an astrophysicist are both correct.
--
--   lecturer            The job title names a teaching or academic post -
--                       professor, lecturer, docent, teaching assistant.
--
--   librarian           The job title contains a library word.
--
--   pharmacist          The job title names a pharmacist. A pharmacology
--                       academic is NOT one.
--
--   hcp_practitioner    The title names a clinician who treats patients AND
--                       the department is a human-health field.
--
--   hcp_researcher      The title names research AND the department is a
--                       human-health field. PATIENT CONTACT IS NOT REQUIRED.
--
--   hcp_administrator   The title names leadership AND the department is a
--                       human-health field. PATIENT CONTACT IS NOT REQUIRED.
--
--   hcp_broad           Any clinical signal, but a clinical JOB TITLE is
--                       mandatory - a department alone is not enough.
--
--   faculty_head        The job title names a FACULTY-LEVEL post - dean, head
--                       of department, rector, pro-vice-chancellor - at an
--                       educational institution.
--
-- ONE THING TO CHECK WITH MERVE BEFORE YOU START. A change is waiting to be
-- built in which a BIOMEDICAL department also counts for hcp_researcher, and
-- in which a title naming two jobs can belong to two audiences. Ask which
-- build you are reading, because the rubric for hcp_researcher differs between
-- them.
--
-- ----------------------------------------------------------------------------
-- THE REASON CODES - pick exactly one for every WRONG or UNSURE
-- ----------------------------------------------------------------------------
--   title_wrong      The job title does not name this profession at all.
--   field_wrong      The department is not in this audience's field.
--   uninformative    The title carries no occupational information at all -
--                    dr, md, fellow, member.
--   ambiguous_word   The title's key word has two meanings. Consultant is a
--                    hospital specialist in Britain and Ireland and a business
--                    adviser in the United States. Fellow is a physician in
--                    subspecialty training in America and a researcher in
--                    Britain. Director can be anything.
--   ended_role       The title records a post that has FINISHED - emeritus,
--                    retired, "professor 2014-2018".
--   too_junior       A student or trainee where the audience means a qualified
--                    professional.
--   language         The title is in a language you cannot read with
--                    confidence. USE THIS FREELY. Guessing is worse than
--                    flagging, and this project has been caught four separate
--                    times assuming an English reading of a non-English title.
--   other            Anything else. Explain it in the reason column.
--
-- MEASURING BY CAUSE IS THE WHOLE VALUE OF THIS EXERCISE.
-- "11 wrong out of 100" tells us almost nothing.
-- "7 of the 11 are field_wrong, all in veterinary departments" tells us
-- exactly what to fix. It was that kind of breakdown, and not the percentage,
-- that found a department bug which moved one audience by five points.
-- THE REASON CODE MATTERS MORE THAN THE VERDICT.
--
-- ----------------------------------------------------------------------------
-- THREE RULES THAT MATTER MORE THAN THEY LOOK
-- ----------------------------------------------------------------------------
-- 1. UNSURE IS A REAL VERDICT, NOT A FAILURE. It is excluded from the
--    percentage and reported separately beside it. In faculty_head a third of
--    the first sample was unsure, and that third is precisely the question
--    marketing has to answer. If it cannot be decided in about a minute, mark
--    UNSURE and move on.
--
-- 2. JUDGE WHAT THE PERSON TYPED, NOT WHAT THEY PROBABLY DO. "They are
--    probably a doctor" is not evidence. A job title naming a clinical role is.
--
-- 3. WHETHER THE PERSON IS STILL IN THAT JOB IS NOT WHAT YOU ARE JUDGING.
--    Somebody who was a researcher in 2010 and works in a bank today is still
--    CORRECT for researcher - marketing already decided that a researcher is a
--    profession you have rather than a post you hold. Only mark ended_role
--    when the TITLE ITSELF says the post has ended.
--
-- ----------------------------------------------------------------------------
-- ONE HARD RULE ABOUT THE DATA
-- ----------------------------------------------------------------------------
-- Job title plus organisation plus department together identify a real
-- person's public ORCID profile. A folder of sample rows was deleted from the
-- repository on 2026-11-05 for exactly that reason.
--
-- So these rows do not go into a spreadsheet shared outside the team, into
-- Slack, into the git repository, or into any document. Verdicts live in the
-- BigQuery table beside the data they describe, and what leaves BigQuery is
-- COUNTS AND REASONS - "7 wrong, 5 of them field_wrong" - never the people.
--
-- If the rows are being sent to an AI, that is a disclosure to whatever
-- service runs it. Confirm with Merve which tool is approved before STEP 3.
-- ============================================================================


-- ============================================================================
-- STEP 1 - CREATE THE VERDICT TABLE. RUN THIS ONCE, EVER.
-- ============================================================================
-- The verdicts live in their own dataset, outside the pipeline's. That is
-- deliberate and it protects both sides - nothing a reviewer writes can reach a
-- dbt model, and nothing a dbt rebuild does can drop a reviewer's work.
--
-- BEFORE YOU RUN IT, SET THE LOCATION. It must match the pipeline's datasets
-- or no query can ever join across the two, because BigQuery does not join
-- across regions. Read it off dev_orcid_role_identifier_scoring in the console
-- under Details then Data location, and paste it below. Do not guess it.
--
-- Two columns record the reason, on purpose. reason_code is from the fixed
-- list above and can be counted. reason is free text and can be read. We want
-- both - a count tells you how big a problem is, a sentence tells you what it
-- is.
-- ----------------------------------------------------------------------------
create schema if not exists `dat-analytics-eng-ec869189.dev_orcid_role_review`
options (location = 'REGION_OF_THE_SCORING_DATASET');

create table if not exists
`dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts`
(
    audience     string  not null,   -- role_key, for example 'faculty_head'
    round_no     int64   not null,   -- which draw this came from, 1 to 5
    -- STRING, NOT INT64. snid's type is not declared in any contract in
    -- this project and it arrives from the source as a STRING. Matching
    -- it here means the verdict table and fct_researcher_roles join
    -- without a cast on either side.
    snid         string  not null,   -- the person, from the sample
    verdict      string  not null,   -- CORRECT or WRONG or UNSURE
    reason_code  string,             -- required unless the verdict is CORRECT
    reason       string,             -- why, in the reader's own words
    read_by      string,             -- the model name, or the person's name
    read_at      timestamp default current_timestamp()
)
cluster by audience, round_no;


-- ============================================================================
-- STEP 2 - PULL 100 PEOPLE. CHANGE THE TWO VALUES BELOW AND RUN IT.
-- ============================================================================
-- target_audience is one of:
--     faculty_head  hcp_broad  hcp_researcher  hcp_practitioner
--     hcp_administrator  researcher  lecturer  librarian  pharmacist
--
-- round_no runs 1 to 5. EACH ROUND IS A DIFFERENT 100 PEOPLE AND THE ROUNDS
-- NEVER OVERLAP. One hash order is cut into consecutive blocks, so round 1 is
-- people 1 to 100, round 2 is 101 to 200, and five rounds give 500 distinct
-- people whose union is itself a single random sample of 500. That union is
-- the point - 100 rows cannot separate a 5-point move from noise, and 500 can.
--
-- WHY A HASH AND NOT rand(). Ordering by farm_fingerprint is random with
-- respect to the data and REPEATABLE with respect to the person - the same
-- round returns the same 100 people every time, so a reading can be re-run
-- after a pipeline change to ask whether those same people are still in the
-- audience. rand() throws that away and the sample can never be drawn again.
--
-- librarian has only 666 CONFIRMED people, so five rounds would take 500 of
-- them. Two rounds is the sensible limit there.
--
-- WHAT TO LOOK AT IN THE OUTPUT. axes_carrying is how many of the three
-- signals - title, organisation, department - are actually holding this person
-- in the audience. A person carried by ONE axis is the interesting case:
-- nothing contradicts a wrong title or a wrong department there, and that is
-- where the errors concentrate. Give those rows extra attention.
-- ----------------------------------------------------------------------------
declare target_audience string default 'faculty_head';
declare round_no        int64  default 1;
declare sample_size     int64  default 100;

with
-- Every CONFIRMED audience each person holds, so a row can say what else the
-- person is. Judged on its own a title looks ambiguous far more often than it
-- is: somebody in hcp_researcher who is ALSO in researcher and lecturer is a
-- clinical academic, and that is usually the answer to the question the row
-- was asking.
all_audiences as (
    select
        snid,
        string_agg(distinct role_key order by role_key) as all_confirmed_audiences
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
    where role_label = 'CONFIRMED'
    group by snid
),
ranked as (
    select
        r.snid,
        -- ⭐ THE AUDIENCE BEING JUDGED. It is the same for all 100 rows, and
        -- it is carried on every row ON PURPOSE: once these rows are exported
        -- and handed to an AI, the declare block above is gone and nothing
        -- else in the payload says which rule to apply.
        r.role_key                              as audience,
        -- The sub-dimension this audience reports - a bucket for hcp_broad, a
        -- setting for pharmacist, an organisation type for the rest.
        r.role_detail                           as audience_detail,
        -- ⭐ HOW THEY GOT IN. Null means the person qualified for this
        -- audience in their own right. A value means they ARRIVED THROUGH A
        -- CHILD ROLE rolling up - so an hcp_broad row reading
        -- 'hcp_practitioner' is in the broad audience because they are a
        -- practitioner, and it is the practitioner rule that has to hold for
        -- the row to be correct.
        r.derived_from_role                     as reached_via,
        -- Every other audience this person is confirmed in.
        a.all_confirmed_audiences,
        r.evidence_title                        as job_title,
        r.evidence_org                          as organisation,
        r.evidence_dept                         as department,
        r.country_code,                         -- consultant means different
                                                -- things in different places
        r.is_current,                           -- information, not a verdict
                                                -- see rule 3 above
        r.title_group,                          -- what the model decided
        r.discipline,                           -- what the department decided
        round(r.role_final_score, 3)            as score,
        round(coalesce(r.role_score, 0.0), 2)   as axis_title,
        round(coalesce(r.org_score,  0.0), 2)   as axis_org,
        round(coalesce(r.dept_score, 0.0), 2)   as axis_dept,
        (case when coalesce(r.role_score, 0.0) > 0 then 1 else 0 end
       + case when coalesce(r.org_score,  0.0) > 0 then 1 else 0 end
       + case when coalesce(r.dept_score, 0.0) > 0 then 1 else 0 end) as axes_carrying,
        row_number() over (
            order by farm_fingerprint(cast(r.snid as string))
        )                                       as hash_position
    from `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles` r
    join all_audiences a using (snid)
    where r.role_key   = target_audience
      -- CONFIRMED only. The second confidence tier is never delivered, so it
      -- is not what needs measuring.
      and r.role_label = 'CONFIRMED'
)
select
    * except (hash_position),
    -- A PASTE-READY INSERT ROW, with the snid already filled in. Fill in the
    -- four quoted values and the line is valid SQL.
    --
    -- It exists for one reason. Transcribing an eight-digit id across a
    -- hundred rows is the single step in this process that silently goes
    -- wrong, and a verdict written against the WRONG snid is worse than no
    -- verdict at all - it is a measurement that looks real and is not.
    -- Never retype an snid. Always edit this string.
    format(
      "('%s','%s',%d,'VERDICT','REASON_CODE','REASON','READ_BY'),",
      snid, target_audience, round_no
    )                                           as insert_row
from ranked
where hash_position between (round_no - 1) * sample_size + 1
                        and  round_no      * sample_size
order by hash_position;


-- ============================================================================
-- STEP 3 - WHAT TO SEND THE AI
-- ============================================================================
-- Export the result of STEP 2 and give the AI the text between the two lines
-- below, followed by the rows. Keep the prompt identical across rounds and
-- audiences except for the audience rule - if the prompt drifts, the rounds
-- stop being comparable and the 500-row union is worthless.
--
-- Record which model you used in the read_by column. In six months the
-- question "where did this 86 percent come from" has to have an answer.
--
-- ---------------------------- PROMPT STARTS ---------------------------------
-- You are auditing an automated system that assigns job titles from ORCID to
-- marketing audiences. For each row, decide whether the assignment to the
-- audience named below is right.
--
-- SEND docs/AI-REVIEWER-RULES.md FIRST, BEFORE THIS PROMPT. It is the full set
-- of rules this pipeline applies to a job title, the decisions already made
-- about edge cases, the failure modes it has actually been caught in, and the
-- open questions where UNSURE is the right answer. Without it the AI judges
-- from its own idea of what a job title means, which is not what is being
-- audited.
--
-- THE AUDIENCE AND ITS RULE:
--   Every row carries an audience column naming the audience being judged,
--   and it is the same for all of them. The rule for it is:
--   <paste the one rule for this audience from THE RUBRIC above, or from
--    section 3 of AI-REVIEWER-RULES.md>
--
-- TWO COLUMNS THAT CHANGE WHAT YOU ARE JUDGING. Read them before the title.
--
--   reached_via  Empty means the person qualified for this audience in their
--                own right, so apply the rule above. A VALUE means they
--                arrived through that other audience rolling up into this one
--                - so a row in hcp_broad reading hcp_practitioner is there
--                because the person is a practitioner, and it is the
--                PRACTITIONER rule that has to hold for the row to be right.
--
--   all_confirmed_audiences  Every audience this person is in. Use it as
--                context, not as proof. Somebody in hcp_researcher who is
--                also in researcher and lecturer is a clinical academic, and
--                that usually answers the question the row was asking. But a
--                person being in four audiences is not evidence that any one
--                of them is correct.
--
-- For each row return exactly one verdict:
--   CORRECT  the evidence satisfies the rule
--   WRONG    the evidence contradicts the rule
--   UNSURE   the evidence is insufficient or the rule is genuinely unclear
--
-- For WRONG or UNSURE also return exactly one reason_code from:
--   title_wrong, field_wrong, uninformative, ambiguous_word, ended_role,
--   too_junior, language, other
--   <paste the definitions from THE REASON CODES above>
--
-- And return a reason - one short sentence in your own words saying what in
-- the row made you decide that.
--
-- THREE RULES YOU MUST FOLLOW:
--   1. UNSURE is a real verdict, not a failure. Use it when the evidence does
--      not decide the question. Do not guess to avoid it.
--   2. Judge what the person typed, not what they probably do. "Probably a
--      doctor" is not evidence.
--   3. Whether the person still holds the job is NOT being judged. A
--      researcher in 2010 who works in a bank today is still CORRECT. Only
--      use ended_role when the TITLE ITSELF says the post has ended, such as
--      emeritus or retired or a closed date range.
--
-- DO NOT SPREAD YOUR VERDICTS TO LOOK BALANCED. If 95 of 100 are correct, say
-- so. If 40 are unsure, say so.
--
-- OUTPUT FORMAT. Each input row carries an insert_row column which already
-- contains the correct snid. Return that exact string with VERDICT,
-- REASON_CODE, REASON and READ_BY replaced, and change nothing else. Do not
-- reorder, renumber, merge or skip rows, and never write an snid yourself.
-- ----------------------------- PROMPT ENDS ----------------------------------


-- ============================================================================
-- STEP 4 - WRITE THE VERDICTS BACK
-- ============================================================================
-- Paste the AI's lines into the VALUES block below, delete the trailing comma
-- on the last line, and run it. One INSERT for all 100 rows - a hundred
-- separate statements costs a hundred times as much and is a hundred chances
-- to corrupt a row.
--
-- Spot-check three or four rows against the STEP 2 output before you run it.
-- If the AI has shifted a verdict onto the wrong snid, this is the only moment
-- anybody would notice.
-- ----------------------------------------------------------------------------
insert into `dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts`
    (snid, audience, round_no, verdict, reason_code, reason, read_by)
values
    ('12345678','faculty_head',1,'CORRECT',NULL,NULL,'MODEL-NAME-HERE'),
    ('12345679','faculty_head',1,'WRONG','title_wrong','Title is Research Fellow, which names no faculty-level post.','MODEL-NAME-HERE'),
    ('12345680','faculty_head',1,'UNSURE','ambiguous_word','Title is only Director with no faculty word beside it.','MODEL-NAME-HERE');

-- Did it land? Expect one row per round and 100 in each.
select audience, round_no, count(*) as rows_written
from `dat-analytics-eng-ec869189.dev_orcid_role_review.audience_verdicts`
group by audience, round_no
order by audience, round_no;


-- ============================================================================
-- STEP 5 - NEXT ROUND
-- ============================================================================
-- Go back to STEP 2, set round_no to 2, and repeat. Five rounds per audience,
-- then move to the next audience in the plan at the top of this file.
--
-- When an audience is finished, tell Merve two things and nothing else:
--   the counts - how many correct, wrong and unsure
--   the reasons - which reason_code accounts for most of the wrong ones
--
-- The second one is the finding. The first one is just the number.
-- ============================================================================
