# -*- coding: utf-8 -*-
import sys, os
SP = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, SP)
from docx_lib import *
from docx.shared import Pt, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH as AL
# The committed figure directory - see the same note in build_doc.py. "fig"
# was a scratch path that existed on one machine only.
F = os.path.join(SP, "doc_figures")
d = doc_new()

p=d.add_paragraph(); p.paragraph_format.space_after=Pt(2)
r=p.add_run("ORCID ROLE ENRICHMENT"); r.bold=True; r.font.size=Pt(9.5)
r.font.color.rgb=PLUM; r.font.name=SANS
p=d.add_paragraph(); p.paragraph_format.space_after=Pt(4)
r=p.add_run("Questions for Marketing"); r.bold=True; r.font.size=Pt(22)
r.font.color.rgb=INK; r.font.name=SANS
para(d,"Eight open decisions  ·  updated 11 November 2026  ·  Analytics Engineering",
     size=9.5,color=MUT,space_after=12)

para(d,"Every question in here is a **definition**, not a technical problem. None of "
       "them can be settled from the data. Each one changes who receives a campaign, so "
       "each one belongs to marketing rather than to us.")
para(d,"**Nine questions were answered on 11 November and have been taken off this page** rather than left with a tick beside them — an answered question that stays on a list gets re-asked. They are recorded in section 6 with the date and the reasoning. What is left below is what is genuinely still open.", space_after=6)
para(d,"We have made a working choice for every question so that nothing is blocked. "
       "Those choices are marked. Any of them can be reversed in one line of "
       "configuration, so changing an answer is cheap — **leaving it undecided is what "
       "costs us**, because we cannot tell anyone what an audience means.", space_after=12)

# ---------------------------------------------------------------- SUMMARY
h(d,"The whole list, at a glance")
table(d,["#","Question","Size","Our working answer","Need"],
 [["1","What does \"Healthcare Professional (broad)\" mean now?","93,377 reachable","Needs your line — see 1","**High**"],
  ["2","Does the role library's grouping decide ours? *statistician, economist*","~1,300 records, being re-counted","No working answer","Medium"],
  ["3.1","Are visiting scholars and fellows teaching staff?","81,749 records","Yes, currently in","Medium"],
  ["3.2","Is an honorary professor active?","6,651 records","Yes, currently in","Medium"],
  ["3.3","Is a `dr` with a clinical department acceptable evidence?","146,865 records","Yes","Medium"],
  ["3.4","Should a past role still count?","not measured","Yes, for seven of nine","Medium"],
  ["3.5","Are vets healthcare professionals?","91+ people","In today, by accident","Medium"],
  ["3.6","Is sport science a healthcare field?","78+ people","In today, by accident","Medium"],
  ["4.1b","Should doctoral researchers be in Students as well?","~48,000 records","Yes, if 4.1 is yes","Confirm"],
  ["4.2","Two deliberate exclusions from Librarian","small","Both excluded","Low"]],
 widths=[0.4,2.8,1.0,1.4,0.6], size=8.5)
box(d,"ANSWERED ON 11 NOVEMBER — AND ONE OF THEM SET A PRINCIPLE",[
 "Nine questions were closed in one sitting. They are in section 6 in full; the two "
 "that change what an audience MEANS are these.",
 "",
 "**The second confidence tier stays off. Nobody we are not certain about enters an "
 "audience.** It would have added 45,054 unique people and nearly doubled the broad "
 "healthcare audience, by delivering people whose two signals disagree — a Paediatrics "
 "department against an Assistant Professor title.",
 "",
 "**Biomedical researchers ARE healthcare professionals.** 15,588 people join Clinical "
 "Researcher and, through the roll-up, the broad healthcare audience. That answer has "
 "a consequence for question 1 below and we would rather put it in front of you than "
 "let you find it: the broad audience now contains people who have never seen a "
 "patient, so the question left is what that audience should be CALLED and where its "
 "edge is — not whether research counts.",
], fill="F1F6F4", accent=TEAL)
box(d,"ONE QUESTION CLOSED SINCE THE LAST VERSION, AND IT SETS A PRINCIPLE",[
 "**Merve, 11 November: the second confidence tier stays off. Nobody we are not "
 "certain about goes into an audience.**",
 "",
 "The question used to be the first item on this page. It would have added 45,054 "
 "unique people, nearly doubling the broad healthcare audience, by delivering people "
 "whose two signals disagree — a Paediatrics department against an Assistant Professor "
 "title. It is now closed and the question has been removed rather than deferred.",
 "",
 "**The principle is the thing to carry into the rest of this page**: where the "
 "evidence is incomplete we would rather miss a person than send them a campaign that "
 "does not apply. Question 2 is the one place where that principle and our own working "
 "answer currently disagree — see the note there.",
], fill="F1F6F4", accent=TEAL)

