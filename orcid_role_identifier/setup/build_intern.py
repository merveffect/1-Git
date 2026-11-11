# -*- coding: utf-8 -*-
# Builds the second-reader brief as a docx. The markdown twin is
# docs/INTERN-SECOND-READER.md; this is the version that gets sent to
# somebody who does not open a repository.
import sys, os
SP = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, SP)
from docx_lib import *
from docx.shared import Pt

d = doc_new()

p = d.add_paragraph(); p.paragraph_format.space_after = Pt(2)
r = p.add_run("ORCID ROLE ENRICHMENT"); r.bold = True; r.font.size = Pt(9.5)
r.font.color.rgb = PLUM; r.font.name = SANS
p = d.add_paragraph(); p.paragraph_format.space_after = Pt(4)
r = p.add_run("Second reader: measuring whether our audience labels are right")
r.bold = True; r.font.size = Pt(20); r.font.color.rgb = INK; r.font.name = SANS
para(d, "For the intern joining 11 November 2026  ·  BigQuery only, no dbt, no "
        "repository access  ·  Analytics Engineering",
     size=9.5, color=MUT, space_after=12)

# ------------------------------------------------------------------ 1
h(d, "1.  Why this job exists")
para(d, "This project sorts about **12 million ORCID employment records** into nine "
        "marketing audiences — Researcher, Lecturer, Librarian, Pharmacist, Head of "
        "Faculty and four healthcare audiences. ORCID has **no profession field**, so "
        "there is nothing to compare our answer against automatically. There is no "
        "ground truth anywhere in this problem.")
para(d, "The only quality measure that exists is a human reading a sample: pull 100 "
        "people an audience claims, look at the job title, employer and department each "
        "one typed, and say whether the label is right.")
box(d, "AND EVERY FIGURE WE REPORT COMES FROM ONE PERSON DOING THAT", [
 "Researcher 99.0%. Lecturer 98.7%. Head of Faculty 83.3%. Every one of those was "
 "produced by **one reader** — the analytics engineer who wrote the rules being "
 "tested. That is the weakest part of the whole project, for two reasons.",
 "",
 "**1. The builder marking their own homework.** Somebody who wrote the rule that put "
 "a person in an audience is the worst available judge of whether they belong there.",
 "",
 "**2. One reading is not a measurement.** Exactly one of the nine has ever been "
 "reproduced: HCP Researcher read 90.0%, then 89.0% on a different 100 people. One "
 "point apart. The other eight are single opinions presented as measurements, and the "
 "status document says so in those words.",
], fill="FBF1EF", accent=RED)
para(d, "**Your reading turns opinions into measurements.** Two things come out of it.")
para(d, "**An agreement rate.** Where two independent readers land in the same place, "
        "the figure is reportable. Where they diverge, the figure is not safe to quote "
        "and we stop quoting it until we know why.")
para(d, "**The disagreements themselves, which are the more valuable output.** A row two "
        "careful readers score differently is usually not a mistake. It is a place where "
        "the **definition** is unclear — and definitions belong to marketing, not to "
        "us. Those rows become questions we did not know to ask. Finding them is the "
        "point of the exercise.")
para(d, "You are not checking the engineer's work for errors. You are a second "
        "instrument on the same measurement.", space_after=12)

# ------------------------------------------------------------------ 2
h(d, "2.  What you will actually do")
table(d, ["Step", "What"],
 [["1", "Run one query. Change one word at the top to pick the audience"],
  ["2", "It returns 100 people: job title, employer, department, plus the score and "
        "which signals carried the decision"],
  ["3", "Read each row and record one verdict — **CORRECT**, **WRONG** or "
        "**UNSURE** — plus a reason code from a fixed list"],
  ["4", "Write the verdicts into your own BigQuery table. One `INSERT`, one row per "
        "person"]],
 widths=[0.5, 5.6])
para(d, "Then one more query compares your rate with the engineer's and lists every row "
        "the two of you scored differently.")
para(d, "**Expect 60 to 90 minutes per 100 rows** the first time, faster after. Do not "
        "rush it: a fast reading is worth nothing, and an UNSURE is a real answer rather "
        "than a failure to decide.")

h(d, "2a.  Read these audiences, in this order", 2)
table(d, ["Order", "Audience", "Our figure", "Why this one"],
 [["1", "`faculty_head`", "**83.3%**",
   "The weakest audience, and the one marketing is being asked to decide about. If "
   "your figure disagrees with 83.3%, that matters immediately"],
  ["2", "`hcp_broad`", "**90.6%**",
   "The largest healthcare audience — 93,377 reachable people"],
  ["3", "`hcp_researcher`", "**94.3%**",
   "Read three times by one person, so it is the only audience where a second reader "
   "can be checked against a figure that was already reproduced"],
  ["4", "`hcp_practitioner`", "**93.4%**",
   "If there is time. Its high-similarity band has never been examined by anybody"]],
 widths=[0.5, 1.3, 0.8, 3.5])
