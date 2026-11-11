# Second reader: measuring whether our audience labels are right

**For the intern joining 2026-11-11. BigQuery only — no dbt, no repository
write access, and none needed.**

---

## 1. Why this job exists

This project sorts ~12 million ORCID employment records into nine marketing
audiences — Researcher, Lecturer, Librarian, Pharmacist, Head of Faculty and
four healthcare audiences. ORCID has **no profession field**, so there is
nothing to compare our answer against automatically. There is no ground truth.

The only quality measure we have is a human reading a sample: pull 100 people
an audience claims, look at the job title, employer and department each one
typed, and say whether the label is right.

Every accuracy figure in our status document — Researcher 99.0%, Head of
Faculty 83.3% — comes from **one person reading** (the analytics engineer who
built the pipeline). That is the weakest part of the whole project, for two
reasons:

1. **The builder marking their own homework.** Someone who wrote the rule that
   put a person in an audience is the worst judge of whether it belongs there.
2. **One reading is not a measurement.** It has been reproduced exactly once:
   HCP Researcher read 90.0%, then 89.0% on a second sample of different
   people. One point apart. That is the only figure in this project that has
   been reproduced rather than asserted; the other eight are single opinions.

**Your reading turns opinions into measurements.** Two things come out of it:

- **An agreement rate.** Where two independent readers agree, the figure is
  reportable. Where they diverge, the figure is not safe to quote.
- **The disagreements themselves, which are the more valuable output.** A row
  two careful readers score differently is usually not a mistake — it is a
  place where the *definition* is unclear. Those rows become questions for
  marketing, and marketing owns the definitions. Finding them is the point.

You are not checking the engineer's work for errors. You are a second
instrument on the same measurement.

---

## 2. What you will actually do

Four steps, repeated per audience.

| Step | What |
| --- | --- |
| 1 | Run one query. Change one word at the top to pick the audience |
| 2 | It returns 100 people: job title, employer, department, plus the score and which signals carried the decision |
| 3 | Read each row and record one verdict: **CORRECT**, **WRONG** or **UNSURE**, plus a reason code from a fixed list |
| 4 | Write the verdicts into your own BigQuery table. One `INSERT`, one row per person |

Then one more query compares your rate with the engineer's and lists the rows
you two scored differently.

**Expect 60–90 minutes per 100 rows** the first time, faster after. Do not
rush: a fast reading is worth nothing, and an UNSURE is a real answer.

### Read these audiences, in this order

| Order | Audience | Engineer's figure | Why this one |
| --- | --- | --- | --- |
| 1 | `faculty_head` | **83.3%** | The weakest audience, and the one marketing is being asked to decide about. If your figure disagrees with 83.3%, that matters immediately |
| 2 | `hcp_broad` | **90.6%** | The largest healthcare audience, 93,377 reachable people |
| 3 | `hcp_researcher` | **94.3%** | Read three times by one person; the only audience where a second reader can be checked against a reproduced figure |
| 4 | `hcp_practitioner` | **93.4%** | If there is time. Its high-similarity band has never been examined by anyone |

Stop after one audience if that is all the time there is. One audience read
properly is worth more than four read quickly.

---

## 3. How to judge a row — the rubric

Each audience has its own rule. **Judge against the rule, not against your own
sense of the job.** The question is never "is this a good person to email"; it
is "does the evidence in this row satisfy this audience's definition".

| Audience | The label is CORRECT when |
| --- | --- |
| `researcher` | The **job title** names research work — researcher, scientist, postdoc, research fellow, principal investigator. **The field is irrelevant**: a plant pathologist and an astrophysicist are both researchers |
| `lecturer` | The job title names a teaching or academic post — professor, lecturer, docent, teaching assistant |
| `librarian` | The job title contains a library word |
| `pharmacist` | The job title names a pharmacist. A pharmacology academic is **not** one |
| `hcp_practitioner` | The title names a clinician who treats patients **and** the department is a human-health field |
| `hcp_researcher` | The title names research **and** the department is a human-health field. **Patient contact is not required** |
| `hcp_administrator` | The title names leadership **and** the department is a human-health field. **Patient contact is not required** |
| `hcp_broad` | Any clinical signal, but a clinical **job title is mandatory** — a department alone is not enough |
| `faculty_head` | The job title names a **faculty-level** post — dean, head of department, rector, pro-vice-chancellor — at an educational institution |

### The reason codes

When you mark WRONG or UNSURE, pick one:

| Code | Means |
| --- | --- |
| `title_wrong` | The job title does not name this profession at all |
| `field_wrong` | The department is not in this audience's field |
| `uninformative` | The title carries no occupational information — `dr`, `md`, `fellow`, `member` |
| `ambiguous_word` | The title's key word has two meanings. `consultant` is a hospital specialist in Britain and a business adviser in the US. `fellow` is a trainee physician in America and a researcher in Britain. `director` can be anything |
| `ended_role` | The title records a post that has finished — *emeritus*, *retired*, *professor 2014-2018* |
| `too_junior` | A student or trainee where the audience means a qualified professional |
| `language` | The title is in a language you cannot read with confidence. **Use this freely** — guessing is worse than flagging |
| `other` | Anything else. Write a note |

**Measuring by cause is the whole value.** "11 wrong out of 100" tells us
almost nothing. "7 of the 11 are `field_wrong` in veterinary departments"
tells us exactly what to fix, and it was this kind of breakdown — not the
percentage — that found the department bug that moved one audience by 5 points.

### Three rules that matter more than they look

1. **UNSURE is a real verdict, not a failure.** It is excluded from the
   percentage and reported separately. In Head of Faculty a third of the
   engineer's sample was UNSURE, and that third is precisely the open question
   marketing has to answer. If you cannot decide in about a minute, mark
   UNSURE and move on.
2. **Judge what the person typed, not what they probably do.** The question is
   whether the evidence in the row supports the label. "They are probably a
   doctor" is not evidence; a job title naming a clinical role is.
3. **A person still being in that job is NOT what you are judging.** Someone
   who was a researcher in 2010 and now works in a bank is still CORRECT for
   `researcher` — that is a decision marketing already made. Only mark
   `ended_role` when the **title itself** says the post has ended.

---

## 4. Do not look at the engineer's verdicts first

The measurement is worth nothing if it is anchored on the first reading. So:

- Do not ask what the engineer marked for a row, and do not read
  `docs/open-questions.md` sections 2.x before you finish. They contain the
  first reading's conclusions.
- Reading section 3 of this file (the rubric) is fine and necessary. The rubric
  is the *definition*; the verdicts are the *measurement*.
- Record your verdict before discussing any row with anyone.

Afterwards, discuss everything. The disagreements are the output.

---

## 5. One hard rule about the data

**No per-person row from these queries goes anywhere outside BigQuery.** Not
into a spreadsheet shared outside the team, not into Slack, not into the git
repository, not into a document.

The reason: job title + organisation + department together identify a real
person's public ORCID profile. A folder of sample rows was deleted from this
repository on 2026-11-05 for exactly this reason. Your verdicts live in a
BigQuery table beside the data they describe, and what leaves BigQuery is
**counts and reasons** — "7 wrong, 5 of them `field_wrong`" — never the people.

Working inside BigQuery is not a limitation here. It is the design.

---

## 6. What you need from us

See `analyses/48_second_reader.sql` for the queries. The access list and the
setup steps are in section 1 of that file.