# ---------------------------------------------------------------- 2+3
h(d,"1.  What does \"Healthcare Professional (broad)\" mean now?")
para(d,"This was asked on 10 November as *is healthcare about the work or the subject?* "
       "Your answer on biomedical researchers settles most of it, so here is the question "
       "that is actually left — and it is a narrower and more answerable one.")
box(d,"FIRST, THE FOUR HEALTHCARE AUDIENCES ARE NOT ONE QUESTION",[
 "We asked this as though it applied to all four. It does not, and three of them "
 "already carry their answer in how they are built.",
 "",
 "`hcp_practitioner   a clinical title AND a health department`",
 "`                   -> treating patients IS the definition. No question here.`",
 "",
 "`hcp_researcher     a RESEARCH title AND a health department`",
 "`                   -> patient contact was never required. Already subject-based.`",
 "",
 "`hcp_administrator  a LEADERSHIP title AND a health department`",
 "`                   -> runs a clinical unit. May never see a patient. No question.`",
 "",
 "`hcp_broad          a clinical title, PLUS everyone the three above roll up`",
 "`                   -> THIS is the only one the question applies to.`",
], fill="FAF2F5", accent=PLUM)
para(d,"So medical physicists, psychologists and clinical scientists are **not** the "
       "question we thought they were. They sit in the practitioner group today, they are "
       "staying there, and that is now a closed decision — section 6.")
h(d,"1a.  What your biomedical answer did to the broad audience",2)
para(d,"`hcp_researcher` now accepts a biomedical department as well as a clinical one, so "
       "**15,588 people** enter it, and because it rolls up, they enter `hcp_broad` too. "
       "That is what you asked for and it is one word of configuration.")
box(d,"AND IT MEANS THE BROAD AUDIENCE IS NO LONGER ALL CLINICIANS",[
 "`hcp_broad` is labelled **Healthcare Professional (broad)** in Braze. After this "
 "change it contains:",
 "",
 "`clinical practitioners        a clinical job title`",
 "`clinical administrators       leadership in a clinical unit`",
 "`clinical researchers          research in a health department`",
 "`biomedical researchers        research in a biomedical department   <- NEW`",
 "",
 "Somebody picking that audience for a campaign about **clinical guidelines or patient "
 "outcomes** will now reach about 15,588 people for whom it does not apply. Nothing is "
 "broken — the audience is doing what you asked — but the NAME no longer describes it.",
 "",
 "**Two ways to settle it, and this is the question:**",
 "",
 "**(a) Rename it.** *Healthcare & Life Sciences* or *Health Professionals & "
 "Researchers*. Costs nothing, one line, and anybody choosing the audience then knows "
 "what they are getting. Clinical practice campaigns use `hcp_practitioner` instead, "
 "which is 46,450 reachable people and is exactly that audience.",
 "",
 "**(b) Keep the name and keep the broad audience clinical**, with biomedical "
 "researchers in `hcp_researcher` only and not rolled up. This is a real change on our "
 "side rather than a line, because the roll-up is how the four audiences are held "
 "together.",
 "",
 "**We recommend (a).** The narrower audience you would want already exists.",
], fill="FDF8EF", accent=AMBER)
h(d,"1b.  And the two cases at the edge, which are the same question",2)
para(d,"Veterinarians and sport science (3.5 and 3.6 below) are this question asked about "
       "two fields. Both are in the healthcare audiences today by accident, neither was "
       "decided, and both follow from wherever you draw this line.")

# ---------------------------------------------------------------- 4
h(d,"2.  Does the role library's grouping decide ours?")
para(d,"Chloe's role library gives every job title a `role_type`. For two families it "
       "gives the SAME `role_type` to titles we treat completely differently, and on "
       "11 November we found that one half of that was our own mistake and the other half "
       "is a question for you.")
box(d,"WHAT THE LIBRARY SAYS, BESIDE WHAT WE DO",[
 "The `role_type` column is the library's own. The right-hand column is measured — "
 "where the records actually sit in our dictionary on 11 November.",
 "",
 "`                       library role_type                      ours`",
 "`Research Statistician   Specialist researcher / practitioner   Researcher`",
 "`Statistician            Specialist researcher / practitioner   SPLIT, see below`",
 "`Medical Statistician    Specialist researcher / practitioner   SPLIT`",
 "`Research Economist      Specialist researcher / practitioner   Researcher`",
 "`Economist               Specialist researcher / practitioner   SPLIT`",
 "`Research Analyst        Research / policy analyst              SPLIT`",
 "`Research Officer        Research / policy analyst              support staff`",
 "",
 "The library makes **no distinction at all** inside either family. We make one, and "
 "the only thing our distinction rests on is whether the person typed the word "
 "*research*. Not what they do — what they typed.",
])
h(d,"2a.  Half of this was our own mistake, and it is being fixed",2)
para(d,"The research-officer family fed no audience. We assumed the model had failed to "
       "recognise it. It had not.")
