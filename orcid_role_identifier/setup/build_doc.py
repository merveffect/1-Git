# -*- coding: utf-8 -*-
import sys, os
SP = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, SP)
from docx_lib import *
from docx.shared import Pt, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH as AL
F = os.path.join(SP, "fig")

d = doc_new()

# ============================================================ TITLE
p = d.add_paragraph(); p.paragraph_format.space_after = Pt(2)
r = p.add_run("ORCID ROLE ENRICHMENT"); r.bold=True; r.font.size=Pt(9.5)
r.font.color.rgb=TEAL; r.font.name=SANS
p = d.add_paragraph(); p.paragraph_format.space_after = Pt(4)
r = p.add_run("Where we are, and what to do next"); r.bold=True
r.font.size=Pt(22); r.font.color.rgb=INK; r.font.name=SANS
para(d, "Working document  ·  updated 29 October 2026  ·  Analytics Engineering, Researcher 360",
     size=9.5, color=MUT, space_after=10)
box(d, "WHAT CHANGED SINCE THE LAST VERSION", [
 "**The project has been checked against an outside source for the first time, and it "
 "passed.** 81.8% of the people we classified were put in the audience they put "
 "themselves in — against a ceiling of 88.9%, which is how often people agree with "
 "their own earlier answer. Section 5 is new and covers it.",
 "",
 "**Nine more corrections landed** from the synonym check, and all fourteen outstanding "
 "corrections are now live in the dictionary.",
 "",
 "**Head of Faculty is now university heads only.** A medical director at a hospital was "
 "reaching it; rather than patch that one title we took the whole hospital path out. "
 "About 2,000 people leave, including 294 heads of department and 17 deans, and that cost "
 "was measured before the decision. A small, certain audience was preferred.",
 "",
 "**The synonym-split check is written** (`analyses/28`). It is step 1 of the taxonomy "
 "plan on page 5 and it needs no judgement — 124 groups, 254 pairs, one query.",
 "",
 "A build has run, and **four of the five corrections landed**. `pi`, `fellow`, "
 "`medical director` and `director of research` all now show as human decisions in the "
 "dictionary — 80,417 records. The fifth, `assistant research professor` (14,060 "
 "records), was pushed after that build and needs the next one.",
 "",
 "**One side effect was predicted and has now been measured: 145 people.** It is not "
 "settled. See the last page.",
], fill="F2F6F5", accent=TEAL)

# ============================================================ 1
h(d, "1.  Where we are today")
para(d, "ORCID is where researchers write their own employment history: job title, "
        "organisation, department. All of it is free text. There is no field anywhere "
        "that says what profession someone is. We read that text and work it out.")
table(d, ["", "Today", "What it means"],
 [["People with a profession", "**673,851**", "We can name a profession for them"],
  ["Reachable", "**501,508**", "In the CDP and opted in. This is what a campaign can use"],
  ["Audiences", "**9**", "Before this project there was one"],
  ["Different job titles handled", "**317,302**", "The work runs once per title, not once per person"],
  ["Different departments handled", "**459,123**", "Same again, for the subject area"]],
 widths=[2.3,1.1,3.3])
para(d, "The last two rows are the reason this is affordable. We do the thinking once, "
        "over the vocabulary, and store the answers. Giving 1.8 million people their "
        "profession after that is an ordinary database join.", space_after=10)
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
 "The title **junior researcher** appears on 42,949 records.",
 "",
 "The machine put it in the **senior** researcher group, and it was 0.870 confident. "
 "Very sure, and completely wrong. The reason is that the computer treats *junior* and "
 "*senior* as two ends of one idea, so they look similar to it.",
 "",
 "Someone wrote one line in a file to say: this is early career. That line wins for "
 "ever and survives every rebuild.",
 "",
 "**But notice what it did not change.** Both researcher groups feed the same audiences, "
 "so 42,949 records moved and not one person entered or left an audience. A correct "
 "dictionary and a correct audience are two different things.",
], fill="FAF2F5", accent=PLUM)

