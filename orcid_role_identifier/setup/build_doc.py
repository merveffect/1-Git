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
para(d, "Working document  ·  updated 26 November 2026 (second build)  ·  Analytics Engineering, Researcher 360",
     size=9.5, color=MUT, space_after=10)
box(d, "WHERE THIS STANDS", [
 "**ONE RULE ARRIVED LATE AND IS THE LARGEST CHANGE THIS PROJECT HAS MADE.** On 25 "
 "November marketing asked for the most current titles only, and on 26 November a job "
 "that ENDED more than six months ago stopped giving anybody a role. It removed 44.83% "
 "of every employment record we hold. The audiences fell by between 9% and 39%, the "
 "number of people we can name a profession for fell 6.7% to 731,584, and **no accuracy "
 "figure in this document has been re-measured since.** Sections 1, 3 and 3.1 are the "
 "new counts; section 8.2 records what it cost and the one question it raises.",
 "",
 "**THE PIPELINE IS BUILT. WHAT IS LEFT IS VALIDATION.** Nothing in the classification "
 "is waiting on engineering any more - the ten audiences, the scoring, the consent "
 "filtering and the delivered contract are all finished and running. The remaining work "
 "is reading the output and taking out of it everything that cannot be true. Section 7 "
 "says how, and that is the only thing standing between this and delivery.",
 "",
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
 [["People with a profession", "**732,872**", "We can name a profession for them"],
  ["Reachable", "**543,241**", "In the CDP and opted in. This is what a campaign can use"],
  ["Audiences", "**10**", "Before this project there was one"],
  ["Different job titles handled", "**321,483**", "The work runs once per title, not once per person"],
  ["Different departments handled", "**466,540**", "Same again, for the subject area"]],
 widths=[2.3,1.1,3.3])
para(d, "**Three quarters of the people we can name are reachable** - 543,241 of 732,872. "
        "The rest are not in the CDP or have not opted in, and no amount of classification "
        "changes that.")
para(d, "**Counted on the 26 November build, which applied one rule and nothing else: "
        "a job that ENDED more than six months ago no longer gives anybody a role.** "
        "Marketing asked for the most current titles on 25 November. A post with no end "
        "date is ongoing and still counts, and a record with no dates at all counts "
        "because there is nothing in it to judge. It removed 808,450 of the 1,803,198 "
        "employment records in the project - 44.83%.", size=9, color=MUT)
para(d, "**The audiences fell by 9 to 40 per cent, and this table fell by 6.7.** That "
        "gap is the most useful thing on the page. 52,406 people lost their profession "
        "where the audiences lost far more, because most people hold two or three roles "
        "and only those who held a single ageing role are emptied. Lecturer is the "
        "largest audience and lost the least, 8.6%, which is what carries the "
        "headline.", size=9, color=MUT)
para(d, "**The recency rule cost nothing from the dictionary, and that was checked "
        "rather than assumed.** On the build that applied it alone, row 4 read 319,032 "
        "before and 319,032 after - every title, 608 human decisions, 35 patterns and "
        "every embedding untouched, because the rule filters employment records "
        "downstream of the vocabulary. It changes which record may give a person a "
        "role, never what a title means.", size=9, color=MUT)
para(d, "**A SECOND BUILD ON THE SAME DAY REBUILT THE DICTIONARY, and that is why "
        "this table went UP while two rules were taking people out.** It carried three "
        "decisions from 8.0, four seed changes from 23 November that had never been "
        "built, and a vocabulary rebuild that added 2,451 job titles and 3,195 "
        "departments. Those new titles classify people who had nobody to be, so every "
        "audience gained more than the rules removed. **Nothing in this build is "
        "attributable to one change** - that is the cost of batching, it was known "
        "before it ran, and the figures below are simply where the project stands "
        "rather than the price of anything.", size=9, color=MUT)
para(d, "**The first two rows and the last two are not the same age.** The people "
        "counts read ORCID live. The vocabulary counts are rebuilt deliberately rather "
        "than continuously, so rows 4 and 5 describe the last dictionary build and not "
        "this one. Worth knowing before dividing one of them by the other.",
     size=9, color=MUT)
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
 [["**Lecturer**", "390,405", "**98.7% \u00b1 1.1**", "Solid. -8.5% since 20 November"],
  ["**Researcher**", "236,370", "**99.0% \u00b1 1.0**", "Solid. **-31.5%** since 20 November"],
  ["Healthcare (broad)", "125,121", "90.6% \u00b1 3.0", "**-29.9%** since 20 November"],
  ["**Students**", "102,857", "**98.7% \u00b1 1.3**", "Solid. The recency rule could not reach it"],
  ["Clinical researcher", "67,094", "90.0% \u00b1 3.1",
   "**-38.9%** since 20 November, the largest fall of the ten"],
  ["Practitioner", "44,102", "93.4% \u00b1 2.6",
   "**-23.1%.** Figure also predates 19 November - needs re-reading"],
  ["Head of faculty", "17,566", "83.3% \u00b1 4.4", "**Being replaced** - see 8.1"],
  ["Clinical administrator", "7,101", "94.9% \u00b1 2.2", "-15.4% since 20 November"],
  ["Pharmacist", "1,440", "95.7% \u00b1 1.9", "**-31.1%** since 20 November"],
  ["Librarian", "717", "98.5%", "Solid. The recency rule could not reach it"]],
 widths=[1.6,0.85,1.3,2.85], size=8.8)