box(d,"THE MODEL WAS RIGHT. THE DICTIONARY ENTRY WAS OURS.",[
 "`research officer` was itself one of our **example titles for the support-staff "
 "group**. So the model matched it against that example perfectly, scored it 1.000, "
 "and filed the family under support staff — a group that feeds no audience at all.",
 "",
 "Measured on 11 November, the family is **4,829 records**: 4,056 of them in support "
 "staff and 738 already in Researcher, split by nothing but how verbose the title was.",
 "",
 "**Fixed the same day, on Merve's instruction: the research-officer family belongs in "
 "Researcher.** A rule now sends `research officer`, `research analyst` and `research "
 "executive` there, scoped so it can only move titles out of support staff and cannot "
 "touch anything already placed. `research support officer` is deliberately NOT caught "
 "— that one really is support work.",
 "",
 "**Nothing is needed from you on this half.** It is here because it is the clearest "
 "example of something this project keeps proving: when an audience looks wrong, the "
 "cause is far more often a line we wrote than the model guessing badly.",
], fill="F1F6F4", accent=TEAL)
box(d,"AND A CORRECTION TO A FIGURE WE GAVE YOU YESTERDAY",[
 "Yesterday's version of this document said `research officer` carried **34,376 "
 "records**. **It does not.** The whole family is 4,829 records, measured.",
 "",
 "The 34,376 was never produced by a query. It existed only in the script that builds "
 "this document, so it was never a measurement, and the same is true of the per-title "
 "figures this section used to carry for statisticians and economists.",
 "",
 "We are telling you because every other number in this document is traceable to a "
 "named query, and the one way that stays true is by saying so when one is not. The "
 "figures below are measured; where a measurement is still running it says so.",
], fill="FBF1EF", accent=RED)
h(d,"2b.  The other half IS a question — statisticians and economists",2)
para(d,"**Measured, and smaller and stranger than we said.** Neither family is \"in no "
       "audience\". Both are already split roughly down the middle by nothing anyone chose.")
table(d,["Family","In an audience (Researcher)","In support staff — no audience"],
 [["Statistician / biostatistician","1,084 records","**866 records**"],
  ["Economist","569 records","**436 records**"]],
 widths=[2.2,1.9,2.0])
para(d,"So the question is about **~1,300 records** sitting in support staff while their "
       "near-identical siblings sit in Researcher — not the 12,469 we said yesterday. "
       "And that 1,300 is a **floor**: the measurement that produced it reads English and "
       "Romance spellings only, so `statistiker`, `estatístico` and `istatistikçi` are "
       "not in it yet. The multilingual count is running.")
para(d,"**The argument for leaving them out.** The job title alone does not say whether the "
       "person does research or provides statistical support to a research office. And the "
       "Researcher audience has **no subject check** — unlike healthcare, where the "
       "department has to agree, there is no second signal to catch a wrong one.")
para(d,"**The argument for taking them in.** The library says they are the same job as the "
       "ones we already accept, and a statistician at a university is doing research by "
       "any normal reading of the word.")
para(d,"**We have no working answer on this one, which is unusual for this document.** The "
       "two readings are equally defensible, and the deciding factor is what your campaigns "
       "are for. If a Researcher campaign is about research OUTPUT — publishing, "
       "authorship, grants — a support statistician does not belong in it. If it is about "
       "working in research, they do.")
para(d,"**And if the answer is yes, there is a second part.** Should they go to Researcher, "
       "or to a practitioner-style audience as specialists? The library files them under "
       "*Specialist researcher / practitioner*, which is deliberately both.")

h(d,"3.  Six medium questions, each one line to change")

h(d,"3.1  Are visiting scholars and fellows teaching staff?  (81,749 records)",2)
para(d,"`visiting scholar` 60,561, `visiting fellow` 15,832, `visiting research scholar` "
       "5,356 — all currently counted as teaching staff because of the word *visiting*.")
para(d,"A visiting scholar may teach, or may only do research. We already moved "
       "`visiting scientist` (32,662 records) out without asking, because a scientist does "
       "not teach. These three are genuinely ambiguous and the word *scholar* leans academic.")

h(d,"3.2  Is an honorary professor active?  (6,651 records)",2)
para(d,"On 16 October you asked us to reject `emeritus professor`, `retired professor` and "
       "`honorary researcher` outright, on the grounds that a retired professor is not a "
       "researcher. We did. **`honorary professor` survived**, and it is not obviously "
       "different.")
box(d,"ONE WORD, TWO MEANINGS",[
 "Market Intelligence's role library puts **Honorary Researcher** on the same line as "
 "Emeritus Researcher, under \"Former or inactive\". That supports rejecting it.",
 "",
 "But in ORCID, *honorary* is very often an **unpaid university title held by somebody "
 "actively employed somewhere else** — an NHS consultant with a university affiliation, "
 "for example. That is the opposite case: active, not retired.",
 "",
 "Both readings are defensible. We would rather you chose than we guessed.",
])