# ============================================================ 3
h(d, "3.  Where each profession stands")
para(d, "\"Read\" below means a person has looked at job titles covering that share of the "
        "group's records. It does not mean the rest is wrong — it means nobody has "
        "checked it.")
fig(d, f"{F}/coverage.png", 6.6, "How much of each profession a person has actually read.")
table(d, ["Profession", "Records", "Read", "Condition", "What it needs next"],
 [["Practitioner","1,656,354","38%","**Weakest**","A clinical expert. 52 of its example words are not in any taxonomy we have."],
  ["Clinical trainee","801,282","68%","Good","Nothing urgent."],
  ["Teaching academic","12,024,436","69%","Exposed","No subject check at all, so a wrong title goes straight through."],
  ["Researcher, early","8,343,585","75%","**Cleanest**","Nothing. Zero corrections were needed on the first read."],
  ["Researcher, established","1,917,931","62%","Good","Two naming clashes to settle. See section 6."],
  ["Leadership","953,819","62%","Good","Watch one side effect after the next build."],
  ["Pharmacist","74,941","51%","Fixed","Was the dirtiest group. 21% of its records were wrong and it cost the audience 91 people."],
  ["Librarian","21,832","n/a","Solid","Decided by the word itself, not by the machine. 0.4% known wrong."],
  ["Student","1,968,320","**0%**","**Not read**","About to become an audience. Nobody has reviewed it."],
  ["Support / technical","1,458,782","n/a","Parked","Feeds nothing. Deliberately holds titles that belong nowhere."]],
 widths=[1.25,0.85,0.5,0.75,3.25], size=9)

