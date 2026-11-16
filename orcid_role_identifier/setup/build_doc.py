# -*- coding: utf-8 -*-
import sys, os
SP = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, SP)
from docx_lib import *
import audiences
from docx.shared import Pt, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH as AL
# The committed figure directory. This said "fig" until 2026-11-03, which was a
# scratch path that existed only on one machine - the builder could not run from
# a clean checkout, and the figures it needs have been committed in doc_figures
# all along.
F = os.path.join(SP, "doc_figures")

d = doc_new()

# ============================================================ TITLE
p = d.add_paragraph(); p.paragraph_format.space_after = Pt(2)
r = p.add_run("ORCID ROLE ENRICHMENT"); r.bold=True; r.font.size=Pt(9.5)
r.font.color.rgb=TEAL; r.font.name=SANS
p = d.add_paragraph(); p.paragraph_format.space_after = Pt(4)
r = p.add_run("Where we are, and what to do next"); r.bold=True
r.font.size=Pt(22); r.font.color.rgb=INK; r.font.name=SANS
para(d, "Working document  ·  updated 16 November 2026  ·  Analytics Engineering, Researcher 360",
     size=9.5, color=MUT, space_after=10)
box(d, "WHERE THIS STANDS", [
 "**All ten audiences are built, and all ten have a measured accuracy.** Every one was "
 "read by hand - 400 people per audience, one record at a time, marked correct, wrong "
 "or not sure. Seven are at 93% or better and the two largest are at 99%. Nothing in "
 "this document is a forecast.",
 "",
 "**Two are not ready, and for different reasons.** *Healthcare Professional (broad)* "
 "is accurate but no longer describes itself: biomedical researchers now roll up into "
 "it, so 54,426 people who have never seen a patient sit in an audience with that name. "
 "*Head of Faculty* is the one weak audience at 83.3%, because the job title is the only "
 "evidence it has. Both are waiting on marketing, not on engineering.",
 "",
 "**The newest audience is Students** - 105,658 people, built and read in November, "
 "98.7% correct and third of the ten.",
 "",
 "**What this document is.** Where the work stands, how it decides, how we know it is "
 "right, and what is still open. The decisions behind each rule, with their "
 "measurements, are recorded separately in the project's open-questions log.",
], fill="F2F6F5", accent=TEAL)

# ============================================================ 1
h(d, "1.  Where we are today")
para(d, "ORCID is where researchers write their own employment history: job title, "
        "organisation, department. All of it is free text. There is no field anywhere "
        "that says what profession someone is. We read that text and work it out.")
# All five rows counted on 2026-11-16 by `analyses/51` query 9. They are
# DISTINCT PEOPLE ACROSS ALL AUDIENCES, which is not the sum of the
# per-audience figures - most people hold two or three roles - so they cannot
# be derived from anything else in this file. Re-run that query after a build
# before quoting them again. Section 1 is the first thing anybody reads, so it
# is the worst place in the project for a stale number.
table(d, ["", "Today", "What it means"],
 [["People with a profession", "**783,293**", "We can name a profession for them"],
  ["Reachable", "**577,603**", "In the CDP and opted in. This is what a campaign can use"],
  ["Audiences", "**10**", "Before this project there was one"],
  ["Different job titles handled", "**315,190**", "The work runs once per title, not once per person"],
  ["Different departments handled", "**458,263**", "Same again, for the subject area"]],
 widths=[2.3,1.1,3.3])
para(d, "**Three quarters of the people we can name are reachable** - 577,603 of 783,293. "
        "The rest are not in the CDP or have not opted in, and no amount of classification "
        "changes that.")
para(d, "The last two rows are the reason this is affordable. We do the thinking once, "
        "over the vocabulary, and store the answers. Giving every person their profession "
        "after that is an ordinary database join.", space_after=10)
fig(d, f"{F}/pipeline.png", 6.6, "How one job title travels through the system.")

# ============================================================ 2
h(d, "2.  One job title, followed all the way")
para(d, "This is the whole system in one example. Everything later in this document "
        "refers back to it.")