h(d,"3.3  Is a `dr` WITH a clinical department acceptable evidence?  (146,865 records)",2)
para(d,"`dr` carries **96,676 records** and `md` **50,189**. Together that is 9.1% of the "
       "clinical group. Neither says anything about a profession beyond holding a "
       "doctorate.")
para(d,"Both are resolved entirely by the department. A clinical department confirms them; "
       "without one they stay in the second tier — and since 11 November the second tier is "
       "never delivered, so **a bare `dr` with no clinical department is already excluded**. "
       "What is left of this question is narrower than it was: whether a `dr` WITH a "
       "clinical department is acceptable evidence on the department alone.")

h(d,"3.4  Should a past role still count?",2)
para(d,"Seven of the nine audiences count past employment. Somebody who was a researcher "
       "in 2010 and works in a bank today is still in the Researcher audience — on the "
       "reasoning that *researcher* is a profession you have rather than a post you hold.")
para(d,"**Head of faculty and Librarian are the exceptions** and count current posts only, "
       "because a former dean is not a dean. If you want the others to behave the same way "
       "it is one line per audience. **The size of that change has not been measured** and "
       "should be before it is made.")

# ---------------------------------------------------------------- LOW
h(d,"3.5  Are veterinarians healthcare professionals?  (91+ people)",2)
para(d,"Found on 10 November while reading a sample of the Clinical Researcher audience "
       "by hand. Veterinary departments are being read as clinical, so vets are in the "
       "healthcare audiences today. Nobody decided that — it happened because veterinary "
       "medicine is medicine and the word carries.")
table(d,["Department","People"],
 [["`Faculty of Veterinary Medicine`","43"],
  ["`Veterinary Pathology`","13"],
  ["`School of Biodiversity, One Health and Veterinary Medicine`","14"],
  ["`Veterinary Public Health`","7"],
  ["`Veterinary Epidemiology`","2"]],
 widths=[4.2,0.9])
para(d,"**91 is a floor, not a total.** It was counted inside one audience, Clinical "
       "Researcher, from a truncated list. The same departments also feed HCP broad and "
       "HCP practitioner, so the real figure across healthcare is larger.")
para(d,"**The case for yes.** A vet is a regulated clinician who diagnoses, prescribes "
       "and operates, and reads clinical literature to do it. For a journals campaign "
       "that may be the whole point.")
para(d,"**The case for no.** Every other audience here is defined by treating people. A "
       "campaign about patient outcomes, clinical guidelines or hospital practice does "
       "not apply to a vet, and arriving in their inbox is the kind of mismatch that "
       "costs more than a missing contact.")
para(d,"**One genuinely hard case either way:** *One Health* departments, 14 people. "
       "Their subject is by definition the intersection of human and animal health.")
para(d,"**Our working answer: no.** But it follows from question 1 rather than standing "
       "on its own — if the broad audience is renamed to cover life sciences as well as "
       "clinical practice, the case for keeping vets out gets weaker, not stronger.")

h(d,"3.6  Is sport and exercise science a healthcare field?  (78+ people)",2)
para(d,"Same reading, same day, and this one splits cleanly down the middle of its own "
       "vocabulary.")
table(d,["Department","People","Reads as"],
 [["`Sports Medicine`, `Institute of Sport and Exercise Medicine`","~25","**Clinical** — medicine"],
  ["`Faculty of Sport Sciences`, `Department of Sport Science`","~45","Not clinical"],
  ["`Physical Education and Sports`","6","Not clinical"],
  ["`Faculty of Sport and Health Sciences`","~35","Both words in one name"]],
 widths=[3.1,0.7,1.4])
para(d,"A sports physician treats patients. A sport scientist studies performance. The "
       "department names sit on both sides and a third group names both at once, which "
       "is why this needs a line drawn rather than a judgement per department.")
para(d,"**Our working answer: keep the ones that say *medicine*, drop the rest.** Same "
       "dependency as vets above: question 1 decides it.")

h(d,"4.  Two decisions we are implementing, and one small exclusion")
h(d,"4.1  A title may name TWO professions — REVERSED 11 November",2)
para(d,"A title belongs to exactly one profession today. Some people write both jobs into "
       "one title, and the system makes us choose. On 30 October we chose Lecturer and "
       "asked you to confirm it.")
