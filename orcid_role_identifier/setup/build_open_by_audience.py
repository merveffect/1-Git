# -*- coding: utf-8 -*-
# Builds docs/ORCID-Open-Questions-by-Audience.docx - every question still
# waiting, filed under the audience it belongs to.
#
# WHY IT EXISTS. Merve, 2026-11-19: "her audience in altina bekleyen open
# questionlari yaz yani basliklara yaz. head of faculty basligi altina bekleyen
# fikirler ve questionlar, practitioner altina bekleyen fikirler ve questionlar
# vs olarak." The status document files questions by SIZE, which is right for
# deciding what to do next and wrong for anybody who owns one audience and
# wants to know what is outstanding in theirs.
#
# WHAT IT IS NOT. Not a decision log - docs/open-questions.md is that, newest
# first, with the measurement behind each call. Not a status report - the
# status document is that. This is one thing only: what is still open, by
# audience, with who has to answer it.
#
# ⭐ NOTHING IS INVENTED HERE. Every item is lifted from an audience section in
# setup/audiences.py, from section 7 of the status document, from the marketing
# one-pager, or from docs/open-questions.md 2.22. Where a size is quoted, its
# unit is stated, because records and people differ by a factor that changes
# title by title. Where no size has been measured, it says so rather than
# guessing one.
import sys, os
SP = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, SP)
from docx_lib import *
from docx.shared import Pt

d = doc_new()

p = d.add_paragraph(); p.paragraph_format.space_after = Pt(2)
r = p.add_run("ORCID ROLE ENRICHMENT"); r.bold = True; r.font.size = Pt(9.5)
r.font.color.rgb = PLUM; r.font.name = SANS
p = d.add_paragraph(); p.paragraph_format.space_after = Pt(4)
r = p.add_run("What is still open, audience by audience")
r.bold = True; r.font.size = Pt(20); r.font.color.rgb = INK; r.font.name = SANS
para(d, "20 November 2026  ·  Analytics Engineering, Researcher 360",
     size=9.5, color=MUT, space_after=10)

para(d, "Every question still waiting, filed under the audience it affects. The status "
        "document orders the same questions by how many people they move, which is the "
        "right order for deciding what to do next and the wrong one if you own a single "
        "audience. This is the other view of the same list.", space_after=4)
para(d, "**Who answers** is on every row. *Marketing* means the question is about what "
        "an audience is for, and we cannot answer it from the data. *Us* means it is "
        "ours and only needs a decision to be written down. Nothing here is blocked on "
        "engineering difficulty.", space_after=10)

box(d, "READ THE SIZES CAREFULLY", [
 "**A record is a job, a person is a person.** Somebody with three posts in ORCID is "
 "three records. The ratio differs title by title, so a count in records is not a "
 "smaller version of a count in people and the two must never be compared. Each size "
 "below says which it is.",
 "",
 "**Where nothing has been measured, it says so.** An unsized question is not a small "
 "one; it is one nobody has counted yet.",
])

def aud(title, sub, rows, note=None):
    h(d, title, 2)
    if sub:
        para(d, sub, size=9.5, color=MUT, space_after=4)
    if rows:
        table(d, ["What is open", "Size", "Who answers"], rows,
              widths=[4.0, 1.25, 0.95], size=8.8)
    if note:
        # A list of notes, because an audience can carry a caveat AND a
        # decision taken but not yet built, and the two are different things.
        for n in ([note] if isinstance(note, str) else note):
            para(d, n, size=9, color=MUT, space_after=4)
    d.paragraphs[-1].paragraph_format.space_after = Pt(11)


# ------------------------------------------------------------------ BLOCKING
h(d, "The one that blocks other work")
table(d, ["", "What is open", "Who answers"],
 [["1", "**What Head of Faculty is for.** A separate meeting is being held to settle "
        "whether it opens up beyond academia to reach decision makers and budget "
        "holders. The whole audience is frozen until then, because the answer changes "
        "what it is, not just how big it is.", "**Marketing**"]],
 widths=[0.3, 5.0, 0.9], size=8.8)
para(d, "**What came off this list on 20 November.** “What Healthcare Professional "
        "(broad) should mean” is settled: it means what its name says in marketing's "
        "vocabulary, biomedical researchers included, and it is not being renamed. The "
        "54,426 people who have never seen a patient are in it on purpose. Everything "
        "else below can wait without stopping anything.", size=9, color=MUT,
     space_after=11)


# ---------------------------------------------------------------- AUDIENCES
h(d, "By audience")

