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
para(d, "Working document  ·  updated 20 November 2026  ·  Analytics Engineering, Researcher 360",
     size=9.5, color=MUT, space_after=10)
box(d, "WHERE THIS STANDS", [
 "**All ten audiences are built, and all ten have a measured accuracy.** Every one was "
 "read by hand - 400 people per audience, one record at a time, marked correct, wrong "
 "or not sure. Seven are at 93% or better and the two largest are at 99%. Nothing in "
 "this document is a forecast.",
 "",
 "**One is not ready, and it is not an accuracy problem.** *Head of Faculty* is the one weak audience at 83.3%, because the job title is the only evidence it has, and it is "
 "parked rather than delivered. *Healthcare Professional (broad)* used to sit beside it here and no longer does: marketing settled on 20 November that the audience means what "
 "its name says in their vocabulary, biomedical researchers included, and that it is not being renamed. The 54,426 people who have never seen a patient are in it on purpose.",
 "",
 "**The newest audience is Students** - 102,026 people, built and read in November, "
 "98.7% correct and third of the ten.",
 "",
 "**Practitioner is about 5,400 people smaller than it was last week, on purpose.** Every job title containing the word *consultant* was taken out of it on 19 November. The word means a hospital specialist in Britain and Ireland and a business adviser almost everywhere else, and the record does not say which. The audience is smaller and more certain; section 6 gives the number and the reasoning.",
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
# All five rows counted on 2026-11-19 by `analyses/51` query 9. They are
# DISTINCT PEOPLE ACROSS ALL AUDIENCES, which is not the sum of the
# per-audience figures - most people hold two or three roles - so they cannot
# be derived from anything else in this file. Re-run that query after a build
# before quoting them again. Section 1 is the first thing anybody reads, so it
# is the worst place in the project for a stale number.
#
# ⭐ THE FIRST TWO ROWS AND THE LAST TWO ARE NOT THE SAME AGE, and the table
# now says so. stg_role_records and the whole staging chain are VIEWS, so the
# people counts read live ORCID every time the scoring models are rebuilt.
# int_title_distinct and int_department_distinct are TABLES and sit UPSTREAM of
# a `--select <seed>+` build, so they are not rebuilt by one: rows 4 and 5 are
# frozen at the last dictionary build and did not move on 19 November while the
# people counts grew by 3,764. Quoting a people-per-title ratio off this table
# would divide a live number by a stale one.
table(d, ["", "Today", "What it means"],
 [["People with a profession", "**783,990**", "We can name a profession for them"],
  ["Reachable", "**577,722**", "In the CDP and opted in. This is what a campaign can use"],
  ["Audiences", "**10**", "Before this project there was one"],
  ["Different job titles handled", "**319,032**", "The work runs once per title, not once per person"],
  ["Different departments handled", "**458,263**", "Same again, for the subject area"]],
 widths=[2.3,1.1,3.3])
para(d, "**Three quarters of the people we can name are reachable** - 577,722 of 783,990. "
        "The rest are not in the CDP or have not opted in, and no amount of classification "
        "changes that.")
para(d, "**Counted on the 20 November build, and the first row went DOWN.** 3,067 "
        "fewer people have a profession at all than a day earlier, even though ORCID "
        "grew. Worth knowing before anybody reads that as a regression: for some people "
        "Students or Lecturer was the ONLY audience they were in - a bare *PhD* at a "
        "university is in Students and nothing else - so excluding a title does not move "
        "those people to another audience, it empties them. 8,560 people left an "
        "audience on 20 November and 3,067 of them lost their profession entirely; the "
        "rest hold a second role that keeps them named.", size=9, color=MUT)
para(d, "**The first two rows and the last two are not the same age either.** The "
        "people counts read ORCID live. The vocabulary counts are rebuilt deliberately "
        "rather than continuously, and the two halves of the vocabulary do not even "
        "move together. **Measured on this build:** the job titles went from 315,190 to "
        "319,032 and the departments did not move by a single record, because the title "
        "dictionary sits upstream of the model that was rebuilt and the department one "
        "does not. So row 4 is a 20 November figure and row 5 is still the one from the "
        "last dictionary build. Worth knowing before dividing one of them by the "
        "other.", size=9, color=MUT)
para(d, "The last two rows are the reason this is affordable. We do the thinking once, "
        "over the vocabulary, and store the answers. Giving every person their profession "
        "after that is an ordinary database join.", space_after=10)
fig(d, f"{F}/pipeline.png", 6.6, "How one job title travels through the system.")

# ============================================================ 2
h(d, "2.  One job title, followed all the way")
para(d, "This is the whole system in one example. Everything later in this document "
        "refers back to it.")

box(d, "EXAMPLE 1  —  THE MACHINE DECIDES", [
 "A person typed **Attending Doctor** as their job title. 333 people did.",
 "",
 "`what they typed       Attending Doctor`",
 "`cleaned up            attending doctor`",
 "`nearest example word  attending physician`",
 "`how close             0.923 out of 1.00`",
 "",
 "**Nobody told the system that a doctor and a physician are the same job.** It worked "
 "that out from the words alone, and that is the whole point of this step: people do not "
 "type the words we would have chosen. The title is given the profession "
 "**Practitioner**, and that answer is stored once and reused for everyone who ever "
 "typed the same thing.",
 "",
 "Now one actual person with that title. They work at a hospital, in an anaesthesiology "
 "department. Three things are scored and added up:",
 "",
 "`title         0.45 x 0.934  =  0.420`",
 "`organisation  0.15 x 1.000  =  0.150`",
 "`department    0.40 x 1.000  =  0.400`",
 "`                     TOTAL  =  0.970`",
 "",
 "The line for this audience is 0.70. They are in.",
 "",
 "**0.923 became 0.934** because a raw similarity never reaches 1.00 in practice and "
 "anything under 0.65 is thrown away, so the surviving range is stretched onto a scale "
 "where the weakest match we accept reads as 0.70. It adds no information - it makes the "
 "number mean what it looks like.",
])
para(d, "**Most common clinical titles do not need the guessing at all.** `physician`, "
        "`attending physician`, `medical doctor` and `medical officer` each match an "
        "example word exactly, at 1.000. The measuring matters at the edges - the "
        "synonyms, the abbreviations and the other languages - which is where a list of "
        "words on its own would simply fail.", space_after=10)
para(d, "Now change one thing. Same job title, but the department says mechanical "
        "engineering. This audience needs the title **and** the subject to agree, so the "
        "person is not scored low — they simply do not appear at all. That second check "
        "is what stops a job title alone from putting someone in a healthcare audience.",
     space_after=10)

box(d, "EXAMPLE 2  —  A PERSON OVERRULES THE MACHINE", [
 "A person typed **chemist**. The nearest example word was **pharmacist**, so the "
 "system made them a Pharmacist. In British English that is a reasonable reading - a "
 "chemist is a shop that dispenses medicines.",
 "",
 "**As an ORCID job title it is wrong every time.** A person who writes *chemist* in "
 "their research record is a chemistry researcher. The system was not wrong about the "
 "word; it was wrong about the world, and no amount of measuring would have found that "
 "out.",
 "",
 "Somebody wrote one line in a file to say: chemist means Researcher. **That line wins "
 "for ever and survives every rebuild.** The same file holds the French case, where "
 "`praticien` - practitioner - sits three letters from `pharmacien` and sent a pile of "
 "French hospital doctors into the Pharmacist audience.",
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
 [["**Lecturer**", "426,449", "**98.7% \u00b1 1.1**", "Solid"],
  ["**Researcher**", "344,847", "**99.0% \u00b1 1.0**", "Solid"],
  ["Healthcare (broad)", "178,556", "90.6% \u00b1 3.0", "**Not weak - undefined.** Waiting on a name"],
  ["Clinical researcher", "109,854", "90.0% \u00b1 3.1", "Good. Grew when biomedical research was ruled in"],
  ["**Students**", "102,026", "**98.7% \u00b1 1.3**", "**New.** Solid"],
  ["Practitioner", "57,351", "93.4% \u00b1 2.6",
   "**The figure predates 19 November** - needs re-reading"],
  ["Head of faculty", "17,421", "83.3% \u00b1 4.4", "**Parked** - not being delivered"],
  ["Clinical administrator", "8,398", "94.9% \u00b1 2.2", "Good. Was 88.9% in October"],
  ["Pharmacist", "2,090", "95.7% \u00b1 1.9", "Good. Was 81.8% in October"],
  ["Librarian", "713", "98.5%", "Solid. All 700 were read in November"]],
 widths=[1.6,0.85,1.3,2.85], size=8.8)
para(d, "**People counted on the build of 20 November; no accuracy figure in this "
        "column was re-measured on it.** That matters for two rows now. Practitioner "
        "lost about 5,400 people on 19 November, when every job title containing "
        "*consultant* was taken out of it, and Students lost 5,604 on 20 November, when "
        "a job title that is nothing but a degree was taken out of it. Both were "
        "deliberate and both are recorded with their cost. In each case the people "
        "removed included known errors, so 93.4% and 98.7% are more likely to understate "
        "their audience than to overstate it - but **both were measured on the "
        "population before the change and should be read as out of date rather than as "
        "current figures.** Lecturer also lost 2,956 people on 20 November, which is "
        "0.7% of it and inside the interval on its 98.7%.",
     size=9, color=MUT, space_after=4)
para(d, "Each audience is written out in section 6: how it is decided, how it was "
        "measured, and what is still open in it.", space_after=10)

h(d, "3.1  How much of each audience can actually be reached", 2)
para(d, "Being in an audience and being contactable are different things. **Reachable** "
        "means the person is in the CDP under any of four legal bases - marketing "
        "opt-in, advertising opt-in, legitimate interest, or book-author consent. "
        "**Both columns were counted on the 20 November build, on the same population "
        "as section 3** - the People column here equals section 3 on all ten rows, to "
        "the person, which is a check worth re-running whenever either model changes. "
        "An earlier version of this document carried two counts nine days apart.",
     space_after=4)
table(d, ["Audience", "People", "Reachable", "Of those"],
 [["**Lecturer**", "426,449", "**331,399**", "77.7%"],
  ["**Researcher**", "344,847", "**245,569**", "71.2%"],
  ["**Healthcare (broad)**", "178,556", "**132,954**", "74.5%"],
  ["**Clinical researcher**", "109,854", "**81,213**", "73.9%"],
  ["**Students**", "102,026", "**66,045**", "**64.7%**"],
  ["**Practitioner**", "57,351", "**42,818**", "74.7%"],
  ["**Head of Faculty**", "17,421", "**13,664**", "78.4%"],
  ["**Clinical administrator**", "8,398", "**6,560**", "78.1%"],
  ["**Pharmacist**", "2,090", "**1,546**", "74.0%"],
  ["**Librarian**", "713", "**391**", "54.8%"]],
 widths=[1.9, 1.1, 1.2, 0.9], size=9)
para(d, "**The rows overlap and must not be added up** - one person can be a Lecturer "
        "and a Clinical researcher at once. **Students is the least reachable of the "
        "ten at 64.7%**, so a campaign gets 66,045 of the 102,026; Librarian is lower "
        "still on a much smaller base. Neither is a classification problem - it is "
        "consent. **Practitioner is reachable for 42,818 people**, down from 46,450 "
        "before the consultant decision of 19 November - that is where the 5,400 are "
        "felt in a campaign brief.", space_after=4)
para(d, "**Nine of the ten rates fell by exactly 0.1 points on this build, and that "
        "uniformity is the useful part.** It is not any decision of ours - no decision "
        "could reach Head of Faculty, Pharmacist or Librarian and all three fell by 0.1 "
        "too. It is background: the people arriving in ORCID are slightly less "
        "contactable than the base they join, so every rate drifts down a little with "
        "each build. One build is not a trend, but it is measured now and the next build "
        "will confirm or kill it. **And it is what makes the tenth row readable.** "
        "Students fell 0.6 points, so 0.5 of it is ours: 3,927 reachable people left an "
        "audience that is 64.7% reachable, which means the bare-qualification group was "
        "about 70% reachable - more contactable than the audience average. The exclusion "
        "cost 5,604 people and 3,927 reachable ones, where the audience rate alone would "
        "have predicted 3,626.", size=9, color=MUT, space_after=10)

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
        "is a closed loop. We now have **two** outside sources, and each one can check a "
        "different thing. Neither can check everything, and the gap between them is the "
        "same gap in both: **clinical specialties**. The role library has no list of them "
        "and the survey does not reach enough clinicians to settle them. That is what a "
        "clinical expert would be for, and it is the one outside source this project has "
        "asked for and does not have.")

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
 [["1","**Re-read Practitioner**","Its 93.4% was measured before two deliberate changes: every `consultant` title left on 19 November, about 5,400 people, and `medical physicist` left on 20 November. The audience it describes no longer exists. It is also the least-read group in the project - reviewed titles cover 38% of its records against 75% for researchers - so this is the one accuracy figure that should not be quoted without its date.","Us"],
  ["2","**Size psychology and psychiatry**","Psychologists were ruled clinical on 20 November. Psychiatry is already in on both axes; psychology is in on the title only, because `psychology` is classified as a social and behavioural subject rather than a clinical one. `analyses/56` counts both professions, what we can reach, and what the field side would cost. It may be worth taking to Matthew as an audience of its own.","Us, then Matthew"],
  ["3","**A decision-maker audience**","Marketing have asked for Head of Faculty to be opened up beyond academia, to reach opinion leaders, budget holders and purchase influencers. A separate meeting is being held for it; the measurement on our side can start before it.","Marketing / us"],
  ["4","Clinical expert call","The one gap no data source covers - see the box in section 3.","Merve / Bernadeta"],
  ["5","Does Lecturer get a detailed role, and what are its values?","`role_detail` is the drill-down beside each delivered row - Hospital, Academia, Industry. Lecturer has never had any rules for it, in any build: 423,975 people with no label. The other nine split the setting, and there is no argument for Lecturer being different - but no measurement says marketing wants it either. `docs/open-questions.md` 2.20.","Marketing"],
  ["6","What do we call the people whose employer we rescued by name?","When ROR cannot identify an employer we recover the SCORE from its name - *universi*, *colleg*, *institut* - which is what saves \u201cIstanbul University-Cerrahpasa\u201d. It rescues the score and leaves the TYPE unknown, and the label keys on the type, so 172,469 people are guaranteed to have no label however many rules we add. Three answers: label them from the name pattern that rescued them, call them *Unknown*, or leave it blank and say so in the contract. Only the first recovers the labels.","Marketing / us"],
  ["7","Reach the survey data in BigQuery","Chloe pointed at `Staging_Response`. Would make the check repeatable instead of a one-off export.","Us / data eng"],
  ["8","A second source for Head of Faculty","It is parked, not delivered, until there is something besides the job title to test a vague one against. Item 3 may change what this audience is for.","Us"],
  ["9","Two small things we are choosing to live with","**A department cannot be excluded.** The job-title axis has three ways to intervene; the subject axis has one, and it can only pull a department in, never push it out - so a veterinary faculty stays in Clinical researcher and *Faculty of Sport and Health Sciences* stays in the healthcare audiences, about 35 people plus an uncounted few hundred. A model change for that is not proposed. **And a bare degree can still slip into Students** by a route the new rule is not scoped to see: 1 job title, 10 records, one field to close whenever that file is next touched.","Us"]],
 widths=[0.3,1.8,3.2,1.3], size=9)

box(d, "WHAT CAME OFF THIS LIST", [
 "**Five open items were answered on 19 November and built on 20 November.** Visiting "
 "scholars and fellows and honorary posts left Lecturer, the bare qualification left "
 "Students, `medical physicist` became a Clinical researcher, and a bare `doctor` was "
 "confirmed in Practitioner. All five were sized before the build and re-counted after "
 "it - the first time this project has priced a seed change by subtraction rather than "
 "by estimate. The bill: 2,956 people out of Lecturer, 5,604 out of Students, and "
 "nothing at all out of Healthcare (broad). One item from that reading stays open and is "
 "now item 8; the measurement found a new one, which is now item 2.",
 "",
 "**And on 20 November both of the items that had gone to Matthew were decided.** "
 "Veterinarians are out of the healthcare audiences - every one of those audiences "
 "is about humans, and the test is the work rather than the subject. Sport and "
 "exercise science is split on the word: the departments that say *medicine* stay, "
 "the ones that say *science* do not. Each decision is half built, and both are "
 "blocked by the same missing mechanism - which is why that mechanism is now item "
 "8 rather than a note in one audience.",
 "",
 "**Statisticians and economists are settled** — the 2,177 records in no audience stay "
 "out. They were never read title by title, and an audience is something a title earns "
 "by being read, not by resembling one that was.",
 "",
 "**The Students audience is built, delivered and read** — 107,091 people, 98.7% over "
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
        "because they share a group.** Nothing in the current design separates them.",
     space_after=4)
para(d, "**Re-measured on 19 November, and it is not closed.** Taking the hospital path out removed the route this box describes, but 52 people are still in Head of Faculty on a clinical job title - 27 of them on the words *medical director* alone. They arrive through employers that ROR types as education, or whose name reads like a university, rather than through hospitals. 42 of the 52 carry no academic word at all. The audience is parked and not delivered, so nobody can reach them today; the number is here so that the day it ships starts from a known defect rather than a clean slate.")


# See the note in build_mkt.py: the committed copy is the one Merve pulls.
for out in (os.path.join(os.path.dirname(SP), "docs", "ORCID-Role-Enrichment-Status-and-Plan.docx"),
            os.path.join(os.path.expanduser("~"), "Downloads", "ORCID-Role-Enrichment-Status-and-Plan.docx")):
    d.save(out)
    print("saved:", out, os.path.getsize(out), "bytes")