box(d,"MERVE, 11 NOVEMBER: NO. IF THE TITLE SAYS TWO JOBS, THE PERSON IS IN BOTH AUDIENCES.",[
 "`lecturer and researcher    ~47,000 records  ->  Lecturer AND Researcher`",
 "`professor and chair/head   ~31,000 records  ->  Lecturer AND Head of Faculty`",
 "`professor and director     ~68,000 records  ->  Lecturer AND Head of Faculty`",
 "",
 "**And the limit of the decision, stated because it is easy to over-read.** This "
 "applies only where **the ORCID title itself names two jobs**. Where somebody wrote "
 "only *Professor* in ORCID and told a survey they are a research scientist, ORCID "
 "still wins and they are a Lecturer. We are not using survey answers to override what "
 "people recorded about their own employment.",
], fill="F1F6F4", accent=TEAL)
para(d,"**It is being implemented now, and it is not a setting.** A title currently gets "
       "exactly one group in our dictionary — one row, one answer — which is why the "
       "nonsense in 4.1a below exists at all. The work is to let a title carry a second "
       "group, measure what moves, and read the two affected audiences again afterwards. "
       "We will report the before and after rather than estimate it.")
para(d,"**What it costs you.** A professor who also runs a research group is in the "
       "Lecturer audience and not in Researcher. A professor who also heads a department "
       "is in Lecturer and not in Head of Faculty. If either of those matters for a "
       "campaign, tell us and we will reopen it.")
box(d,"WHAT THE SURVEY DATA SHOWED",[
 "We compared our answer against 290,000 people who had picked their own job title in a "
 "Market Intelligence survey. Overall we agreed 81.8% of the time, against a ceiling of "
 "88.9% — which is how often the same person agrees with their OWN earlier answer.",
 "",
 "Two audiences scored far below that, and the cause is the same in both:",
 "",
 "`4,210  said \"research scientist\"   we said lecturer`",
 "`  654  said \"head of department\"   we said lecturer`",
 "`2,602  said \"PhD student\"          we said lecturer`",
 "",
 "Every one of them has **Professor** recorded as their job title in ORCID, and a title "
 "can belong to only one profession in our system. So a professor who runs a research "
 "group is in Lecturer and not in Researcher; a professor who heads a department is in "
 "Lecturer and not in Head of Faculty.",
 "",
 "The Researcher audience scored 69.9% and Head of Faculty 20%, and this rule is the "
 "largest single reason for both.",
], fill="FBF1EF", accent=RED)
box(d,"THE EXAMPLE THAT SHOWS IT",[
 "`research assistant professor   71,785 records  ->  Researcher`",
 "`research professor             48,609 records  ->  Researcher`",
 "`professor of neurology          1,815 records  ->  Practitioner`",
 "",
 "**None of these is wrong.** A research assistant professor really is a research post. "
 "A professor of neurology really is a neurologist.",
 "",
 "But a research assistant professor also **teaches**, and the Lecturer audience does not "
 "contain them. So Lecturer undercounts professors.",
 "",
 "Letting one title carry two professions would fix it. That is a design change rather "
 "than a setting, so it is here for awareness, not for a decision now.",
])
h(d,"4.1a  The same decision, applied to *professor and director*",2)
para(d,"Measured the same day. Those compound titles are currently split between the "
       "teaching group and the leadership group **by word order**, which cannot be "
       "defended whichever way you answer.")
box(d,"THE SAME TWO WORDS, FOUR DIFFERENT ANSWERS",[
 "`professor and director   4,601  ->  Head of Faculty`",
 "`professor & director     2,185  ->  Lecturer`",
 "`professor director       2,140  ->  Lecturer`",
 "`director professor       1,110  ->  Head of Faculty`",
 "`director/professor       2,033  ->  Head of Faculty`",
 "`professor/director       1,256  ->  Lecturer`",
 "",
 "The only thing separating them is the separator and the order. About **68,000 "
 "records** in total: 44,000 currently in Lecturer, 24,000 in Head of Faculty.",
])
para(d,"One rule has to cover all of them, and it costs something either way. Sending "
       "them all to **Lecturer** removes 24,000 records from Head of Faculty, which is "
       "already our weakest audience. Sending them all to **Head of Faculty** removes "
       "44,000 from Lecturer — 0.4% of a group of twelve million.")
para(d,"**This is no longer a choice between the two, because of 4.1: all six spellings go "
       "to BOTH.** A professor who is also a director is in Lecturer and in Head of "
       "Faculty, which is what their own title says. Head of Faculty gains the ~24,000 "
       "records it was losing to word order, Lecturer keeps its ~44,000, and the "
       "separator stops deciding anything.")

h(d,"4.1b  The same decision, applied to doctoral researchers",2)
para(d,"The third instance of the same decision, and the one we need confirmed. The "
       "Students audience is being built now, and whether it holds every doctoral student depends on 4.1.")