box(d, "EXAMPLE 1  —  THE MACHINE DECIDES", [
 "A person typed **Consultant Paediatrician** as their job title.",
 "",
 "`what they typed       Consultant Paediatrician`",
 "`cleaned up            consultant paediatrician`",
 "`nearest example word  consultant`",
 "`how close             0.699 out of 1.00`",
 "",
 "So the title is given the profession **Practitioner**. That answer is stored once and "
 "reused for everyone who ever typed the same thing.",
 "",
 "Now one actual person with that title. They work at a hospital, in a paediatrics "
 "department. Three things are scored and added up:",
 "",
 "`title         0.45 x 0.742  =  0.334`",
 "`organisation  0.15 x 1.000  =  0.150`",
 "`department    0.40 x 1.000  =  0.400`",
 "`                     TOTAL  =  0.884`",
 "",
 "The line for this audience is 0.70. They are in.",
])
para(d, "Now change one thing. Same job title, but the department says mechanical "
        "engineering. This audience needs the title **and** the subject to agree, so the "
        "person is not scored low — they simply do not appear at all. That second check "
        "is what stops a job title alone from putting someone in a healthcare audience.",
     space_after=10)

box(d, "EXAMPLE 2  —  A PERSON OVERRULES THE MACHINE", [
 "The title **junior researcher** appears on 42,949 records. The machine read *junior* "
 "and *senior* as two ends of one idea and filed it as senior - 0.870 confident, and "
 "completely wrong.",
 "",
 "Somebody wrote one line in a file to say: this is early career. **That line wins for "
 "ever and survives every rebuild.**",
 "",
 "This is why every question in this document is cheap to answer. A decision is one "
 "row, it is permanent, and changing your mind later costs the same as deciding now.",
], fill="FAF2F5", accent=PLUM)

# ============================================================ 3
h(d, "3.  The ten audiences")
para(d, "Every figure here is a people figure, counted directly. *Right, of the decided* "
        "leaves out the records a reader marked **not sure** - either a definition that is "
        "not settled or a record that does not say enough to judge. It is never counted "
        "as correct.")
table(d, ["Audience", "People", "Right, of the decided", "Verdict"],
 [["**Lecturer**", "423,668", "**98.7% \u00b1 1.1**", "Solid"],
  ["**Researcher**", "340,705", "**99.0% \u00b1 1.0**", "Solid"],
  ["Healthcare (broad)", "181,295", "90.6% \u00b1 3.0", "**Not weak - undefined.** Waiting on a name"],
  ["Clinical researcher", "108,805", "90.0% \u00b1 3.1", "Good. Grew when biomedical research was ruled in"],
  ["**Students**", "105,658", "**98.7% \u00b1 1.3**", "**New.** Solid"],
  ["Practitioner", "62,141", "93.4% \u00b1 2.6", "Good"],
  ["Head of faculty", "17,218", "83.3% \u00b1 4.4", "**Parked** - not being delivered"],
  ["Clinical administrator", "8,258", "94.9% \u00b1 2.2", "Good. Was 88.9% in October"],
  ["Pharmacist", "2,064", "95.7% \u00b1 1.9", "Good. Was 81.8% in October"],
  ["Librarian", "700", "98.5%", "Solid. All 700 read"]],
 widths=[1.6,0.85,1.3,2.85], size=8.8)
para(d, "Each audience is written out in section 6: how it is decided, how it was "
        "measured, and what is still open in it.", space_after=10)

h(d, "3.1  How much of each audience can actually be reached", 2)
para(d, "Being in an audience and being contactable are different things. **Reachable** "
        "means the person is in the CDP under any of four legal bases - marketing "
        "opt-in, advertising opt-in, legitimate interest, or book-author consent. The "
        "people column below was counted on 10 November, two days before section 3's, "
        "and the Students row on 12 November when that audience was built; the share "
        "reachable is what to read here and it is stable.", space_after=4)
table(d, ["Audience", "People", "Reachable", "Of those"],
 [["**Lecturer**", "410,499", "**319,291**", "77.8%"],
  ["**Researcher**", "333,280", "**237,391**", "71.2%"],
  ["**Healthcare (broad)**", "124,982", "**93,377**", "74.7%"],
  ["**Students**", "105,658", "**68,959**", "**65.3%**"],
  ["**Practitioner**", "61,945", "**46,450**", "75.0%"],
  ["**Clinical researcher**", "54,016", "**39,758**", "73.6%"],
  ["**Head of Faculty**", "15,159", "**11,962**", "78.9%"],
  ["**Clinical administrator**", "7,563", "**5,949**", "78.7%"],
  ["**Pharmacist**", "2,060", "**1,531**", "74.3%"],
  ["**Librarian**", "699", "**384**", "54.9%"]],
 widths=[1.9, 1.1, 1.2, 0.9], size=9)