aud("Lecturer — 426,449 people, 98.7% correct",
    "Both questions were answered on 19 November and built on 20 November. The build "
    "then raised one new question, in Researcher rather than here.",
 [], "**Answered and built — it cost 2,956 people.** Visiting scholars and visiting fellows "
     "are not teaching staff — the post is temporary, usually unpaid, and the title "
     "names a visit rather than a job. An honorary post is conferred rather than held, "
     "which completes the family begun on 16 October when `emeritus professor`, "
     "`retired professor` and `honorary researcher` were rejected. Both leave Lecturer "
     "for the holding group, so they can be brought back by name. `visiting researcher` "
     "and `visiting scientist` are untouched — they name research and are already in "
     "Researcher. Before the build the two rules could see 978 people on an honorary "
     "title and 1,727 on a visiting one, and neither rule reached a second audience. "
     "Afterwards Lecturer had gone from 427,256 to 426,449 against an expected 429,405, "
     "so the measured cost is 2,956 — the prediction held.")

aud("Researcher — 344,847 people, 99.0% correct",
    "**Nothing is open.** One item arrived on 20 November and was answered the same day.",
 [], ["**Answered 20 November: honorary research fellows STAY in Researcher.** Honorary "
     "posts left Lecturer that day, and because the rule is scoped to teaching titles, "
     "241 honorary titles carrying 1,127 records remained here — `honorary research "
     "fellow` and its family. Raised as an inconsistency with the 16 October rejection "
     "of the exact string `honorary researcher`; settled by deciding these stay. No "
     "rule was widened.",
     "The 43.9% survey agreement is not a fault and not a question. A professor who runs "
     "a research group is in both Lecturer and Researcher; the survey records one answer, "
     "so one of the two is counted wrong whatever we do."])

aud("Students — 102,026 people, 98.7% correct",
    "Built and read in November. One open item left: two more were answered on 20 "
    "November and the largest source of doubt on 19 November.",
 [["**`md phd` and `md/phd`.** A US MD-PhD programme student, or a qualified physician "
   "listing two degrees. The same credential-versus-status problem as a bare `PhD`.",
   "not measured", "Us"]],
 ["**Answered 19 November, written, not yet built:** a bare qualification is NOT a "
  "student. `PhD`, `Master`, `Bachelor` as the whole job title is a credential, not a "
  "status — one person wrote `Phd holder` outright — and it was 6% of the sample and "
  "the largest single source of doubt here. The rule matches the whole title or "
  "nothing, so `PhD student` is untouched, and `doctor` and `dr` are deliberately left "
  "out of it because the same day ruled a bare doctor stays in Practitioner. **It cost "
  "5,604 people** — from 107,091 to 102,026 against an expected 107,630 — which makes "
  "it by far the most expensive of the five decisions. Before the build it looked like "
  "4,241, published as a floor because that count ran on the raw title and could not "
  "see the spellings the cleaning changes. The floor was 76% of the real cost.",
  "**One hole left, measured at 10 records.** A bare qualification the machine reads as "
  "research is routed here by a different rule that the new exclusion is not scoped to "
  "see. The fix is one field on that other rule.",
  "Not a question: the employer rule refuses 10,316 people whose titles plainly say "
  "`phd student`, because ROR types Max Planck as a facility and teaching hospitals as "
  "healthcare. That bill was measured and accepted on 11 November."])

aud("Healthcare Professional (broad) — 178,556 people, 90.6% correct",
    "**Nothing is open.** Settled on 20 November and not being renamed.",
 [], ["**This is what Healthcare Professional means in marketing's vocabulary.** "
     "Biomedical researchers roll up into it, so 54,426 people who have never seen a "
     "patient are in it — on purpose. The question had been carried as the one thing "
     "blocking delivery; it was answered on 11 November and closed explicitly on 20 "
     "November. No rename, nothing waiting.",
     "It has no errors of its own — everyone arrives through a child audience, so it "
     "improves when they do. 887 of the people in it describe themselves as professors "
     "or researchers rather than clinicians."])

aud("Clinical / Biomedical Researcher — 109,854 people, 90.0% correct",
    "Grew when biomedical research was ruled in on 11 November. Two items, neither sized.",
 [["**Where does “biomedical” stop?** The audience accepts human-health and "
   "biomedical departments. Nobody has drawn the line at the far edge of biomedical — "
   "plant genetics, animal physiology, bioinformatics with no human subject.",
   "not measured", "Marketing"],
  ["**A title that is the single word `Fellow`.** A trainee physician in the United "
   "States, a researcher in the United Kingdom. Flagged in the reviewer rules as "
   "unsure and never settled.", "not measured", "Us"]])