box(d,"THE SAME PERSON, TWO DIFFERENT AUDIENCES",[
 "`phd student           472,677  ->  Students`",
 "`phd candidate         184,217  ->  Students`",
 "`doctoral researcher    42,231  ->  Researcher`",
 "`postgraduate researcher 5,427  ->  Researcher`",
 "",
 "All four are doctoral students. The role library lists them as **one job**.",
 "",
 "They are split because of a decision you already made: *if they research, they go in "
 "the Researcher audience, doctoral student or not*. Somebody who describes themselves "
 "as a doctoral researcher is telling us they research.",
 "",
 "**The consequence:** the Students audience will not contain every doctoral student. "
 "About 48,000 records' worth describe themselves in research terms and sit in Researcher "
 "instead. Some people will be in both.",
], fill="FDF8EF", accent=AMBER)
para(d,"**The question: should those last two rows be in Students as well as Researcher?** With 4.1 answered yes, a title that says both *doctoral* and *researcher* can carry both groups, and the person appears in both audiences. We think that is right and it is the consistent answer, but Students is a new audience and ~48,000 records of it turn on this, so we want your word rather than our inference.")

h(d,"4.2  Two deliberate exclusions from Librarian",2)
para(d,"**Archivists are not included** — the word pulled in archaeologists, glaciologists "
       "and clerks, and archivists are a separate call from the one you made. "
       "**\"Information specialist\" is not included** — it pulled in every IT job in the "
       "data. Either can be added as one line, as a decision rather than a guess.")
h(d,"5.  Head of Faculty — ANSWERED 11 November, recorded in full")
para(d,"Originally asked as \"is a Director at a university a head of faculty?\" — about "
       "2,900 people. Reading the group showed it splits cleanly in two.")
table(d,["Never academic — 53,599 records","","Could be either — 172,611 records",""],
 [["`ceo`","15,918","`director`","**144,252**"],
  ["`founder`","6,952","`president`","11,625"],
  ["`managing director`","5,568","`vice president`","6,324"],
  ["`general manager`","3,513","`principal`","5,482"],
  ["`owner`","3,395","`board member`","1,706"]],
 widths=[1.9,0.8,1.9,0.8])
box(d,"THE DECISION IS SMALLER THAN THE NUMBERS LOOK",[
 "The organisation already does most of this work. Head of faculty scores a **company at "
 "zero**, so a corporate title at a company cannot be confirmed at all.",
 "",
 "`ceo       879 people found  ->  only 55 confirmed`",
 "`founder   411 people found  ->  only 31 confirmed`",
 "`owner     188 people found  ->  only  2 confirmed`",
 "",
 "So the question is not \"should a CEO be a head of faculty\" — almost none are. It is "
 "whether those 55, and the same residue on every other title, should be excluded by name.",
])
para(d,"**Our working answer:** exclude the never-academic list by name; keep the "
       "ambiguous list, because excluding `president` would lose real university presidents.")
box(d,"DECIDED 11 NOVEMBER — THEY STAY IN, AND HERE IS WHAT THAT COSTS",[
 "**Merve, 11 November: if the person works at a university, the organisation is an "
 "educational institution and the title is director, chair or head — keep them.**",
 "",
 "The question is closed and the 267 people below stay in the audience. Two things are "
 "worth recording with it.",
 "",
 "**The organisation side was already as strict as it can be.** Since 5 November Head "
 "of Faculty scores every ROR organisation type except Education at **zero**, including "
 "an unresolved one. With a 0.65 threshold that means nobody confirms without a "
 "verified educational employer — no hospitals, no research institutes, no companies, "
 "no national laboratories, and nobody whose employer we could not identify. That "
 "removed 1,968 people on 5 November and ~2,000 on 29 October.",
 "",
 "**So what remains is a reported error rate, not a hidden one.** The audience is "
 "79.2% certainly right, 15.0% these 267 people, and **5.7% our own error**. We quote "
 "the 5.7% rather than bury it, and the accuracy table at the end of this document "
 "reads 83.3% for exactly this reason.",
], fill="F1F6F4", accent=TEAL)
box(d,"NEW — WE HAVE NOW PRICED THIS QUESTION, AND IT IS THE LARGEST THING LEFT IN THE AUDIENCE",[
 "Measured 3 November against 1,775 people in Head of faculty whose own words we can "
 "check. The audience divides in three:",
 "",
 "`79.2%  certainly right   223 called themselves leadership; 1,185 hold a title that`",
 "`                         names a faculty-level post`",
 "`15.0%  UNCERTAIN         267 people holding ONLY chair, director or head, with no`",
 "`                         faculty word anywhere beside it  <-- THIS QUESTION`",
 "` 5.7%  wrong             102 people with no leadership word at all`",
 "",
 "So this is not a corner of the audience, it is **one person in seven**. And whichever "
 "way you answer, the uncertainty disappears: in, and those 267 are right by definition; "
 "out, and they leave. **After this answer the audience is as defensible as we can make "
 "it** — the remaining 5.7% is our error rate and we report it rather than hide it.",
], fill="FDF8EF", accent=AMBER)
para(d,"One note for a publisher. `editor-in-chief`, **5,172 records**, was in this group "
       "until 21 October — an editorial role reading as institutional leadership. Now moved.")

h(d,"5a.  The hospital side of the same question",2)
para(d,"Measured on 29 October. About **2,000 people** were reaching Head of Faculty "
       "through an organisation that reads as a hospital rather than a university.")