para(d, "**The rows overlap and must not be added up** - one person can be a Lecturer "
        "and a Clinical researcher at once. **Students is the least reachable of the "
        "ten at 65.3%**, so a campaign gets 68,959 of the 105,658; Librarian is lower "
        "still on a much smaller base. Neither is a classification problem - it is "
        "consent.", space_after=10)

box(d, "WHY HEALTHCARE IS THE HARDEST PART", [
 "Academic titles are nearly the same everywhere: Professor, Associate Professor, "
 "Lecturer. Clinical titles are not. **Resident, Registrar, Facharzt, Interno** and "
 "**Jefe de Servicio** can all mean a doctor in training, and they share no common word.",
 "",
 "Real example: before October we had no example word for anaesthetists, so 2,765 of "
 "them were matched to **neurosurgeon**. And 2,684 veterinarians were matched to "
 "**dentist**, because dentist was the closest word we had given the machine.",
 "",
 "Both are fixed. It is here because it explains why the healthcare audiences sit at "
 "90-95% while the academic ones sit at 99%, and why a clinical expert is still the one "
 "outside source this project has never had.",
], fill="FBF1EF", accent=RED)

# ============================================================ 4
h(d, "4.  The outside sources we now have")
para(d, "Until this month every number in this project came from our own pipeline. That "
        "is a closed loop. We now have three outside sources, and each one can check a "
        "different thing. None of them can check everything.")
fig(d, f"{F}/sources.png", 6.4, "What each outside source can and cannot check for us.")

h(d, "4.1  The role library (the taxonomy)", 2)
para(d, "Market Intelligence keeps a library of 315 job titles with a description, a "
        "sector and a role type for each. Chloe O'Donnell wrote it specifically because "
        "this project reads free text, so it is fuller than the short list they use in "
        "surveys.")
para(d, "**What it confirms.** 48 of our 151 example words appear in it. That is the first "
        "time anybody outside this project has checked our vocabulary.")
para(d, "**What it cannot check.** 103 of our example words are not in it, and they are "
        "not random:", space_after=4)
fig(d, f"{F}/taxonomy_blindspot.png", 6.3,
    "Our example words the taxonomy does not list, by profession.")
box(d, "WHAT THIS MEANS IN PLAIN TERMS", [
 "The role library is a **research career** taxonomy, not a **medical** one. Its "
 "healthcare section has Physician, Clinician, Surgeon and Healthcare Professional. It "
 "has no list of specialties at all — no cardiologist, no anaesthetist, no midwife, no "
 "veterinarian.",
 "",
 "It is also written in English, so every foreign word we use is missing: "
 "`dirigente medico`, `apotheker`, `pharmacien`, `eczaci`, `docente`, `dozent`, "
 "`wissenschaftlicher mitarbeiter`.",
 "",
 "**Three conclusions.** The 39 clinical example words we added in October were not "
 "redundant. We still need a clinical expert. And the taxonomy cannot check the "
 "multilingual half of our dictionary, which is exactly where our worst mistakes have "
 "been.",
])

h(d, "4.2  The survey answers", 2)
para(d, "Market Intelligence asks people their job title in most surveys. It is a closed "
        "question with 21 options, so the answers are clean. Crucially, some surveys also "
        "record the person's email address, which means we can match them to our own "
        "output.")
table(d, ["Export", "Rows", "What it gives us"],
 [["Journal Author Satisfaction","109,396","Email + the job title the person picked for themselves"],
  ["Researcher Panel members","232,648","Opt-in email + self-selected job title"]],
 widths=[1.9,0.9,3.9])
para(d, "**Both exports arrived on 30 October and have been used.** 290,045 unique "
        "people after deduplication, 93.2% of whom could be mapped onto one of our ten "
        "professions. Section 5 has the result. The headline: 81.8% of the people we "
        "classified were put in the audience they put themselves in, against a ceiling "
        "of 88.9%.")
box(d, "WHAT IT WILL AND WILL NOT TELL US", [
 "**It will tell us** where our profession disagrees with what the person says they do. "
 "That is a real external check and we have never had one.",
 "",
 "**It will not give us an accuracy percentage.** The people in these surveys are a "
 "selected group: they publish, and they answer surveys. Librarians and students are "
 "barely in it. So it checks the research core well and the edges not at all.",
 "",
 "**And the 21 options do not line up with our 10 groups.** The survey has Masters "
 "Student and PhD Student separately; we have one Student group. The survey has no "
 "pharmacist option and no librarian option at all, so those two audiences cannot be "
 "checked this way.",
], fill="FDF8EF", accent=AMBER)


