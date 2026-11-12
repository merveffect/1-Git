# -*- coding: utf-8 -*-
# Builds docs/AI-REVIEWER-RULES.docx. The markdown twin is
# docs/AI-REVIEWER-RULES.md - this is the version that gets sent over Teams and
# pasted into Word, where raw markdown would arrive as ## and pipe characters.
#
# ONE SECTION PER AUDIENCE AND NOTHING ELSE. The first version of this document
# ran to 289 lines of mechanism, history and measured failures. Merve, 11 Nov:
# "bu kadar detaya gerek var miydi? sadece bizim bu audienceler icin
# uyguladigimiz kurallari yaz." A reviewer needs the rule in force, not how it
# came to be - the history lives in docs/open-questions.md.
import sys, os
SP = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, SP)
from docx_lib import *
from docx.shared import Pt

d = doc_new()

p = d.add_paragraph(); p.paragraph_format.space_after = Pt(2)
r = p.add_run("ORCID ROLE ENRICHMENT"); r.bold = True; r.font.size = Pt(9.5)
r.font.color.rgb = PLUM; r.font.name = SANS
p = d.add_paragraph(); p.paragraph_format.space_after = Pt(4)
r = p.add_run("Audience rules, as the pipeline applies them today")
r.bold = True; r.font.size = Pt(20); r.font.color.rgb = INK; r.font.name = SANS
para(d, "Reference for the AI reviewing audience membership  ·  12 November 2026  ·  "
        "Analytics Engineering", size=9.5, color=MUT, space_after=10)

para(d, "One section per audience. For each row you are asked: **does the evidence "
        "satisfy this audience's rule?**")
para(d, "You are only shown CONFIRMED rows. The second confidence tier is never "
        "delivered, so it is not what you are judging.", space_after=12)


def aud(name, label, lines):
    h(d, name + "  —  " + label, 2)
    for t in lines:
        bullet(d, t)
    d.paragraphs[-1].paragraph_format.space_after = Pt(9)


aud("researcher", "Researcher (all fields)", [
 "**Title must name** research work: researcher, scientist, postdoc, research fellow, "
 "research associate, principal investigator, group leader.",
 "**Field: ANY. There is no department check at all.** A plant pathologist, an "
 "astrophysicist and a medieval historian are all correct. **Never mark `field_wrong` "
 "on a Researcher row.**",
 "**Organisation:** any. University and research institute score highest, company "
 "lowest. Nothing is excluded.",
 "**Excluded:** `emeritus`, `retired`, `honorary researcher`. Also `phd student`, "
 "`phd candidate`, `phd fellow` — a doctoral student is only a researcher if the "
 "title itself names research, as `doctoral researcher` does.",
 "**Past posts count.** A researcher in 2010 working in a bank today is still correct.",
])

aud("lecturer", "Lecturer / Teaching Academic", [
 "**Title must name** a teaching or academic post: professor, lecturer, reader, "
 "docent, instructor, tutor, teaching assistant.",
 "**Field:** no department check.",
 "**Organisation:** any. Education scores highest, company lowest.",
 "**Excluded:** `emeritus professor`, `retired professor`. School teachers are in by "
 "default and were measured at 0.2% of the group.",
 "**Past posts count.**",
])

aud("librarian", "Librarian / Information Professional", [
 "**Title must contain** a library word. Decided by literal pattern rather than "
 "similarity, so it is always a certain match.",
 "**Field:** none. **Organisation: irrelevant** — it carries zero weight here.",
 "**Excluded by choice:** archivists, because the word pulled in archaeologists, "
 "glaciologists and clerks. And `information specialist`, because it pulled in every "
 "IT job in the data.",
 "**CURRENT POSTS ONLY.**",
])

aud("pharmacist", "Pharmacist", [
 "**Title must name a pharmacist. The title is the only way in** — nobody becomes a "
 "pharmacist by working in a pharmacy department.",
 "**Field:** a pharmacy department adds score but is not required.",
 "**Organisation:** any. Hospital highest, then company, then university.",
 "**Excluded:** pharmacology and pharmaceutical-science academics — `pharmacolog`, "
 "`pharmacognos`, `pharmaceutic`, `medicinal chem`. A professor of pharmacology is an "
 "academic, not a pharmacist. Also pharmacy students and pharmacy technicians.",
 "**Past posts count.**",
])

aud("faculty_head", "Head of Faculty / Department", [
 "**Title must name a faculty-level post:** dean, head of department, head of school, "
 "rector, provost, pro-vice-chancellor, chancellor.",
 "**Field:** none. **The title and the employer are the only two signals**, so there "
 "is nothing to contradict a wrong title. This is why its accuracy is the lowest of "
 "the nine.",
 "**Organisation: EDUCATION ONLY.** Every other ROR type scores zero, including an "
 "unresolved one — no hospitals, no research institutes, no companies, no national "
 "labs, nobody whose employer could not be identified. **So never mark a faculty_head "
 "row wrong for its organisation. It is already verified.**",
 "**Excluded:** named chairs — `endowed chair`, `chair professor of X`, `canada "
 "research chair` are professorships, not leadership. Also `editor-in-chief`.",
 "**CURRENT POSTS ONLY.**",
])

aud("hcp_broad", "Healthcare Professional (broad)", [
 "**Title must name a clinical role. THE TITLE IS MANDATORY** — a clinical department "
 "alone is not enough. An administrator in a cardiology department is out.",
 "**Field:** a human-health department adds most of the score.",
 "**Organisation:** any except archive. Hospital highest.",
 "**It also contains everyone who ROLLS UP** from hcp_practitioner, hcp_researcher, "
 "hcp_administrator and pharmacist. **Check `reached_via`:** if it names a child "
 "audience, that child's rule is the one that has to hold.",
 "**Past posts count.**",
])