table(d,["Title at a hospital","People","Is this a head of faculty?"],
 [["`director`","826","Unclear"],
  ["`head of department`","294","**Genuinely ambiguous** — medical school departments are often based in hospitals"],
  ["`head`","225","Unclear"],
  ["`chief`","213","Probably clinical, not academic"],
  ["`medical director`","95","**No.** Runs a clinical unit"],
  ["`dean`","17","**Yes** — a real academic title"]],
 widths=[1.6,0.7,4.3])
box(d,"WHAT WE DID, AND WHY WE ARE TELLING YOU",[
 "**Merve's decision, 29 October: Head of Faculty is university heads only.**",
 "",
 "The reasoning: there is no second signal available in this audience. Healthcare has a "
 "department check, Lecturer has none but is huge — Head of Faculty is small and built "
 "for precision, so it takes only what we are certain of.",
 "",
 "**The cost, measured before deciding: those ~2,000 people leave**, including the 294 "
 "heads of department and the 17 deans above. We would rather have a small, certain "
 "audience and grow it later from a proper faculty-leadership source than keep a larger "
 "one we cannot defend.",
 "",
 "**One trap we caught on the way.** The word *medical school* was filed under hospitals "
 "in our settings, not under universities. Removing hospitals would have removed medical "
 "school deans too. It has been moved.",
 "",
 "If you would rather keep the hospital path, it is one line to put back — but then the "
 "`head of department` question above has to be answered.",
], fill="FDF8EF", accent=AMBER)

# ---------------------------------------------------------------- 5 NEW
h(d,"6.  Already decided — recorded so nobody re-opens them")
table(d,["Question","Decision","When"],
 [["Should the second confidence tier be delivered? (45,054 unique people, "
   "and nearly double the broad healthcare audience)",
   "**No. Confirmed only.** Nobody we are not certain about enters an audience. The "
   "`consultant` country rule that was a precondition for switching it on falls away "
   "with it.","**11 Nov**"],
  ["Are teaching assistants in the Lecturer audience? (178,205 records)",
   "**Yes.** If they teach, they are a lecturer, doctoral student or not.","21 Oct"],
  ["Are doctoral students who research in the Researcher audience? (197,895 records)",
   "**Yes.** Same principle read across: if they research, they are a researcher.","21 Oct"],
  ["Should retired and emeritus people be in live audiences? (17,277 records removed)",
   "**No.** A retired professor is not a lecturer.","16 Oct, confirmed 29 Oct"],

  ["Should we build audiences for students and support staff?",
   "**Students yes, support staff no.** Students is being built now.","21 and 23 Oct"],

  ["Should Head of faculty include hospital-based leaders? (~2,000 people)",
   "**No.** University heads only. Small and certain beats large and arguable.","29 Oct"],

  ["Should Researcher split into early-career and senior?",
   "**No, and withdrawn.** One Researcher audience, and the route to seniority "
   "would be dates rather than title words.","4 Nov"],
  ["Does book-author consent cover a role-based campaign? (26,654 people)",
   "**Yes**, from the Head of Marketing. The fourth consent basis is built and "
   "delivering; reachable means any one of the four.","**11 Nov**"],
  ["Are biomedical researchers healthcare professionals? (15,588 people)",
   "**Yes.** They join Clinical Researcher and, through the roll-up, the broad "
   "healthcare audience. See 1a for the one consequence.","**11 Nov**"],
  ["Are psychologists, medical physicists and clinical scientists in the right "
   "place? (~5,000 records)",
   "**Leave them exactly as they are** — in the practitioner group and in the "
   "broad healthcare audience. Four questions closed in one line.","**11 Nov**"],
  ["Should a bare `director`, `chair` or `head` at a university be a head of "
   "faculty? (267 people, 15.0% of the audience)",
   "**Yes, keep them.** An educational employer is already required and already "
   "verified. See 5.","**11 Nov**"],
  ["Should a title that names two jobs count as both? (78,000+ records)",
   "**YES — reversed from the 30 October answer.** See 4.1. Being implemented.",
   "**11 Nov**"],
  ["Is a doctoral student in Researcher because they are a doctoral student?",
   "**No — the title has to say so.** Being a doctoral student is not the "
   "qualification; a title naming research is. `phd fellow`, 19,424 records, "
   "names neither and comes out.","4 Nov"],
  ["Can someone be a healthcare professional with no clinical job title? (6,115 people)",
   "**No.** They were in the broad HCP audience on their department alone — an "
   "administrator in a cardiology department. The job title is now mandatory. "
   "**1,445 marketable contacts leave.**","4 Nov"]],
 widths=[3.0,2.3,0.9], size=8.5)