# ============================================================ 5
h(d, "5.  How we know it is right")
para(d, "Two independent checks, and they answer different questions. Neither alone is "
        "the answer.")

h(d, "5.1  Read by hand - the number quoted everywhere else", 2)
para(d, "400 CONFIRMED people per audience, drawn at random, read one record at a time "
        "and marked correct, wrong or not sure. All 700 librarians were read. That is "
        "where every percentage in section 3 comes from, and it is the measurement this "
        "project trusts most, because somebody looked at each row.")

h(d, "5.2  Against what people say about themselves", 2)
para(d, "Market Intelligence exported two surveys in which people picked their own job "
        "title from a fixed list and gave an email address - 290,045 people after "
        "deduplication. That let us compare our answer to the person's own answer.")
box(d, "PEOPLE DISAGREE WITH THEMSELVES 11% OF THE TIME", [
 "34,372 of them answered both surveys, so they declared their own job twice:",
 "",
 "`same person, two surveys, same profession   88.9%`",
 "`same person, two surveys, same words         60.6%`",
 "",
 "So **88.9% is the ceiling**. Nothing we do can score meaningfully above it, and 85% "
 "would be close to perfect rather than poor. Their disagreements are real rather than "
 "careless - 627 said professor in one and research scientist in the other, 523 "
 "professor and editor, 180 student and academic.",
 "",
 "Measuring this first is the point. Without it we would have compared our own number "
 "against an implied 100% and called a good result a failure.",
])
para(d, "Measured against the people who did not contradict themselves: **81.8% of the "
        "people we classified were put in the audience they put themselves in**, against "
        "that ceiling of 88.9%.")

h(d, "5.3  Three things this check cannot do", 2)
bullet(d, "**It is not an accuracy rate.** Self-declaration is a second opinion, not a "
          "fact. People pick one option from a list to describe a life that has several - "
          "a professor who runs a research group is both, and the survey takes one.")
bullet(d, "**The population is selected.** These are people who publish and who answer "
          "surveys. Librarians appear seven times. Students and support staff are barely "
          "represented, and there is no pharmacist option at all - so three of the ten "
          "audiences cannot be checked this way.")
bullet(d, "**The real limit is coverage, not accuracy.** Of the 290,045 respondents we "
          "could match 238,440 to somebody in the CDP, and then knew the job of only "
          "**46,656** - a quarter. The rest have no ORCID employment record to read. That "
          "confirms from outside what this project has said from inside: the ceiling is "
          "how many people we can say anything about at all, not how often we are right "
          "about the ones we can.")
para(d, "It is also repeatable. The comparison is a query, so it re-runs after every "
        "change as a regression check. That is worth more than the single number.",
     space_after=10)

# ============================================================ 6
audiences.build(d, F)

# ============================================================ 7
h(d, "7.  What happens next")
table(d, ["#", "What", "Why now", "Who"],
 [["1","**What \"Healthcare Professional (broad)\" means**","The only thing that blocks us. Biomedical researchers now roll up into it, so 54,426 people who have never seen a patient are in an audience with that name. One sentence from marketing settles it.","Marketing"],
  ["2","A rule for the bare qualification","`PhD`, `Ph.D`, `Master`, `Bachelor` used as the whole job title — 6% of the Students reading and the single largest source of doubt in it. A degree is a credential, not a status, and one record says `Phd holder` outright. `analyses/51` queries 8 and 8b size it and list the real spellings.","Us"],
  ["3","A country condition on `research scholar`","It is a `student` anchor, so it matches at score 1.0 with no country test. In India it means a doctoral student; elsewhere it can be a senior post. Found in the Students reading.","Us"],
  ["4","**A decision-maker audience**","Marketing have asked for Head of Faculty to be opened up beyond academia, to reach opinion leaders, budget holders and purchase influencers. Seven definition questions are with them; the measurement on our side can start before they answer.","Marketing / us"],
  ["5","Clinical expert call","The one gap no data source covers - see the box in section 3.","Merve / Bernadeta"],
  ["6","Reach the survey data in BigQuery","Chloe pointed at `Staging_Response`. Would make the check repeatable instead of a one-off export.","Us / data eng"],
  ["7","A second source for Head of Faculty","It is parked, not delivered, until there is something besides the job title to test a vague one against. Item 4 may change what this audience is for.","Us"]],
 widths=[0.3,1.8,3.2,1.3], size=9)