aud("Practitioner — 57,351 people, 93.4% correct",
    "The least-read group in the project: reviewed titles cover 38% of its records "
    "against 75% for researchers. Three items left; two were answered on 19 November "
    "and four more on 20 November.",
 [["**Does a research nurse treat patients?** `research nurse`, `clinical research "
   "nurse`, `research midwife`, `research dietitian`, `nurse scientist`. A real "
   "question and nobody has asked it.", "~286 records", "Us / clinical expert"],

  ["**Psychology: the field side is not done.** Psychologists were ruled clinical on "
   "20 November, and psychiatry is already in on both axes. But `psychology` is "
   "classified as a social and behavioural subject rather than a clinical one, and this "
   "audience needs the title AND the field to agree — so a psychologist in a Psychology "
   "department cannot enter it. `analyses/56` sizes both professions and what the fix "
   "would cost.", "being counted", "Us"]],
 ["**Answered 19 November, written, not yet built.** `medical physicist` (346 records) "
  "becomes a Clinical researcher: they plan radiotherapy doses and assure imaging "
  "equipment, and they do not treat patients, so the same move `clinical scientist` got "
  "in October. Two consequences accepted with it — they also enter the all-fields "
  "Researcher audience, which has no department test, and one whose department reads as "
  "physics leaves the healthcare audiences altogether. A bare `doctor` (4,465 records) "
  "STAYS in Practitioner, written down so it cannot drift on the next rebuild; unlike "
  "`consultant` it names a medical qualification in every language that borrowed it. "
  "The bare `dr` was settled the next day: a medical qualification beside a clinical "
  "department is enough, and the department test is what makes it safe. "
  "**Measured on the build: all 170 of the medical physicists we confirm work in "
  "radiotherapy, radiology or oncology departments**, so every one re-confirms as a "
  "clinical researcher and rolls back up into Healthcare (broad) — which grew 0.513% "
  "against a control median of 0.503%, so the move cost it nothing. 291 people typed "
  "the title and only 170 were in any audience, so it also recruited about 121 who "
  "were nowhere before.",
  "**Veterinarians: decided NO on 20 November** — every HCP audience is about humans, "
  "and the test is the work rather than the subject. 161 people carried a veterinary "
  "job title in Healthcare (broad), 121 of them contactable. The job-title route is "
  "closed; a veterinary professor still belongs in Lecturer and a veterinary researcher "
  "in Researcher, neither being an HCP audience.",
  "**Sport and exercise science: decided 20 November, split on the word** — keep the "
  "departments that say *medicine*, drop the ones that say *science*. A sports physician "
  "treats patients; a sport scientist studies performance.",
  "**And the department half of both calls was dropped, deliberately.** A professor in a "
  "veterinary faculty stays in Clinical researcher, and *Faculty of Sport and Health "
  "Sciences* stays in the healthcare audiences. The title is always the priority, and a "
  "rule is not worth writing for 35 people. It is also the project's own architecture "
  "said out loud — the title decides and the department corroborates, the same principle "
  "that retired the field-only route on 4 November when it was admitting 6,115 people "
  "with no clinical job title at all.",
  "**A caveat rather than a question:** the 93.4% was measured before 19 November, when "
  "every title containing `consultant` left this audience and took about 5,400 people "
  "with it. The people removed included known errors, so the figure is more likely to "
  "understate than overstate — but it has not been re-read and should be quoted with "
  "its date."])

aud("Clinical Administrator — 8,398 people, 94.9% correct",
    "**Nothing is open.** The one item this audience carried was checked on 19 November "
    "and closed.",
 [], "Closed on 19 November: the worry that industry medical directors, blocked here "
     "since 5 November, would simply keep Healthcare (broad). Of the forty employers "
     "sending the most leadership titles into Healthcare (broad), not one is a company "
     "— they are hospitals, medical faculties, health ministries, the NIH, Cleveland "
     "Clinic, Mayo. A caveat remains: the 94.9% was read on 5 November and this audience "
     "gained about 1% in new members on 19 November.")

