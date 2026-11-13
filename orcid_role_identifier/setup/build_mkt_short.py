# -*- coding: utf-8 -*-
# Builds docs/ORCID-Audiences-One-Pager.docx - the SHORT version of the
# marketing questions, for reading in a meeting rather than before one.
#
# WHY IT EXISTS. Merve, 2026-11-12: "docs cok karisik ... yarin toplantida bu
# docxi gondermek yerine onlara birkac tablo, suan ne durumdayiz kisa ozet,
# hangi audience lar iyi hangileri kotu durumda, sonra questionlari da bize en
# cok kisi kaybettiren veya kazandiran veya en cok impacti olan karardan en aza
# sirala." ORCID-Questions-for-Marketing.docx stays as the full reference; this
# is what goes in the room.
#
# EVERY FIGURE HERE IS A PEOPLE FIGURE, deliberately. analyses/50 query 2g
# found on 11 November that dim_title_group.frequency froze the first time each
# title was embedded and ran 14-30x high, so every RECORD count in the long
# document is inflated. People figures are counted from fct_researcher_roles
# and stg_role_records and were never affected. Where a question's size was
# only ever a record count, this says so rather than quoting it.
import sys, os
SP = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, SP)
from docx_lib import *
from docx.shared import Pt

d = doc_new()

p = d.add_paragraph(); p.paragraph_format.space_after = Pt(2)
r = p.add_run("ORCID ROLE ENRICHMENT"); r.bold = True; r.font.size = Pt(9.5)
r.font.color.rgb = PLUM; r.font.name = SANS
p = d.add_paragraph(); p.paragraph_format.space_after = Pt(4)
r = p.add_run("Where the nine audiences stand, and what we need you to decide")
r.bold = True; r.font.size = Pt(19); r.font.color.rgb = INK; r.font.name = SANS
para(d, "13 November 2026  ·  Analytics Engineering  ·  one page, then the calls",
     size=9.5, color=MUT, space_after=10)

para(d, "We read the job title, employer and department that researchers typed into "
        "their own ORCID record, and sort them into ten audiences. All ten are built "
        "and all ten have been measured. Nothing below is a forecast.",
     space_after=12)

# ------------------------------------------------------------- THE AUDIENCES
h(d, "The ten audiences today")
table(d, ["Audience", "People", "Right, of the decided", "Where that comes from", "Verdict"],
 [["**Lecturer**", "423,668", "**98.7% ± 1.1**", "400 read one by one", "Solid"],
  ["**Researcher**", "340,705", "**99.0% ± 1.0**", "400 read one by one", "Solid"],
  ["Healthcare (broad)", "181,295", "90.6% ± 3.0", "400 read one by one",
   "**Not weak — undefined.** Question 1"],
  ["Clinical researcher", "108,805", "90.0% ± 3.1", "400 read one by one",
   "Good. Grew with question 1"],
  ["**Students**", "105,658", "**97.8% ± 3.6**", "100 of 400 read so far",
   "**New.** 300 still to read"],
  ["Practitioner", "62,141", "93.4% ± 2.6", "400 read one by one", "Good"],
  ["Head of faculty", "17,218", "83.3% ± 4.4", "400 read one by one",
   "**Parked** — not being delivered"],
  ["Clinical administrator", "8,258", "94.9% ± 2.2", "400 read one by one",
   "Good. Was 88.9% in October"],
  ["Pharmacist", "2,064", "95.7% ± 1.9", "400 read one by one",
   "Good. Was 81.8% in October"],
  ["Librarian", "700", "98.5%", "all 700 read", "Solid"]],
 widths=[1.45, 0.7, 1.15, 1.25, 2.05], size=8.8)
para(d, "*Right, of the decided* leaves out the rows a reader marked **not sure**. Not sure "
        "means one of two things: a definition you have not settled yet, or a record that "
        "does not say enough to judge. It is never counted as correct.",
     size=9, color=MUT, space_after=12)

box(d, "THE WHOLE PICTURE IN THREE LINES", [
 "**Seven of the ten are at 93% or better**, and the two biggest are at 99%. These are "
 "safe to use today. The People column is a 12 November count and grows a little every "
 "week, because ORCID is added to continuously.",
 "",
 "**Head of Faculty is parked and is not being delivered.** It is the one weak audience "
 "at 83.3%, and the cause is not a bug: it is the only audience where the job title is "
 "the *only* evidence we have, so a vague title has nothing to contradict it. We are "
 "waiting on a second source before we offer it.",
 "",
 "**Healthcare (broad) is not inaccurate — it is undefined.** It does what we built it to "
 "do; we just can no longer say in one sentence who is in it. That is question 1, and it "
 "is the only thing on this page that blocks us.",
])