box(d,"ONE RESIDUE ON THE RETIREMENT DECISION",[
 "We removed 17,277 records of retired and emeritus people. About **1,065 people** remain "
 "in live audiences on a retirement title — 692 of them in Lecturer, which is **0.17%** "
 "of that audience.",
 "",
 "They are left because there is no efficient way to remove them: 878 different spellings, "
 "and almost no two people write it the same way. `honorary and visiting academic, "
 "emeritus professor`. `retired, full professor, full professor (emeritus)`.",
 "",
 "We are telling you rather than quietly fixing it, because **we cannot claim an audience "
 "is clean to 0.17%** and would rather you knew the floor.",
])

# ---------------------------------------------------------------- CLOSE
h(d,"7.  What we need from this meeting")
table(d,["Priority","Question","Why it cannot wait"],
 [["1","What should the broad healthcare audience be called, and where is its "
   "edge? (Q1)",
   "Your biomedical answer put 15,588 non-clinicians into an audience named "
   "*Healthcare Professional*. The name is now wrong or the roll-up is — and vets "
   "and sport science follow from the same line"],
  ["2","Do statisticians and economists belong in an audience? (Q2b)",
   "~1,300 records, and the only question in this document where we have no "
   "working answer to fall back on"],
  ["3","Confirm doctoral researchers in Students as well as Researcher (Q4.1b)",
   "~48,000 records, and Students is a new audience whose size depends on it"],
  ["4","Everything else","One line each, any time"]],
 widths=[0.65,2.6,3.0], size=9)
para(d,"**One correction we owe you, repeated here because it changes every number you "
       "have been given.** Every \"reachable\" figure quoted before 10 November counted "
       "marketing opt-in ALONE — one basis out of four. It understated the audience by "
       "between 2.2 and 4.1 times. Lecturer was reported as 109,323 and is **319,291**. "
       "Legitimate interest is the whole gap: 295,314 of Lecturer hold it against 109,323 "
       "with marketing consent. The pipeline has been right since 16 October; the "
       "reporting was reading a narrower column. Every number in this document is now the "
       "four-basis figure.")
para(d,"**And one question we were going to ask and are not, because we measured it "
       "instead.** The CDP carries three more consents — editor referral, editorial board "
       "members, webshop buyer. Each is permission for a different communication, so none "
       "is a basis for a role campaign without your word. They reach **251 people** that "
       "nothing else reaches, 0.03% of the reachable total. Ruling them in would not move "
       "anything, so we are not asking.", space_after=12)
para(d,"**There is now an accuracy figure, and here is exactly what it is.** ORCID has "
       "no profession field, so there is nothing to compare against automatically. "
       "Instead, on 5 November 400 Confirmed people were drawn at random from each "
       "audience and read one at a time — job title, employer, department — and marked "
       "correct, wrong or not sure.")
table(d,["Audience","Correct, of the decided","Reachable"],
 [["Researcher","99.0%","237,391"],
  ["Lecturer","98.7%","319,291"],
  ["Librarian (all 692 read)","98.5%","384"],
  ["Pharmacist","95.7%","1,531"],
  ["HCP administrator","94.9%","5,949"],
  ["**Clinical researcher**","**94.3%** — read 3 times","39,758"],
  ["HCP practitioner","93.4%","46,450"],
  ["HCP broad","90.6%","93,377"],
  ["**Head of Faculty**","**83.3%**","11,962"]],
 widths=[2.0,2.1,1.3], size=9)
para(d,"Clinical researcher is the one that moved. It was 90.0% on 5 November and 89.0% on "
       "a second sample, then **94.3%** after the department dictionary was corrected on "
       "10 November. The change is within sampling noise at 100 people, so we are not "
       "claiming it as proven — but the ERRORS changed in the way the fix predicts. "
       "Departments that are not human health fell from 4 in 10 to 2 in 5, and both "
       "survivors are fields we have not addressed yet.")
para(d,"**On 10 November the lowest of those was read again, by a different reader, on "
       "100 different people: 89.0%.** One point apart from 90.0%. That is the first "
       "quality figure in this project that has been reproduced rather than asserted.")
para(d,"Two things the table does not say. *Not sure* is left out of the percentage, and "
       "for Head of Faculty it is a third of the sample — almost all of it the `director` "
       "question, Question 2 here, so answering that question is what moves the number. "
       "And the figure is about whether we read the job title correctly, not about "
       "whether the person is still in that job.")
para(d,"Underneath it, every decision is inspectable: name any person and we can show you "
       "the words they typed, what it matched, how close it was, and whether a human or "
       "the model decided.")

# The repo copy is the deliverable - Merve pulls from git, so a file that
# exists only in one machine's Downloads folder reaches nobody. Downloads is
# kept as well because that is where it gets attached to an email from.
for out in (os.path.join(os.path.dirname(SP), "docs", "ORCID-Questions-for-Marketing.docx"),
            os.path.join(os.path.expanduser("~"), "Downloads", "ORCID-Questions-for-Marketing.docx")):
    d.save(out); print("saved:", out, os.path.getsize(out), "bytes")