box(d, "WHAT CAME OFF THIS LIST", [
 "**Statisticians and economists are settled** — the 2,177 records in no audience stay "
 "out. They were never read title by title, and an audience is something a title earns "
 "by being read, not by resembling one that was.",
 "",
 "**The Students audience is built, delivered and read** — 105,658 people, 98.7% over "
 "400 records. Internships count, company graduate trainees do not, current posts only, "
 "one bucket for all levels, and the employer must be a university. Every decision on "
 "the old item 3 held as written.",
 "",
 "**The fourth consent basis is in.** `is_book_author_communications_opted_in` is part of "
 "the reachable figure everywhere it is quoted.",
 "",
 "**The synonym check ran and found something bigger than a synonym split**: the "
 "dictionary's record counts had frozen the first time each job title was seen and were "
 "running 14 to 30 times high. Fixed. It never touched the classification, so no audience "
 "changed and no decision was taken on a wrong basis — but every *records* figure quoted "
 "from the dictionary before 11 November was wrong. Section 3 used to be the main place "
 "they survived in this document; it now shows people and accuracy only.",
 "",
 "**A title may now name two jobs**, which was the other thing folded into that build. "
 "7,144 of the Students arrived that way, and so did the biomedical researchers behind "
 "item 1.",
])
box(d, "HOW THE 145 WERE RESOLVED — AND THE PATTERN TO REMEMBER", [
 "Moving **medical director** into Leadership was right for the Clinical Administrator "
 "audience. But Leadership feeds **two** audiences, and we only wanted one of them:",
 "",
 "`leadership  ->  hcp_administrator   (what we wanted)`",
 "`            ->  faculty_head        (what we did not)`",
 "",
 "The arithmetic lets a hospital medical director straight through:",
 "",
 "`0.60 x 1.000  (the title, forced to full marks by our correction)`",
 "`0.40 x 0.500  (a hospital)`",
 "`       TOTAL   0.800     the line for Head of Faculty is 0.65`",
 "",
 "**Measured: 145 people.** That is 0.7% of Head of Faculty. Small — except that this is "
 "the one audience built for precision rather than reach, so being right matters more "
 "here than anywhere else.",
 "",
 "**Why there is no easy fix.** The system has no way to say 'this title must not feed "
 "that audience'. The only veto that exists works on the organisation name, not the job "
 "title. So the choices are all compromises:",
], fill="FBF1EF", accent=RED)
table(d, ["Option", "What it costs"],
 [["Lower the hospital score for Head of faculty",
   "Would have to drop from 0.50 to below 0.125, which removes **every** head of faculty whose record names a hospital — including real medical school deans"],
  ["Move `medical director` back to Practitioner",
   "Fixes this, but puts them back in an audience for people who treat patients, which they do not"],
  ["Accept the 145 and record it",
   "Honest, costs nothing, leaves a known error in the audience we most want to be right"],
  ["Build a title-level exclusion",
   "The proper fix. A model change plus a new test, for 145 people"]],
 widths=[2.2,4.4], size=9)
para(d, "**Both measurements came back on 29 October.** `medical director` added 198 "
        "people to Clinical Administrator, so the move itself was worth it. And the "
        "hospital path into Head of Faculty carried about 2,000 people — 826 `director`, "
        "294 `head of department`, 17 `dean` — so lowering the score would have cost far "
        "more than the 95 medical directors it removed.", space_after=4)
para(d, "**The decision went further than the measurement suggested.** Rather than trade "
        "one group off against another, Merve took the whole hospital path out: Head of "
        "Faculty is university heads only. It is the one audience built for precision "
        "rather than reach, there is no second signal available in it, and coverage can "
        "come back later from a faculty-leadership source. The ~2,000 leave knowingly.",
        space_after=4)
para(d, "This is worth reading twice, because it is the shape of problem we will keep "
        "meeting: **a correction that is right for one audience is wrong for another, "
        "because they share a group.** Nothing in the current design separates them.")


# See the note in build_mkt.py: the committed copy is the one Merve pulls.
for out in (os.path.join(os.path.dirname(SP), "docs", "ORCID-Role-Enrichment-Status-and-Plan.docx"),
            os.path.join(os.path.expanduser("~"), "Downloads", "ORCID-Role-Enrichment-Status-and-Plan.docx")):
    d.save(out)
    print("saved:", out, os.path.getsize(out), "bytes")