# ------------------------------------------------------------------ THE CALLS
h(d, "What we need from you, biggest first")
table(d, ["", "The call", "How many people it moves", "Urgency"],
 [["1", "**What should \"Healthcare Professional (broad)\" mean?**",
   "181,295 in it — 54,426 of them arrived this month", "**Blocks us**"],
  ["2", "Is a bare `dr` plus a clinical department enough to call someone clinical?",
   "Large", "Medium"],
  ["3", "Are visiting scholars and visiting fellows teaching staff?",
   "Large", "Medium"],
  ["4", "Should a job someone has left still count?",
   "Affects seven of the ten audiences", "Medium"],
  ["5", "Is an honorary professor still an active academic?", "Medium size", "Medium"],
  ["6", "Do statisticians and economists belong in an audience at all?",
   "In no audience today", "Medium"],
  ["7", "Does Students mean doctoral candidates, or every student?",
   "Master's and undergraduate students are in it today", "Medium"],
  ["8", "Are veterinarians healthcare professionals?", "91", "Low"],
  ["9", "Is sport and exercise science a healthcare field?", "78", "Low"],
  ["10", "Two titles we chose to keep out of Librarian",
   "Small", "Low"]],
 widths=[0.3, 2.95, 2.1, 0.85], size=8.8)
para(d, "Every one of these is reversible in one line of configuration. Changing an answer "
        "later is cheap — **leaving it open is what costs us**, because until it is settled "
        "we cannot tell you what an audience means.", space_after=12)

# ------------------------------------------------------- THE THREE THAT MATTER
h(d, "1.  What should \"Healthcare Professional (broad)\" mean?")
para(d, "You told us on 11 November that biomedical researchers are healthcare "
        "professionals, and we have implemented it. It works. But it has a consequence "
        "worth one minute of your time.")
para(d, "Biomedical researchers enter *Clinical researcher*, and because that audience "
        "rolls up into *Healthcare Professional (broad)*, they enter the broad one too. It "
        "is built now, so this is a count and not an estimate: Clinical researcher went "
        "from 50,600 to **108,805** and the broad audience from 126,869 to **181,295**. So "
        "**54,426 people** who have never seen a patient joined an audience called "
        "*Healthcare Professional* this month. Nothing is broken — the name is simply no "
        "longer describing the audience.")
para(d, "**Two ways out, and we recommend the first.** Rename it, because *Practitioner* "
        "already is the clinical audience at 46,526 reachable people and nobody needs two "
        "of those. Or stop rolling researchers up into it, which keeps the name and "
        "shrinks the audience.")
para(d, "**What we need is one sentence from you:** who is in Healthcare Professional "
        "(broad), and what should it be called on a campaign brief.", space_after=12)

h(d, "2.  Is a bare `dr` plus a clinical department enough?")
para(d, "A record that says only *Dr* in an oncology department tells us the person is "
        "medically qualified and works in a clinical setting, but not what they do. We "
        "currently accept it as clinical evidence. Saying no makes the healthcare "
        "audiences smaller and more certain; saying yes keeps them as they are.",
     space_after=12)

h(d, "The remaining seven, one line each")
bullet(d, "**3  Visiting scholars and fellows** — in Lecturer today. They teach, but the "
          "post is temporary and often unpaid.")
bullet(d, "**4  Past jobs** — seven of the ten audiences count a job someone has left. A "
          "researcher in 2010 who runs a bakery today is still in Researcher. Head of "
          "Faculty, Librarian and Students already use current posts only.")
bullet(d, "**5  Honorary professors** — in Lecturer today. The title is usually a mark of "
          "respect rather than a job.")
bullet(d, "**6  Statisticians and economists** — in no audience at all today. Their titles "
          "name a discipline, not a job we recognise. A third of the family is already in "
          "Lecturer correctly, as *professor of biostatistics*.")
bullet(d, "**7  What Students means** — it is *Student / Doctoral Candidate* today and it "
          "contains master's and undergraduate students too, because that is what people "
          "wrote. If a campaign means doctoral candidates only, say so and we will narrow "
          "it. Separately: it is university employers only, which means a PhD student at a "
          "research institute or a teaching hospital is not in it.")
bullet(d, "**8  Veterinarians** — 91 people, in the healthcare audiences today by accident "
          "rather than by decision.")
bullet(d, "**9  Sport and exercise science** — 78 people, same situation.")
bullet(d, "**10  Librarian exclusions** — we keep out archivists, because the word also "
          "collected archaeologists and glaciologists, and *information specialist*, "
          "because it collected every IT job in the data.")
d.paragraphs[-1].paragraph_format.space_after = Pt(12)

# ------------------------------------------------------------- HONESTY NOTE
box(d, "TWO THINGS ABOUT THE NUMBERS ON THIS PAGE", [
 "**Every figure here is a people figure, counted directly on 12 November.** Earlier "
 "versions sized some questions in *records*, from a column we found to be defective on "
 "11 November — it froze the first time each job title was seen and had been running 14 "
 "to 30 times high. It is fixed, it never touched the classification, and no audience "
 "changed and no decision was taken on a wrong basis. The sizes on this page do not come "
 "from it.",
 "",
 "**Students is measured on 100 records, not 400.** Its 97.8% sits with the strongest "
 "audiences, but on a quarter of the reading every other audience had — so the true "
 "figure could be anywhere from 94% to 99%. The remaining 300 are being read now, and "
 "they will be done before anybody runs a campaign on it.",
], fill="FBF6EE", accent=AMBER)

for out in (os.path.join(os.path.dirname(SP), "docs",
                         "ORCID-Audiences-One-Pager.docx"),
            os.path.join(os.path.expanduser("~"), "Downloads",
                         "ORCID-Audiences-One-Pager.docx")):
    d.save(out); print("saved:", out, os.path.getsize(out), "bytes")