para(d, "**Read the two number columns as different dates, because they are.** The "
        "People column is the 26 November build. **Not one accuracy figure beside it "
        "was re-measured on that build**, and after the recency rule seven of the ten "
        "audiences are between 9% and 39% smaller than the population those figures "
        "describe. The percentages are the last thing we measured rather than a current "
        "reading, and the three rows the rule could not touch - Students, Head of "
        "Faculty, Librarian - are the only ones where the number and the percentage "
        "describe the same people.", size=9, color=MUT, space_after=4)
para(d, "**Which way they are likely to be wrong, since they will be quoted before "
        "they are re-read.** The rule removed people whose only qualifying post ended "
        "years ago, and a post that old is the commonest single reason a label is "
        "stale - so the surviving audiences should read HIGHER than the figures beside "
        "them rather than lower. That is an expectation and not a measurement, which is "
        "why re-reading Practitioner is the first item in section 7. Practitioner "
        "carries two dated figures at once: 93.4% predates the consultant removal of 19 "
        "November as well.", size=9, color=MUT, space_after=4)
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
 [["**Lecturer**", "390,405", "**306,044**", "78.4%"],
  ["**Researcher**", "236,370", "**166,814**", "70.6%"],
  ["**Healthcare (broad)**", "125,121", "**93,337**", "74.6%"],
  ["**Students**", "102,857", "**66,811**", "**65.0%**"],
  ["**Clinical researcher**", "67,094", "**49,510**", "73.8%"],
  ["**Practitioner**", "44,102", "**33,107**", "75.1%"],
  ["**Head of Faculty**", "17,566", "**13,784**", "78.5%"],
  ["**Clinical administrator**", "7,101", "**5,523**", "77.8%"],
  ["**Pharmacist**", "1,440", "**1,071**", "74.4%"],
  ["**Librarian**", "717", "**393**", "54.8%"]],
 widths=[1.9, 1.1, 1.2, 0.9], size=9)
para(d, "**The rows overlap and must not be added up** - one person can be a Lecturer "
        "and a Clinical researcher at once. **Students is the least reachable of the "
        "ten at 65.0%**, so a campaign gets 66,811 of the 102,857; Librarian is lower "
        "still at 54.8% on a much smaller base. Neither is a classification problem - "
        "it is consent.", space_after=4)
para(d, "**The recency rule left the audiences more contactable than it found them, "
        "which was not the expected direction.** Eight of the ten rates held or rose on "
        "the 26 November build and the largest move is Lecturer, up 0.7 points. Working "
        "it backwards: the people the rule removed from Lecturer were about 70% "
        "reachable against an audience average of 78%, so an ageing employment record "
        "and a missing consent tend to travel together - somebody who stopped "
        "maintaining their ORCID often stopped being contactable too. **Researcher is "
        "the exception**, down 0.6 points, where the people removed were slightly MORE "
        "reachable than the audience they left. Both figures ignore the ORCID growth "
        "between builds, so read them as the direction rather than the size.",
     size=9, color=MUT, space_after=10)