aud("hcp_practitioner", "Healthcare Practitioner", [
 "**Title must name a clinician who treats patients** AND **the field must be a "
 "human-health department.** Both are required.",
 "**Organisation:** any except archive. Hospital highest.",
 "**Past posts count.**",
])

aud("hcp_researcher", "Clinical / Biomedical Researcher", [
 "**Title must name research** AND **the field must be a human-health OR a biomedical "
 "department.** Both required.",
 "**PATIENT CONTACT IS NOT REQUIRED.** A clinical trials statistician in an oncology "
 "department is correct.",
 "**Organisation:** any, nothing excluded.",
 "**Past posts count.**",
])

aud("students", "Student / Doctoral Candidate", [
 "**Title must name a student.** PhD student, doctoral candidate, graduate "
 "student, master's student, postgraduate - and `doctoral researcher` and "
 "`postgraduate researcher`, which name research but describe a doctoral "
 "student. **The title is the only way in**; there is no department check.",
 "**Organisation: EDUCATION ONLY.** Every other ROR type scores zero, an "
 "unresolved employer included. **So never mark a students row wrong for its "
 "organisation — it is already a university.** This was measured and "
 "reaffirmed: it refuses 10,316 people whose titles say `phd student` at "
 "research institutes, teaching hospitals and research councils, because ROR "
 "does not type those as Education. Those people are not in your sample.",
 "**Excluded:** company graduate trainees — `graduate trainee`, `management "
 "trainee` — who are employees being trained, not students. The employer rule "
 "removes them, so you will not see them either.",
 "**CURRENT POSTS ONLY.** A finished PhD is not a student. This is the one "
 "rule that cost the audience most: 61,209 people were removed by it, and "
 "they are today's professors and postdocs.",
 "**Nothing is read from the education section of the profile.** A person's "
 "degrees are not evidence here — only the employment title is. So do not "
 "mark a row correct because the person obviously studied somewhere.",
])

aud("hcp_administrator", "Clinical Leadership / Administration", [
 "**Title must name a leadership post** AND **the field must be a human-health "
 "department.** Both required.",
 "**PATIENT CONTACT IS NOT REQUIRED.** Somebody running a cardiology unit is correct.",
 "**Organisation: company and funder score zero** — an industry medical director is "
 "deliberately out.",
 "**Past posts count.**",
])

# ------------------------------------------------------------------ UNSURE
h(d, "Mark UNSURE here — these are open questions, not errors")
table(d, ["What you see", "Code"],
 [["A title that is only `director`, `chair` or `head` with no faculty word beside it "
   "— 15% of faculty_head", "`ambiguous_word`"],
  ["`consultant` outside Britain and Ireland — it means business adviser in the US, "
   "where 0.20 of them have a clinical department against 0.68 in Britain. "
   "**Use `country_code`**", "`ambiguous_word`"],
  ["A title that is the single word `Fellow` — a trainee physician in the US, a "
   "researcher in the UK", "`ambiguous_word`"],
  ["A veterinary department in a healthcare audience", "`field_wrong`"],
  ["`Faculty of Sport Sciences` or `Sport and Health Sciences` in a healthcare "
   "audience", "`field_wrong`"],
  ["`statistician`, `medical statistician`, `economist`", "`title_wrong`"],
  ["`honorary professor`", "`ended_role`"],
  ["`visiting scholar`, `visiting fellow` in Lecturer", "`ambiguous_word`"],
  ["A psychologist in a clinical audience", "`ambiguous_word`"],
  ["`dr` or `md` alone", "`uninformative`"],
  ["`md phd` or `md/phd` in Students — a US MD-PhD programme student, or a "
   "qualified physician listing two degrees. The same credential-versus-status "
   "problem as a bare `phd`", "`ambiguous_word`"],
  ["`research scholar` in Students — a doctoral student in India, a senior "
   "visiting post elsewhere. **Use `country_code`**", "`ambiguous_word`"],
  ["`student` with no level in Students, where the employer is a school rather "
   "than a university — a school pupil is not the audience", "`title_wrong`"],
  ["`trainee` alone in Students at a hospital — a clinical trainee belongs to "
   "trainee_clinical, not here", "`title_wrong`"],
  ["A title in a language you cannot read with confidence", "`language`"]],
 widths=[4.6, 1.5], size=9)

box(d, "TWO THINGS THAT ARE NOT ERRORS", [
 "**A low score on a long title.** A verbose string dilutes every match it contains, "
 "so it scores lower than the same job stated briefly. Judge the words, not the "
 "number.",
 "",
 "**Whether the person still holds the job.** Only use `ended_role` when the title "
 "itself says the post has ended — emeritus, retired, a closed date range.",
])

h(d, "How to behave")
para(d, "UNSURE is a real verdict and is excluded from the accuracy figure, so do not "
        "guess to avoid it. Judge what the person typed, not what they probably do. "
        "Give a reason code on every WRONG and UNSURE — **the code matters more than "
        "the verdict**. Do not spread verdicts to look balanced: if 95 of 100 are "
        "correct, say so.")

for out in (os.path.join(os.path.dirname(SP), "docs", "AI-REVIEWER-RULES.docx"),
            os.path.join(os.path.expanduser("~"), "Downloads",
                         "AI-REVIEWER-RULES.docx")):
    d.save(out); print("saved:", out, os.path.getsize(out), "bytes")