para(d, "**Stop after one audience if that is all the time there is.** One audience read "
        "properly is worth more than four read quickly.", space_after=12)

# ------------------------------------------------------------------ 3
h(d, "3.  How to judge a row — the rubric")
para(d, "Each audience has its own rule. **Judge against the rule, not against your own "
        "sense of the job.** The question is never “is this a good person to email”. "
        "It is “does the evidence in this row satisfy this audience's definition”.")
table(d, ["Audience", "The label is CORRECT when"],
 [["`researcher`",
   "The **job title** names research work — researcher, scientist, postdoc, research "
   "fellow, principal investigator. **The field is irrelevant**: a plant pathologist "
   "and an astrophysicist are both researchers"],
  ["`lecturer`",
   "The job title names a teaching or academic post — professor, lecturer, docent, "
   "teaching assistant"],
  ["`librarian`", "The job title contains a library word"],
  ["`pharmacist`",
   "The job title names a pharmacist. A pharmacology academic is **not** one"],
  ["`hcp_practitioner`",
   "The title names a clinician who treats patients **and** the department is a "
   "human-health field"],
  ["`hcp_researcher`",
   "The title names research **and** the department is a human-health field. "
   "**Patient contact is not required**"],
  ["`hcp_administrator`",
   "The title names leadership **and** the department is a human-health field. "
   "**Patient contact is not required**"],
  ["`hcp_broad`",
   "Any clinical signal, but a clinical **job title is mandatory** — a department "
   "alone is not enough"],
  ["`faculty_head`",
   "The job title names a **faculty-level** post — dean, head of department, rector, "
   "pro-vice-chancellor — at an educational institution"]],
 widths=[1.5, 4.6], size=9)

h(d, "3a.  The reason codes", 2)
para(d, "When you mark WRONG or UNSURE, pick one.")
table(d, ["Code", "Means"],
 [["`title_wrong`", "The job title does not name this profession at all"],
  ["`field_wrong`", "The department is not in this audience's field"],
  ["`uninformative`",
   "The title carries no occupational information — `dr`, `md`, `fellow`, `member`"],
  ["`ambiguous_word`",
   "The title's key word has two meanings. `consultant` is a hospital specialist in "
   "Britain and a business adviser in the United States. `fellow` is a physician in "
   "subspecialty training in America and a researcher in Britain. `director` can be "
   "anything"],
  ["`ended_role`",
   "The title records a post that has finished — *emeritus*, *retired*, "
   "*professor 2014-2018*"],
  ["`too_junior`",
   "A student or trainee where the audience means a qualified professional"],
  ["`language`",
   "The title is in a language you cannot read with confidence. **Use this freely** "
   "— guessing is worse than flagging"],
  ["`other`", "Anything else. Write a note"]],
 widths=[1.3, 4.8], size=9)
box(d, "MEASURING BY CAUSE IS THE WHOLE VALUE", [
 "“11 wrong out of 100” tells us almost nothing.",
 "",
 "“7 of the 11 are `field_wrong`, all in veterinary departments” tells us exactly "
 "what to fix.",
 "",
 "It was this kind of breakdown — not the percentage — that found the department "
 "bug that moved one audience by five points. The reason code is more important than "
 "the verdict.",
])

h(d, "3b.  Three rules that matter more than they look", 2)
para(d, "**1. UNSURE is a real verdict, not a failure.** It is excluded from the "
        "percentage and reported separately beside it. In Head of Faculty a third of the "
        "engineer's sample was UNSURE, and that third is precisely the open question "
        "marketing has to answer. If you cannot decide in about a minute, mark UNSURE "
        "and move on.")
para(d, "**2. Judge what the person typed, not what they probably do.** The question is "
        "whether the evidence in the row supports the label. “They are probably a "
        "doctor” is not evidence; a job title naming a clinical role is.")
para(d, "**3. Whether the person is still in that job is NOT what you are judging.** "
        "Somebody who was a researcher in 2010 and now works in a bank is still CORRECT "
        "for `researcher` — that is a decision marketing already made. Only mark "
        "`ended_role` when the **title itself** says the post has ended.", space_after=12)