box(d, "WHY HEALTHCARE IS THE HARDEST PART", [
 "Academic titles are nearly the same everywhere: Professor, Associate Professor, "
 "Lecturer. Clinical titles are not. **Resident, Registrar, Facharzt, Interno** and "
 "**Jefe de Servicio** can all mean a doctor in training, and they share no common word.",
 "",
 "Real example: before October we had no example word for anaesthetists, so they were "
 "matched to **neurosurgeon**. And veterinarians were matched to **dentist**, because "
 "dentist was the closest word we had given the machine.",
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
box(d, "WHAT VALIDATION MEANS HERE, BECAUSE IT IS NOT MORE CLASSIFYING", [
 "**The remaining work removes matches rather than adding them, and it is a judgement "
 "rather than a model.** The machine has done what it can. What is left is the set of "
 "things that are impossible rather than merely unlikely, and a person has to say which "
 "those are. Accuracy is what this project is judged on - somebody who is not a "
 "clinician must not be in a healthcare audience - so where coverage and correctness "
 "pull against each other, correctness wins and the match is deleted.",
 "",
 "**Two checks are being run, and neither of them looks at the job title again.** The "
 "first reads what the CDP already knows about the people we matched and asks whether it "
 "agrees. The second looks for one person appearing in two audiences that cannot both be "
 "true - a Head of Faculty who is also in Students is about 70 people today, and not one "
 "of them can be both.",
 "",
 "**The second check has to be written carefully, because holding several roles is "
 "correct here and is built on purpose.** A *research professor* is in Researcher and in "
 "Lecturer; a *doctoral researcher* is in Researcher and in Students. Those are right. "
 "So the rule is not \u201cappears twice\u201d - it is a named list of pairs that "
 "contradict each other, written one pair at a time.",
 "",
 "**What it costs: the delivered population falls slightly, not steeply.** These are "
 "contradictions in the tens and low hundreds against audiences in the hundreds of "
 "thousands. The figures in sections 1 and 3 are the pre-validation counts and will be "
 "restated once the eliminations are in.",
], fill="F2F6F5", accent=TEAL)

h(d, "7.  What happens next")
table(d, ["#", "What", "Why now", "Who"],
 [["1","**Re-read Practitioner**","Its 93.4% was measured before two deliberate changes: every `consultant` title left on 19 November, about 5,400 people, and `medical physicist` left on 20 November. The audience it describes no longer exists. It is also the least-read group in the project - reviewed titles cover 38% of its records against 75% for researchers - so this is the one accuracy figure that should not be quoted without its date.","Us"],
  ["2","**Size psychology and psychiatry**","Psychologists were ruled clinical on 20 November. Psychiatry is already in on both axes; psychology is in on the title only, because `psychology` is classified as a social and behavioural subject rather than a clinical one. `analyses/56` counts both professions, what we can reach, and what the field side would cost. It may be worth taking to Matthew as an audience of its own.","Us, then Matthew"],
  ["3","**A decision-maker audience**","Marketing have asked for Head of Faculty to be opened up beyond academia, to reach opinion leaders, budget holders and purchase influencers. A separate meeting is being held for it; the measurement on our side can start before it.","Marketing / us"],
  ["4","Clinical expert call","The one gap no data source covers - see the box in section 3.","Merve / Bernadeta"],
  ["5","**Give Lecturer a detailed role** - decided, not yet built","`role_detail` is the drill-down beside each delivered row: Hospital, Academia, Research Institute, Industry. Lecturer has never had any rules for it in any build, so the largest audience we have - 426,449 people - is the one audience nobody can segment. The other nine already split the setting and there is no argument for Lecturer being different. Six seed rows, copying the pattern the other nine use. It also clears the warning that fires on every build.","Us"],
  ["6","**Label the people whose employer we rescued by name** - decided, not yet built","When ROR cannot identify an employer we recover the SCORE from its name - *universi*, *colleg*, *institut* - which is what saves \u201cIstanbul University-Cerrahpasa\u201d. It rescues the score and leaves the TYPE unknown, and the label keys on the type, so 172,469 people are guaranteed to have no label however many rules are added. **Decision: label them from the name pattern that rescued them.** It is the only one of the three answers that recovers real labels rather than renaming the gap, and the information is already in hand - we matched the word to rescue the score and then threw away what we matched. Needs a type column on the name-pattern seed. **One check before it ships:** this fills about 270,000 values that are blank today, and blank-to-value is a change for whoever reads the field.","Us"],
  ["7","Reach the survey data in BigQuery","Chloe pointed at `Staging_Response`. Would make the check repeatable instead of a one-off export.","Us / data eng"],
  ["8","A second source for Head of Faculty","It is parked, not delivered, until there is something besides the job title to test a vague one against. Item 3 may change what this audience is for.","Us"],
  ["9","Reconcile `org_type_scores` and `role_detail_map`","The two seeds that describe employers were written to different standards and only one was tested: the first carries all ten ROR types for all ten audiences, the second carries between two and six. That is where items 5 and 6 come from, and it is worth finishing in one pass rather than one audience at a time. `funder` alone - research councils, CNRS, INSERM, NIH - is 53,241 people with no label.","Us"]],
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


# ============================================================ 8
h(d, "8.  What we need decided, in one sitting")
para(d, "Everything still waiting on somebody outside engineering, in the order it "
        "matters. Every decision below is reversible in one line of configuration "
        "afterwards.", space_after=4)
box(d, "WHAT TO COME OUT OF THE ROOM WITH", [
 "**FIRST, THE POSITION. The pipeline is finished and nothing here is waiting on "
 "engineering.** What remains on our side is validation - deleting the matches that "
 "cannot be true - and it takes the delivered figures down slightly rather than steeply. "
 "Section 7 says what it consists of.",
 "",
 "**THREE WERE DECIDED INSIDE THE TEAM ON 26 NOVEMBER AND ARE BUILT** - see 8.0. "
 "They are here to be read rather than answered: the `MD, PhD` titles, the 0.60 "
 "threshold on Healthcare Professional (broad), and our own employees leaving the "
 "pipeline alongside our competitors'.",
 "",
 "**FIVE DECISIONS, and we cannot take any of them.** Whether `md` on its own is "
 "enough (8.2). Whether the four part-regulated health roles stay in (8.2). Whether "
 "Librarian's two exclusions come back (8.2). **Whether anybody uses `role_detail`, or "
 "we delete it (8.3).** And whether anything in the holding group is wanted as an "
 "audience - consultants above all, which is the largest group we have set aside (8.4). "
 "**The sixth came off the list on 25 November:** a job that ended more than six months "
 "ago no longer counts, which was the largest question here and is built (8.2).",
 "",
 "**ONE SCOPE, on an audience already decided.** Head of Faculty is being widened into a "
 "decision-maker audience rather than repaired (8.1). The decision is taken; what we "
 "need is which job classes and which industries count.",
 "",
 "**TWO ASKS, which are resource rather than definition** - a second reader and the "
 "survey data in BigQuery (8.5) - plus whether we should go looking for a librarian data "
 "source, since 713 people is a source gap and not a classification one (8.4). **The "
 "clinical-expert ask has come off this list:** Springer Medicine is the route, and 8.5 "
 "says how.",
 "",
 "**AND FOUR THINGS THAT ARE INFORMATION ONLY** - they need no answer and are here so "
 "nobody is surprised later: Practitioner's accuracy figure describes a population that "
 "no longer exists; one job title can put somebody in two audiences, deliberately; every "
 "figure in this document counts the people we DELIVER and there is a larger number "
 "upstream that is never delivered; and the psychology count is running.",
], fill="FBF6EE", accent=AMBER)

h(d, "8.0  Decided on 26 November, and already built", 2)
para(d, "**These three came to us as questions and were answered inside the team "
        "rather than sent out.** Each is one line of configuration and each is "
        "reversible; what they are not is a guess, and the reasoning is recorded "
        "beside the rule in the seed that carries it.", space_after=4)
table(d, ["The question", "The decision, and what it rests on", "What it moves"],
 [["**A job title that is nothing but two degrees - `MD, PhD`.** Was in Students.",
   "**Out, and into no audience at all.** The ambiguity was real and is why it was "
   "asked: in the United States MD-PhD is the name of a combined degree PROGRAMME, so "
   "somebody writing it at a university may be enrolled in it, while everywhere else "
   "and in the US after graduation it is how a qualified physician lists two diplomas. "
   "Decided on what the title states - two FINISHED degrees, which is a credential and "
   "not a status. The rule is anchored to the whole title, so `MD/PhD Student`, "
   "`Graduate Assistant (MD/PhD)` and `MPhil/MD/PhD Offer Holder` are untouched.",
   "**~140 people** leave Students and enter the holding group, retrievable by name. "
   "**Verified after the build: one person still carries such a title in Students**, "
   "which is a 99% landing and is being traced - most likely a human override that "
   "predates the rule and beats it by design, or a title reaching Students through its "
   "SECOND group, which a pattern scoped to the primary group cannot see."],
  ["**Healthcare Professional (broad) confirms at 0.60 while its four children confirm "
   "at 0.70.** So somebody scoring 0.65 is refused as a Clinical Administrator and "
   "delivered as a Healthcare Professional.",
   "**The threshold stays at 0.60.** All 3,840 people in that band hold a clinical or "
   "biomedical DEPARTMENT - the child audiences require the title and the field "
   "together, so no other kind of person can reach the band at all. 2,424 of them "
   "arrive as researchers in biomedical departments, which is precisely what marketing "
   "ruled in on 11 November; raising the threshold would throw them out and contradict "
   "that decision. **The weak half is named rather than left unsaid:** of the 1,416 who "
   "arrive through clinical leadership, titles like `CEO`, `President` and `Owner` "
   "describe a business, not a profession. That is a title problem and will be fixed "
   "with overrides, not by moving the threshold.",
   "**Nothing today.** 3,840 people stay. The corporate-title subset is being counted "
   "before any rule is written for it."],
  ["**Springer Nature's own employees** - 239 people whose ORCID record names one of "
   "our imprints.",
   "**Removed from the pipeline entirely, exactly as our competitors are.** Removal is "
   "at the PERSON level rather than the record level: one job naming an excluded "
   "employer takes the whole person out. Record-level removal would have emptied only "
   "48 of the 239, because the rest hold another job that would have kept them "
   "classified.",
   "**587 people in total** with the 348 competitor-employed - 0.066% of the 890,940 we "
   "read. No title leaves the dictionary: the rule sits downstream of the vocabulary. "
   "**Verified after the build: zero people whose record names an excluded employer "
   "hold any audience.** This is the only one of the three that landed exactly."]],
 widths=[1.7, 3.5, 1.7], size=8.5)

h(d, "8.1  Head of Faculty is being replaced by a decision-maker audience", 2)
para(d, "**This is no longer an open question and is here as a decision already taken.** "
        "Head of Faculty was parked rather than delivered because the job title was its "
        "only evidence and a vague one had nothing to contradict it - 83.3%, the lowest "
        "of the ten, with 20% of the audience holding nothing but *director*, *head* or "
        "*chair*. The answer agreed is not to repair it but to widen what it is for: a "
        "**decision-maker** audience reaching budget holders, opinion leaders and "
        "purchase influencers in companies and other industries as well as in "
        "universities.")
table(d, ["What was measured", "What it gives", "What is still needed from you"],
 [["The audience at three employer settings, `analyses/53`.",
   "**17,421** as universities only, which is what exists today. **23,676** opening it "
   "to research institutes. **35,378** opening it to every employer type - and industry "
   "medical directors go from 0 to 408 at both of the wider settings.",
   "**The scope, not the decision.** Which job classes count as a decision maker, and "
   "which industries are wanted. The widest setting is measured and buildable; what we "
   "cannot choose for you is where inside that range the audience should sit."]],
 widths=[1.6, 3.1, 2.1], size=8.5)

h(d, "8.2  One answered last week, and three still open", 2)
table(d, ["#", "The question", "Where it stands", "Size"],
 [["\u2713", "**Should a job somebody has LEFT still count? ANSWERED on 25 "
   "November, and it was the largest question on this list.**",
   "**A job that ended more than six months ago no longer gives anybody a role**, and "
   "it was built on 26 November. An ongoing post still counts, and so does a record "
   "with no dates at all, because there is nothing in it to judge. Head of Faculty, "
   "Librarian and Students already counted current posts only and are unchanged.",
   "**808,450 of 1,803,198 employment records - 44.83%.** Per audience: Clinical "
   "researcher -39.1%, Researcher -31.6%, Pharmacist -31.2%, Healthcare (broad) "
   "-30.2%, Practitioner -23.5%, Clinical administrator -15.8%, Lecturer -8.6%. "
   "**One thing worth raising rather than burying: only 5.8% of ended posts ended "
   "inside six months, so in this data six months and six years are nearly the same "
   "rule. At three years it still removes 79% of what six months removes.** The "
   "window is one line of configuration."],
  ["2", "**Is `md` on its own enough?**",
   "50,189 records. A bare `dr` was settled on 20 November - a medical qualification "
   "beside a clinical department is accepted as clinical evidence. `md` is the same "
   "shape and nobody has been asked about it.",
   "50,189 records, resolved entirely by the department beside them."],
  ["3", "**Four health roles that are regulated in some countries and support roles in "
   "others.** Mental health support workers, genetic counsellors, counsellors, clinical "
   "scientists.",
   "All of them are in Practitioner today, by the machine rather than by a decision. "
   "`medical physicist` was the fifth and was settled on 20 November - it became a "
   "clinical researcher.",
   "326 / 866 / 1,205 records, counsellors being the largest."],
  ["4", "**The two titles kept out of Librarian.** Archivists, and *information "
   "specialist*.",
   "Both excluded by us, for measured reasons: `archivist` as an example word also "
   "collected archaeologists, glaciologists and clerks, and `information specialist` "
   "collected every IT job in the data. Either is one row to reverse, as a decision "
   "rather than a guess.",
   "**Unmeasured, and the cheapest reach we have.** Librarian is 713 people - see 8.4."]],
 widths=[0.3, 2.0, 3.1, 1.4], size=8.5)

h(d, "8.3  The question nobody has answered twice, and it decides two items on our list", 2)
box(d, "DOES ANYBODY ACTUALLY READ `role_detail`?", [
 "`role_detail` is the drill-down beside each delivered row - Hospital, Academia, "
 "Industry, Research Institute. It is the difference between *clinical researchers* and "
 "*clinical researchers in industry* on a brief.",
 "",
 "**We asked in November and could not settle it from our own side.** The column was "
 "deleted once on the understanding that nothing read it, and put straight back the same "
 "day because a comment in our repository is not evidence of what a consumer does. That "
 "is recorded as a mistake of ours, not a change of mind.",
 "",
 "**If nobody reads it, say so and we delete it** - the model, the seed and three tests, "
 "and two items come off our list with it. **If somebody does read it**, two things need "
 "doing and we have decided how, so this is the only input needed: Lecturer has never "
 "had any values at all, which leaves the largest audience in the project - 426,449 "
 "people - as the only one nobody can segment; and about 270,000 people are "
 "structurally blank, because when the public register cannot identify an employer we "
 "rescue the SCORE from its name and the label keys on the TYPE, which stays unknown.",
 "",
 "**One warning that comes with filling them in:** it turns about 270,000 blanks into "
 "values, and blank-to-value is a change for whoever reads the field.",
])

h(d, "8.4  Reach we could buy, if it is wanted", 2)
table(d, ["What", "The finding", "What it would take"],
 [["**Librarians are a SOURCE gap, not a classification gap.**",
   "713 people, and the audience is 98.5% correct - every one of the 700 was read. The "
   "reason it is small is that ORCID is a publishing identifier: you create one to "
   "attach your name to papers, and librarians largely never do. It is also the only "
   "audience besides Head of Faculty and Students that counts current posts only.",
   "A different dataset, if that business matters. Separately, including past library "
   "posts would grow it - unmeasured, one line."],
  ["**The holding group - people we deliberately took OUT.**",
   "Every job title containing *consultant* (about 17,360 records), veterinarians, "
   "honorary posts, visiting scholars and fellows, and job titles that are nothing but "
   "a degree all now sit in a group that feeds no audience. None of them is deleted; "
   "they were kept retrievable by name on purpose.",
   "**The biggest one is consultants.** In Britain and Ireland a consultant is a "
   "hospital specialist; almost everywhere else it is a business adviser, and the "
   "record does not say which. A country condition would recover a real clinical "
   "population, and it is the single largest group we have set aside."],
  ["**Psychology and psychiatry.**",
   "Psychologists were ruled clinical on 20 November. Psychiatry is already in on both "
   "axes; psychology is in on the job title only, because the subject is classified as "
   "social and behavioural rather than clinical.",
   "Being counted now, `analyses/56`. It may be worth proposing as an audience of its "
   "own."]],
 widths=[1.7, 3.2, 2.0], size=8.5)

h(d, "8.5  Three things we need that are not decisions", 2)
bullet(d, "**A clinical expert - and this one now has a route.** It is the one outside "
          "source the project has asked for and never had: the role library Market "
          "Intelligence keeps has no list of clinical specialties at all - no "
          "cardiologist, no anaesthetist, no midwife - and 52 of our 58 clinical example "
          "words are absent from it, while the survey does not reach enough clinicians "
          "to settle them either. **The route agreed is Springer Medicine.** The "
          "healthcare audiences go to Bernadeta, who checks them against the coverage in "
          "their own data and returns an analysis, and that analysis is what cleans the "
          "weakest group in the project. **Nothing is needed from you except awareness "
          "that this is the plan** - and if there is a governance view on moving the "
          "data, we would rather hear it before it moves than after.")
bullet(d, "**A second reader.** Every accuracy figure in this document is ONE reader - "
          "the analyst, against the definitions written here. About 30 rows per audience "
          "read independently is what turns them into figures we would guarantee to "
          "somebody outside the team. It is a day of somebody's time, not a project.")
bullet(d, "**The survey data in BigQuery.** Chloe pointed at `Staging_Response`. Today "
          "the external check is a one-off export from 30 October; in BigQuery it "
          "becomes a query that re-runs after every change, which is worth more than "
          "the single number it produced.")
d.paragraphs[-1].paragraph_format.space_after = Pt(10)

box(d, "AND FOUR THINGS TO SAY RATHER THAN ASK", [
 "**Practitioner's 93.4% is out of date and we are re-reading it.** It was measured "
 "before every `consultant` title left the audience on 19 November, about 5,400 people, "
 "and before `medical physicist` left on 20 November. The people removed included known "
 "errors, so it is more likely to understate than overstate - but it describes a "
 "population that no longer exists.",
 "",
 "**Nine of the ten audiences are being delivered. Head of Faculty is not.** That is a "
 "decision, not a defect, and 8.1 is what unparks it.",
 "",
 "**Every figure in this document counts the people we DELIVER, and there is a bigger "
 "number in the warehouse that does not.** The scoring table keeps two confidence "
 "tiers, CONFIRMED and PROBABLE, so that we can see what sits just below each "
 "threshold. Only CONFIRMED is ever delivered. Read one table upstream of delivery and "
 "Head of Faculty looks like 36,000 people rather than 17,421 - which is exactly what "
 "happened on 24 November when the roles were checked against Braze from the other "
 "side. Nothing is wrong: the gap IS the rule that holds that audience together, "
 "because an employer the public register cannot identify scores zero and lands in "
 "PROBABLE. The delivered table is `fct_braze_contact_roles` and it applies two "
 "filters, the confidence tier and a consent basis. **If a figure for one of these "
 "audiences does not match this document, that is the first thing to check.**",
 "",
 "**A job title that names two jobs is given BOTH, and that is already built.** A "
 "`research professor` is in Researcher and in Lecturer; a `professor and dean` is in "
 "Lecturer and in Head of Faculty; a `doctoral researcher` is in Researcher and in "
 "Students. Five rules do this, each one a literal word match rather than a guess, and "
 "they are what the standing warning on every build is counting - 250 job titles today. "
 "Worth saying out loud because the obvious assumption is that a title lands in one "
 "place and has to be argued out of the others.",
], fill="FBF6EE", accent=AMBER)

# See the note in build_mkt.py: the committed copy is the one Merve pulls.
for out in (os.path.join(os.path.dirname(SP), "docs", "ORCID-Role-Enrichment-Status-and-Plan.docx"),
            os.path.join(os.path.expanduser("~"), "Downloads", "ORCID-Role-Enrichment-Status-and-Plan.docx")):
    d.save(out)
    print("saved:", out, os.path.getsize(out), "bytes")