aud("Head of Faculty — 17,421 people, 83.3% correct — PARKED",
    "Parked and not delivered. Everything below is frozen until marketing answers the "
    "seven questions sent on 18 November — they change what the audience is, so "
    "working on it now risks building the wrong thing.",
 [["**The seven questions.** What the audience is called; which of the 33 job classes "
   "are in; whether `Director`, `Head` and `Chief` count on their own or only when "
   "qualified; whether healthcare administrators are a sub-group; how it interacts with "
   "the existing Head of Faculty audience; current jobs only or past ones too; and "
   "whether the Exclusion Editor list is a job or a person.", "see below",
   "**Marketing**"],
  ["**Which of three sizes they want.** Measured, not forecast: academia only 17,218 "
   "people with 0 at a company; academia plus resolved employers 23,676 with 408; the "
   "gate fully open 35,378 with 408.", "17,218–35,378 people", "**Marketing**"],
  ["**52 people hold a clinical title, not an academic one.** 27 of them on the words "
   "`medical director` alone, there since 29 October. They arrive through employers ROR "
   "types as education, or whose name reads like a university. 42 of the 52 carry no "
   "academic word at all.", "52 people", "Us, after the answers"],
  ["**A second source.** The job title is the only evidence this audience has, so a "
   "vague title has nothing to contradict it. 20% of it holds nothing but `director`, "
   "`head` or `chair`.", "20% of the audience", "Us"]],
 "**The finding worth carrying into that conversation:** opening the gate fully buys no "
 "commercial audience. Company employers are 408 either way. The commercial people exist "
 "— 868 CEOs, 429 founders, 224 managing directors — but 11,702 of the 18,160 "
 "who would arrive have an employer nobody could identify. What blocks them is employer "
 "identification, not their job title.")

aud("Pharmacist — 2,090 people, 95.7% correct",
    "Was the weakest audience in the project in October. One item left, and it is "
    "vocabulary rather than a rule.",
 [["**Portuguese and Spanish forms the English stems miss**, and clinical chemists. "
   "Overrides, not a new rule.", "not measured", "Us"]])

aud("Librarian — 713 people, 98.5% correct",
    "The only audience where every member was read rather than a sample. One item, and "
    "it is a confirmation rather than a question.",
 [["**Two exclusions we chose.** Archivists, because the word also collected "
   "archaeologists, glaciologists and clerks. And `information specialist`, because it "
   "collected every IT job in the data. Both deliberate; marketing has never confirmed "
   "them.", "small", "Marketing"]])


# ------------------------------------------------------------ CROSS-CUTTING
h(d, "Questions that cross several audiences")
table(d, ["What is open", "Reach", "Who answers"],
 [["**Should a job somebody has left still count?** ORCID keeps a whole employment "
   "history and seven of the ten audiences accept any of it, so a researcher in 2010 who "
   "runs a bakery today is still in Researcher. A label is never replaced by a newer "
   "job, only added to. Head of Faculty, Librarian and Students already count current "
   "posts only. Whichever way it goes: the job title and employer we show you are the "
   "ones that put the person in the audience, so for anybody in on a past job they can "
   "be years out of date.", "seven of ten", "**Marketing**"],
  ["**A clinical expert.** Both outside sources we hold share one gap: clinical "
   "specialties. The role library has no specialty list at all — no cardiologist, no "
   "anaesthetist, no midwife — and the survey does not reach enough clinicians to "
   "settle them. It is the one outside source this project has asked for and never had, "
   "and it is why the healthcare audiences sit at 90–95% while the academic ones sit "
   "at 99%.", "all healthcare", "Merve / Bernadeta"],
  ["**Reach the survey answers in BigQuery.** Chloe pointed at `Staging_Response`. It "
   "would make the self-declaration check repeatable instead of a one-off export.",
   "—", "Us / data eng"]],
 widths=[4.0, 1.1, 1.1], size=8.8)

box(d, "WHAT IS NOT ON THIS LIST, AND WHY", [
 "**Statisticians and economists.** 2,177 records in no audience, and they stay out. "
 "They were never read title by title, and an audience is something a title earns by "
 "being read, not by resembling one that was. Settled, not pending.",
 "",
 "**Every title containing `consultant`.** Removed from Practitioner on 19 November at "
 "a measured cost of about 5,400 people. The decision was questioned once, with the "
 "number, and reaffirmed. It is closed, and the price is recorded in the decision log "
 "rather than left to be inferred.",
 "",
 "**Anything blocked on engineering.** There is nothing on this list we cannot build. "
 "Every item is a decision about what an audience is for.",
], fill="FBF6EE", accent=AMBER)

for out in (os.path.join(os.path.dirname(SP), "docs",
                         "ORCID-Open-Questions-by-Audience.docx"),
            os.path.join(os.path.expanduser("~"), "Downloads",
                         "ORCID-Open-Questions-by-Audience.docx")):
    d.save(out); print("saved:", out, os.path.getsize(out), "bytes")