# ------------------------------------------------------------------ 4
h(d, "4.  Do not look at the engineer's verdicts first")
para(d, "The measurement is worth nothing if it is anchored on the first reading. So:")
bullet(d, "Do not ask what the engineer marked for a row.")
bullet(d, "Do not read `docs/open-questions.md` sections 2.x before you finish — they "
          "contain the first reading's conclusions.")
bullet(d, "Reading section 3 of this document is fine and necessary. The rubric is the "
          "**definition**; the verdicts are the **measurement**. Those are different "
          "things.")
bullet(d, "Record your verdict before discussing any row with anybody.")
para(d, "Afterwards, discuss everything. The disagreements are the output.",
     space_after=12)

# ------------------------------------------------------------------ 5
h(d, "5.  One hard rule about the data")
box(d, "NO PER-PERSON ROW LEAVES BIGQUERY", [
 "Not into a spreadsheet shared outside the team, not into Slack, not into the git "
 "repository, not into a document.",
 "",
 "**The reason:** job title + organisation + department together identify a real "
 "person's public ORCID profile. A folder of sample rows was deleted from this "
 "repository on 5 November for exactly this reason.",
 "",
 "Your verdicts live in a BigQuery table beside the data they describe, and what "
 "leaves BigQuery is **counts and reasons** — “7 wrong, 5 of them "
 "`field_wrong`” — never the people.",
 "",
 "Working inside BigQuery is not a limitation here. It is the design.",
], fill="FBF1EF", accent=RED)

# ------------------------------------------------------------------ 6
h(d, "6.  The access you need, and nothing more")
table(d, ["What", "Where", "Why"],
 [["**READ** — BigQuery Data Viewer",
   "`dev_orcid_role_identifier_scoring.fct_researcher_roles`",
   "One table. It carries the job title, organisation, department, the three axis "
   "scores and the audience label — everything a reading needs. Nothing in it "
   "identifies a person beyond `snid`, which is an internal key"],
  ["**WRITE** — BigQuery Data Editor",
   "`dev_orcid_role_review`",
   "Your own dataset, created by query 0. Deliberately **outside** the pipeline's "
   "datasets: nothing a reviewer writes should be able to reach a dbt model, and "
   "nothing dbt rebuilds should be able to drop a reviewer's work"],
  ["**RUN** — BigQuery Job User", "project level", "Without it no query runs"]],
 widths=[1.7, 2.1, 2.8], size=9)
para(d, "**One thing to check before query 0.** The new dataset's location must match "
        "the pipeline's own datasets, because BigQuery does not join across regions. "
        "Read it off `dev_orcid_role_identifier_scoring` in the console — Details, "
        "then Data location — and put it in query 0. Do not guess it.")
para(d, "**What is deliberately NOT granted:** write access to any "
        "`dev_orcid_role_identifier_*` dataset, and no repository access. Neither is "
        "needed, and a single row in one seed file moves nine audiences at once.")
para(d, "The queries are in `analyses/48_second_reader.sql`. Queries 1 to 3a are yours; "
        "4 compares your rate with the first reading; 5 and 5a are the row-level "
        "comparison, which works from the second reading onward.", space_after=12)

# ------------------------------------------------------------------ 7
h(d, "7.  One limit, stated now rather than discovered later")
para(d, "The first reader's verdicts were never stored per person — only the totals "
        "were, because per-person rows are deliberately kept out of the repository. So "
        "**the first comparison is a comparison of rates, not of rows**: “you read 100 "
        "people and got 86%, the first reader read 100 different people and got "
        "83.3%”.")
para(d, "That is weaker than row-level agreement, and it is what we have. It is also "
        "exactly how HCP Researcher was reproduced, so it is not worthless.")
para(d, "From this point on both readers write into the same table, so the **next** "
        "comparison is row-level: query 5 computes Cohen's kappa and query 5a lists "
        "every row the two readers scored differently. Getting to that state is half "
        "the reason this work is being set up now.")
box(d, "WHY KAPPA AND NOT PLAIN AGREEMENT", [
 "On an audience that is 99% correct, two readers who say CORRECT to everything agree "
 "99% of the time while measuring nothing at all.",
 "",
 "Cohen's kappa subtracts the agreement that chance alone would produce.",
 "",
 "`< 0.20   no better than chance - the rubric is not usable as written`",
 "`0.21-0.40  poor        0.41-0.60  moderate`",
 "`0.61-0.80  good        > 0.80     strong`",
])

for out in (os.path.join(os.path.dirname(SP), "docs",
                         "ORCID-Second-Reader-Brief.docx"),
            os.path.join(os.path.expanduser("~"), "Downloads",
                         "ORCID-Second-Reader-Brief.docx")):
    d.save(out); print("saved:", out, os.path.getsize(out), "bytes")