box(d, "WHY \"PRACTITIONER\" KEEPS COMING UP", [
 "It has the least review and it feeds the most audiences. Clinical job titles are also "
 "the most scattered vocabulary in the data.",
 "",
 "Academic titles are nearly the same everywhere: Professor, Associate Professor, "
 "Lecturer. Clinical titles are not. **Resident, Registrar, Facharzt, Interno** and "
 "**Jefe de Servicio** can all mean a doctor in training, and they share no common word.",
 "",
 "Real example: before October we had no example word for anaesthetists, so 2,765 of "
 "them were matched to **neurosurgeon**. And 2,684 veterinarians were matched to "
 "**dentist**, because dentist was the closest word we had given the machine.",
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

h(d, "4.2  The survey answers — ARRIVED, and measured in section 5", 2)
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
        "professions. The full result is section 5. The headline: 81.8% of the people we "
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

h(d, "4.3  Clinical expertise", 2)
para(d, "A call with Bernadeta is being arranged. Section 4.1 shows why this is still "
        "needed even though we now have a taxonomy: the taxonomy is silent on exactly the "
        "part where we are weakest. The three things worth asking for are any existing "
        "clinical title list, anything that explains how clinical titles differ between "
        "countries, and whether web-scraped data she worked on could help.")

# ============================================================ 5
h(d, "5.  VALIDATION — our answer against what people said about themselves")
para(d, "Until the end of October every number in this project came from our own "
        "pipeline. Market Intelligence then exported two surveys in which people had "
        "picked their own job title from a fixed list and given an email address. That "
        "let us compare our answer to the person's own answer for the first time.")
table(d, ["Source", "Rows", "Period"],
 [["Researcher Panel","232,648","June 2022 – October 2026"],
  ["Journal Author Satisfaction","109,396","April 2024 – October 2026"],
  ["**Combined, one answer per person**","**290,045**","most recent answer kept"]],
 widths=[2.6,1.2,2.8])

h(d, "5.1  We measured the ceiling before measuring ourselves", 2)
para(d, "34,372 people appear in both surveys, so they declared their own job twice. "
        "That gives something rare: a way to find out how reliable the yardstick is "
        "before using it.")
box(d, "PEOPLE DISAGREE WITH THEMSELVES 11% OF THE TIME", [
 "`same person, two surveys, same profession   88.9%`",
 "`same person, two surveys, same words         60.6%`",
 "",
 "So **88.9% is the ceiling**. Nothing we do can score meaningfully above it, and 85% "
 "would be close to perfect rather than poor.",
 "",
 "Their disagreements are real rather than careless:",
 "",
 "`627  professor in one, research scientist in the other`",
 "`523  professor in one, editor in the other`",
 "`288  head of department in one, professor in the other`",
 "`180  student in one, academic in the other   (time: people move on)`",
 "",
 "Measuring this first is the point. Without it we would have compared our own number "
 "against an implied 100% and called a good result a failure.",
])

h(d, "5.2  The result", 2)
fig(d, f"{F}/validation.png", 6.4,
    "Of the people we classified, how many did we put where they put themselves.")
para(d, "**81.8% overall, against a ceiling of 88.9%** — 92% of the best obtainable. "
        "Lecturer is above the ceiling, but that is the test being easier rather than us "
        "being better: the ceiling compared one answer to one answer, while this asks "
        "whether our answer is among the roles we gave the person.")

h(d, "5.3  The real limit is coverage, not accuracy", 2)
fig(d, f"{F}/validation_funnel.png", 6.4,
    "Where the 290,045 survey respondents go.")
para(d, "We matched 238,440 of them to somebody in the CDP, and then knew the job of only "
        "**46,656** — a quarter. The rest have no ORCID employment record we can read.")
para(d, "This confirms from outside what the project has been saying from inside: the "
        "ceiling on this work is **how many people we can say anything about at all**, "
        "not how often we are right about the ones we can.")

h(d, "5.4  What it found: the one-title-one-group rule", 2)
para(d, "Head of Faculty scored 20%, and the Researcher audience 69.9%. The biggest "
        "single cause is the same in both, and it is a design choice rather than a bug.")
box(d, "A PROFESSOR CAN ONLY BE ONE THING", [
 "`4,210  said \"research scientist\"   we said teaching academic`",
 "`  654  said \"head of department\"   we said teaching academic`",
 "`2,602  said \"PhD student\"          we said teaching academic`",
 "",
 "All of them have **Professor** recorded as their ORCID job title, and a title belongs "
 "to exactly one profession in our system. A professor who researches, runs a department "
 "or supervises doctoral students is only a lecturer to us.",
 "",
 "This was already an open question — worth 463,603 records — and it was marked low "
 "priority because it is a design change rather than a setting. **It now has outside "
 "evidence**: more than ten thousand people describe themselves differently from us, and "
 "this rule is why.",
], fill="FBF1EF", accent=RED)
para(d, "Head of Faculty has two further causes, both of them decisions taken "
        "deliberately in the last week: it counts current posts only, and it was narrowed "
        "to universities only on 29 October.")

h(d, "5.5  What this is not", 2)
bullet(d, "**It is not an accuracy rate.** Self-declaration is a second opinion, not a "
          "fact. People pick one option from a list to describe a life that has several.")
bullet(d, "**The population is selected.** These are people who publish and who answer "
          "surveys. Librarians appear seven times. Students and support staff are barely "
          "represented.")
bullet(d, "**Two audiences cannot be checked this way at all** — the survey offers no "
          "pharmacist and no librarian option worth the name.")
bullet(d, "**It is repeatable.** The comparison is a query, so it can be re-run after "
          "every change as a regression check. That is new, and it is worth more than the "
          "single number.")

h(d, "6.  How to use the taxonomy well — step by step")
para(d, "The taxonomy is built for a B2C research audience, so most of it is not about "
        "us. The aim is to take only the parts that improve our matching and leave the "
        "rest. Here is the order to do it in, cheapest and surest first.")

h(d, "Step 1 — Check the synonym groups.  (DONE 30 October)", 2)
para(d, "The taxonomy groups titles that mean the same job. There are **124 such groups** "
        "and **254 pairs** to check. The rule is simple: if two titles are the same job, "
        "they must land in the same profession in our system. Where they do not, one of "
        "them is wrong.")
para(d, "**No judgement is needed and nobody has to read anything.** It is a query.")
box(d, "WHY THIS IS THE BEST FIRST STEP", [
 "We already found one of these by hand, and it is the biggest open problem on the list:",
 "",
 "`assistant research professor   14,060 records  ->  Teaching academic`",
 "`research assistant professor   71,785 records  ->  Researcher, early`",
 "",
 "The taxonomy lists those two as **the same job**. We put them in different professions, "
 "which means they feed different audiences. That is **85,845 records** split by nothing "
 "more than word order.",
 "",
 "The synonym check would have found this automatically, and it will find the others we "
 "have not noticed.",
])

h(d, "Step 2 — Finish the gap list we already measured.", 2)
para(d, "We compared every taxonomy title against our dictionary and measured which gaps "
        "are real in ORCID. Four have been fixed, covering 80,417 records. Four are left "
        "and are listed in section 6.")
para(d, "**The rule that matters here: a gap is not automatically a new example word.** "
        "A title nobody types into ORCID is not worth adding, and a title already landing "
        "in the right place does not need anything.")
box(d, "A PREDICTION THE MEASUREMENT KILLED", [
 "Before running it, I expected **allied health professional** to be a real gap. It is a "
 "standard umbrella term in the UK health service, covering physiotherapists, "
 "radiographers and occupational therapists.",
 "",
 "It appears **0 times** in ORCID. Nobody writes it as their job title.",
 "",
 "Had we added it as an example word without measuring, we would have gained nothing and "
 "taken on one more risk. This is why we measure before adding.",
])

h(d, "Step 3 — Use the descriptions to settle open questions.", 2)
para(d, "The taxonomy has three columns we have not used at all: a description, typical "
        "responsibilities, and typical outputs. These are the richest part of it, and they "
        "are what settles an argument about where a job belongs.")
box(d, "EXAMPLE — A BOUNDARY CASE THE DESCRIPTION SETTLES", [
 "`clinical scientist     1,671 records  ->  we put it in Clinical trainee`",
 "",
 "It got there through the example word **clinical fellow**, matching on one word.",
 "",
 "The taxonomy says: *\"A scientist applying laboratory or analytical expertise to "
 "diagnosis, monitoring and treatment in healthcare.\"*",
 "",
 "That is a qualified healthcare scientist, not a doctor in training. The description "
 "answers the question without anybody needing to be an expert.",
])
para(d, "We have thirteen open questions waiting on marketing. For several of them the "
        "taxonomy's own words are the evidence to put in front of the meeting.")

h(d, "Step 4 — Use the role type, but only where it is clear.", 2)
para(d, "The taxonomy sorts titles into about 23 role types. Most do not line up with our "
        "10 professions, because theirs is about seniority and ours is about occupation. "
        "Comparing all of them would produce noise.")
para(d, "**Four of them are unambiguous and worth checking:**", space_after=3)
table(d, ["Taxonomy role type", "Must become", "If it does not, it is a real finding"],
 [["Clinical practitioner / researcher","`practitioner`","A doctor is in the wrong group"],
  ["Clinical trainee","`trainee_clinical`","A trainee is in the wrong group"],
  ["Student / trainee","`student`","A student is counted as staff"],
  ["Former / inactive researcher","rejected","A retired person is in a live audience"]],
 widths=[2.2,1.3,3.1])

h(d, "Step 5 — Do not use it for two things.", 2)
bullet(d, "**Clinical specialties.** It does not have them. That is the clinical expert's job.")
bullet(d, "**Non-English titles.** It has almost none. That is the survey data's job, and "
          "our own reading.")
para(d, "Trying to stretch the taxonomy over these would waste time and give false comfort.",
     space_after=10)

h(d, "Step 6 — Keep the useful part as a permanent test.", 2)
para(d, "Once the synonym check is done, turn it into a test that runs with every build. "
        "Then a future change to our example words cannot quietly split a synonym group "
        "again. The one in step 1 went unnoticed for months.")

# ============================================================ 6
h(d, "7.  Which matches need the most attention")
para(d, "Ranked by how many records are affected. The first two are the same problem seen "
        "twice: the same job written two ways, landing in two professions.")
table(d, ["What is wrong", "Records", "Why it happened", "What to do"],
 [["`research assistant professor` is in Researcher, while `assistant research professor` is in Teaching",
   "**85,845**","The machine matched one on *research assistant* and the other on *assistant professor*",
   "Decide which is right, then one line each"],
  ["`research director` is a researcher, but `director of research` was in a group that feeds nothing",
   "22,403","Same job, different word order","**Done** on 29 Oct"],
  ["`fellow` on its own was treated as a doctor in training",
   "48,777","Matched on *clinical fellow*, one word out of two","**Done** on 29 Oct"],
  ["`pi` was given no profession at all","17,219",
   "Scored 0.537, below the line we accept, so it was dropped","**Done** on 29 Oct"],
  ["`statistician` feeds nothing, but `biostatistician` and `bioinformatician` are researchers",
   "7,094","Three similar jobs, one treated differently","**Asked of marketing** — see the questions document"],
  ["`medical director` was treated as someone who treats patients","7,715",
   "A medical director runs a unit; they do not see patients","**Done** on 29 Oct — watch one side effect"],
  ["`privatdozent` and `pd` are given no profession","2,046",
   "German academic rank. Scored 0.642, just under the line","Check what `pd` really is, then two lines"],
  ["Retired and emeritus titles still in live audiences","15,317 records / **1,065 people**",
   "878 different spellings, no two alike","Recorded as a known limit. Not worth fixing"]],
 widths=[2.5,0.95,2.05,1.3], size=8.5)

box(d, "A RULE WE LEARNED THE HARD WAY THIS WEEK", [
 "We have always picked what to review by how many **records** a title carries. For "
 "finding people who are wrongly in an audience, that is the wrong order — by a factor "
 "of fourteen.",
 "",
 "`retired and emeritus titles   15,317 records`",
 "`people they actually put in an audience      1,065`",
 "",
 "The reason is simple. A role looks at a person's whole career. Someone who typed "
 "*Professor Emeritus* usually also has *Professor, 1990-2020* behind it, and that older "
 "record keeps them in the audience anyway. Removing the first one changes nothing for "
 "them.",
 "",
 "So: to fix the **dictionary**, sort by records. To fix the **audience**, sort by people. "
 "Using the first to answer the second nearly bought us a change we did not need.",
], fill="FAF2F5", accent=PLUM)

# ============================================================ 7
h(d, "8.  What happens next")
table(d, ["#", "What", "Why now", "Who"],
 [["1","Run the synonym check","Written as `analyses/28`. Finds splits like the 85,845-record one automatically. No judgement needed.","Us"],
  ["2","Fold its findings into the next build","So Students, the consent basis and these corrections all land in one rebuild and one round of checking.","Us"],
  ["3","Add the Students audience","Agreed at the meeting. All decisions already made: internships count, trainees do not, current post only, one bucket for all levels.","Us"],
  ["4","Add the fourth consent basis","`is_book_author_communications_opted_in`. Agreed. Half an hour.","Us"],
  ["5","Match the survey answers","The first real outside check. Needs the files.","Us"],
  ["6","Clinical expert call","The one gap no data source covers.","Merve / Bernadeta"],
  ["7","Reach the survey data in BigQuery","Chloe pointed at `Staging_Response`. Would make the check repeatable instead of a one-off export.","Us / data eng"]],
 widths=[0.3,1.8,3.2,1.3], size=9)

para(d, "Items 3 and 4 should go in the same build, so there is one rebuild and one round "
        "of checking rather than two.", space_after=4)
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

out = os.path.join(os.path.expanduser("~"), "Downloads", "ORCID-Role-Enrichment-Status-and-Plan.docx")
d.save(out)
print("saved:", out, os.path.getsize(out), "bytes")
