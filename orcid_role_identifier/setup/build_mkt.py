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
para(d,"Sixteen open decisions  ·  updated 11 November 2026  ·  Analytics Engineering",
     size=9.5,color=MUT,space_after=12)

para(d,"Every question in here is a **definition**, not a technical problem. None of "
       "them can be settled from the data. Each one changes who receives a campaign, so "
       "each one belongs to marketing rather than to us.")
para(d,"We have made a working choice for every question so that nothing is blocked. "
       "Those choices are marked. Any of them can be reversed in one line of "
       "configuration, so changing an answer is cheap — **leaving it undecided is what "
       "costs us**, because we cannot tell anyone what an audience means.", space_after=12)

# ---------------------------------------------------------------- SUMMARY
h(d,"The whole list, at a glance")
table(d,["#","Question","Size","Our working answer","Need"],
 [["1","Is \"healthcare professional\" about the work or the subject?","settles 5 others","Work (treats patients)","**High**"],
  ["1a","Are biomedical researchers healthcare professionals?","15,588 people","No","**High**"],
  ["2","Which leadership titles are a head of faculty?","**267 people = 15.0% of the audience**","Keep ambiguous ones in. **Hospitals now excluded**","**High**"],
  ["3","Does the word \"research\" in a title decide the audience?","~55,000 records","No","**High**"],
  ["4","Does book-author consent cover a role campaign?","26,654 people",
   "**BUILT 10 Nov** — want it in writing","Confirm"],
  ["5.1","Are psychologists healthcare professionals?","~4,500 records","Yes, currently in","Medium"],
  ["5.2","Four smaller versions of the same question","2,743 records","Yes, currently in","Medium"],
  ["5.3","Are visiting scholars and fellows teaching staff?","81,749 records","Yes, currently in","Medium"],
  ["5.4","Is an honorary professor active?","6,651 records","Yes, currently in","Medium"],
  ["5.5","Is an uninformative title (dr, md) acceptable evidence?","146,865 records","Yes, if the department agrees","Medium"],
  ["5.6","Should a past role still count?","not measured","Yes, for seven of nine","Medium"],
  ["5.8","Are vets healthcare professionals?","91+ people","In today, by accident","Medium"],
  ["5.9","Is sport science a healthcare field?","78+ people","In today, by accident","Medium"],
  ["6.1","Should a job title be allowed in two professions?","78,000 records","**DECIDED — no.** Please confirm","Confirm"],
  ["6.1a","*professor and director* — split today by word order alone","68,000 records","Recommend Head of Faculty","**High**"],
  ["6.2","Two deliberate exclusions from Librarian","small","Both excluded","Low"],
  ["—","*Switch on the second confidence tier?*","*45,054 people*","**CLOSED 11 Nov — no. See 7**","—"],
  ["—","*Should Researcher split into early and senior?*","—","**WITHDRAWN 4 Nov — not splitting**","—"]],
 widths=[0.35,2.5,1.05,1.55,0.6], size=8.5)
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
h(d,"1.  One question settles five of the others")
para(d,"Questions 1a, 3, 5.1 and 5.2 are the same question asked about different jobs. Answer "
       "it once and they all resolve.")
box(d,"THE QUESTION",[
 "**Is \"healthcare professional\" about the work, or about the subject?**",
 "",
 "A biomedical researcher, a psychologist, a medical physicist, a genetic counsellor and "
 "a mental health support worker all work in health **without practising medicine**.",
 "",
 "If our healthcare campaigns are about **clinical practice** — journals for surgeons, "
 "drug information — then these people do not belong.",
 "",
 "If they are about **medical content** — biomedical journals, health research — then "
 "they do.",
 "",
 "That fact lives in your campaign plans. It is not in our data and no amount of "
 "analysis will find it.",
], fill="FAF2F5", accent=PLUM)
para(d,"**And today's line is inconsistent, which is why we are asking.**")
table(d,["Who","Size","In today?","Sees patients?"],
 [["Biomedical researchers","15,588 people","**No**","No"],
  ["Medical physicists / clinical scientists","346 records","**Yes**","No"],
  ["Psychologists","~4,500 records","Yes","Usually"],
  ["Genetic counsellors","866 records","Yes","Yes"],
  ["Counsellors","1,205 records","Yes","Yes"],
  ["Mental health support workers","326 records","Yes","Yes"]],
 widths=[2.3,1.1,0.9,1.1])
para(d,"Look at the first two rows. **Medical physicists are in and biomedical researchers "
       "are out, and neither sees patients.** There is no principled reason for that. One "
       "is in because it is small enough that nobody asked; the other is out because it was "
       "big enough that we had to choose.")
para(d,"A useful test when you decide: *could two reasonable, equally well-informed people "
       "disagree and both be right?* If yes, it is a definition question. \"Is an "
       "internist a trainee?\" fails that test — one of them is simply wrong. \"Are "
       "biomedical researchers healthcare professionals?\" passes it.")
box(d,"WHAT EACH ANSWER ACTUALLY CHANGES — PRICED 11 NOVEMBER",[
 "**If the answer is WORK** — healthcare means treating patients:",
 "",
 "`OUT        medical physicists / clinical scientists      346 records`",
 "`OUT        academic psychologists (bare psicólogo/a)    2,658 records`",
 "`OUT        veterinarians                                  91+ people`",
 "`OUT        sport science that does not say medicine       ~51 people`",
 "`STAYS OUT  biomedical researchers                     15,588 people`",
 "",
 "The four healthcare audiences shrink by roughly **3,100 records**, which is under "
 "1% of them. The 15,588 biomedical researchers are not lost to us — they stay in the "
 "Researcher audience, which already reaches them. **This answer costs almost nothing "
 "and makes the word mean one thing.**",
 "",
 "**If the answer is SUBJECT** — healthcare means medical content:",
 "",
 "`IN         biomedical researchers                   15,588 people`",
 "`IN         veterinarians                               91+ people`",
 "`IN         all sport and exercise science               ~78 people`",
 "`STAYS IN   medical physicists, all psychologists`",
 "",
 "The broad healthcare audience grows by about **16,000 people** and nothing leaves. "
 "The cost here is not a number. It is that *healthcare professional* would no longer "
 "mean a clinician, so a campaign about clinical practice could not be sent to that "
 "audience by name — a narrower clinical audience would have to be built underneath it, "
 "which is a week of our work rather than a line.",
 "",
 "**Both answers are defensible and both are one word of configuration.** What is not "
 "defensible is today's line, which runs through the middle of the same reasoning.",
], fill="FAF2F5", accent=PLUM)

# ---------------------------------------------------------------- 4
h(d,"2.  Which leadership titles count as a head of faculty?")
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
box(d,"AND THE 11 NOVEMBER PRINCIPLE POINTS THE OTHER WAY FROM OUR OWN WORKING ANSWER",[
 "Our working answer above keeps the ambiguous titles **in**. Merve's decision on the "
 "second confidence tier was that **nobody we are not certain about enters an audience**.",
 "",
 "Those 267 people are not in the second tier — they are Confirmed, because their "
 "organisation is a university and `director` scores highly on its own. So the tier "
 "decision does not reach them. But the principle does, and applied here it would take "
 "them out: the share of this audience we can defend **from the person's own words "
 "would rise from 79.2% to 93.2%**, on an audience of 1,508 instead of 1,775.",
 "",
 "We are not making that change ourselves, because it is a definition and not a "
 "threshold — a Director at a university may genuinely be a head of faculty, and here, "
 "unlike the second tier, there is no second signal saying otherwise. **This is the one "
 "question we most need answered.**",
], fill="F1F6F4", accent=TEAL)
para(d,"One note for a publisher. `editor-in-chief`, **5,172 records**, was in this group "
       "until 21 October — an editorial role reading as institutional leadership. Now moved.")

h(d,"2a.  The hospital side of the same question",2)
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
h(d,"3.  Does the word \"research\" in a job title decide the audience?")
para(d,"This started as one question about statisticians. Running a check against the "
       "role library on 29 October showed it is a pattern, not a one-off, and the same "
       "answer settles all of it.")
box(d,"THE PATTERN, IN ONE PLACE",[
 "`biostatistician        7,723  ->  Researcher audience`",
 "`research statistician    299  ->  Researcher audience`",
 "`research economist     1,125  ->  Researcher audience`",
 "",
 "`statistician           7,094  ->  no audience at all`",
 "`medical statistician     969  ->  no audience at all`",
 "`economist              4,406  ->  no audience at all`",
 "",
 "**The only difference is whether the person typed the word \"research\".** Not what "
 "they do — what they typed.",
 "",
 "Market Intelligence's own role library lists each pair as ONE job. It describes a "
 "statistician as *\"a specialist who designs data collection and applies statistical "
 "methods to produce reliable evidence\"*, which is research work either way.",
])
para(d,"**20,000 records turn on this**, and it is one answer, not six.")
para(d,"**The argument for leaving it out.** The job title on its own does not say whether "
       "the person does research or provides statistical support to a research office. And "
       "the Researcher audience has **no subject check** — there is no second signal to "
       "catch a wrong one, unlike healthcare where the department has to agree. Moving "
       "7,094 records into an audience with no safety net is riskier than it looks.")
para(d,"**Our working answer: leave them out**, on the grounds of that missing safety net — "
       "but the inconsistency is real, it is now six titles rather than one, and we would "
       "rather you settled it.")

h(d,"3a.  The biggest single case of the same pattern",2)
para(d,"`research officer` carries **34,376 records** and sits in the group that feeds no "
       "audience. `research analyst` (5,894 records) is in the Researcher audience. The "
       "role library lists them as the same job.")
para(d,"This one is larger than the whole statistician family put together, and it moves "
       "in whichever direction you choose for question 4.")

# ---------------------------------------------------------------- 12 NEW
h(d,"4.  Does book-author consent cover a role-based campaign?  — BUILT, STILL WANTED IN WRITING")
para(d,"**This is now in the pipeline**, on Merve's instruction that it counts. "
       "`is_book_author_communications_opted_in` is the fourth consent basis and **26,654 "
       "people across the nine audiences hold it**. Reachable means any one of the four: "
       "marketing opt-in, advertising opt-in, legitimate interest, book-author consent.")
box(d,"WHAT WE STILL WANT FROM YOU",[
 "Somebody opted in to hear about **books**.",
 "",
 "Does that cover a **healthcare practitioner campaign**?",
 "",
 "The number is already built and already going out. This is a legal scope question, not "
 "a technical one, and we would like the answer recorded in writing the way the third "
 "basis was on 16 October — so that whoever audits a send can see the permission was "
 "considered rather than assumed.",
], fill="FDF8EF", accent=AMBER)
para(d,"**And a correction we owe you.** Every \"reachable\" figure we have given you "
       "before 10 November counted marketing opt-in ALONE — one basis out of four. It "
       "understated the audience by between 2.2 and 4.1 times. Lecturer was reported as "
       "109,323 and is **319,291**. Legitimate interest is the whole gap: 295,314 of "
       "Lecturer hold it against 109,323 with marketing consent. The pipeline has been "
       "right since 16 October; the reporting was reading a narrower column. Every number "
       "in this document is now the four-basis figure.")
para(d,"**One question we were going to ask you and are not, because we measured it "
       "instead.** The CDP carries three more consents — editor referral, editorial board "
       "members, webshop buyer. Each is permission for a different communication, so none "
       "of them is a basis for a role campaign without your word. They reach **251 people** "
       "that nothing else reaches, 0.03% of the reachable total. Ruling them in would not "
       "move anything, so we are not asking.")

# ---------------------------------------------------------------- MEDIUM BLOCK
h(d,"5.  Nine medium questions, each one line to change")

h(d,"5.1  Are psychologists healthcare professionals?  (~4,500 records)",2)
para(d,"All six psychologist titles currently match our **psychiatrist** example word and "
       "therefore sit in the clinical group. A psychologist is not a psychiatrist — no "
       "medical degree — but a clinical psychologist is a regulated healthcare "
       "professional in most countries, and an educational psychologist arguably is not.")
table(d,["Title","Records","Note"],
 [["`psicóloga` / `psicólogo`","2,658","bare \"psychologist\", could be academic"],
  ["`psicóloga clínica`","751","explicitly clinical"],
  ["`forensic psychologist`","390","clinical, in a legal setting"],
  ["`consultant clinical psychologist`","381","clinical"],
  ["`educational psychologist`","367","works in schools"]],
 widths=[2.2,0.8,2.6])
para(d,"**There is a third answer and it may be the right one: do not label them at all.** "
       "A rejected title is simply left unassigned, which already happens to any title we "
       "cannot place. The case for it: these people receive email. A clinical psychologist "
       "in a psychiatry department is Confirmed today and would receive a clinical "
       "campaign. If they are not healthcare professionals, a wrong inclusion costs more "
       "than a temporary exclusion. The case against: it removes them from everything, "
       "including a psychologist audience we might open later.")

h(d,"5.2  Four smaller versions of the same question  (2,743 records)",2)
table(d,["Question","Records","Today"],
 [["Are mental health support workers healthcare professionals?","326","Yes"],
  ["Are medical physicists and clinical scientists?","346","Yes"],
  ["Are genetic counsellors?","866","Yes"],
  ["Are counsellors?","1,205","Yes"]],
 widths=[3.5,0.8,0.9])
para(d,"All four are regulated health roles in some countries and support roles in others. "
       "Question 1 settles all of them at once.")

h(d,"5.3  Are visiting scholars and fellows teaching staff?  (81,749 records)",2)
para(d,"`visiting scholar` 60,561, `visiting fellow` 15,832, `visiting research scholar` "
       "5,356 — all currently counted as teaching staff because of the word *visiting*.")
para(d,"A visiting scholar may teach, or may only do research. We already moved "
       "`visiting scientist` (32,662 records) out without asking, because a scientist does "
       "not teach. These three are genuinely ambiguous and the word *scholar* leans academic.")

h(d,"5.4  Is an honorary professor active?  (6,651 records)",2)
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

h(d,"5.5  Is an uninformative title acceptable evidence?  (146,865 records)",2)
para(d,"`dr` carries **96,676 records** and `md` **50,189**. Together that is 9.1% of the "
       "clinical group. Neither says anything about a profession beyond holding a "
       "doctorate.")
para(d,"Both are resolved entirely by the department. A clinical department confirms them; "
       "without one they stay in the second tier — and since 11 November the second tier is "
       "never delivered, so **a bare `dr` with no clinical department is already excluded**. "
       "What is left of this question is narrower than it was: whether a `dr` WITH a "
       "clinical department is acceptable evidence on the department alone.")

h(d,"5.6  Should a past role still count?",2)
para(d,"Seven of the nine audiences count past employment. Somebody who was a researcher "
       "in 2010 and works in a bank today is still in the Researcher audience — on the "
       "reasoning that *researcher* is a profession you have rather than a post you hold.")
para(d,"**Head of faculty and Librarian are the exceptions** and count current posts only, "
       "because a former dean is not a dean. If you want the others to behave the same way "
       "it is one line per audience. **The size of that change has not been measured** and "
       "should be before it is made.")

# ---------------------------------------------------------------- LOW
h(d,"5.7  What the Students audience will and will not contain",2)
para(d,"The Students audience is being built now. One thing about its scope should be "
       "said before it ships, because it is not obvious and it is not a mistake.")
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
para(d,"Nothing needs changing. We are flagging it so that nobody later reports the "
       "Students audience as undercounting — it is working as decided.")

h(d,"5.8  Are veterinarians healthcare professionals?  (91+ people)",2)
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
para(d,"**Our working answer: no**, consistent with Question 1. Say the word and it is "
       "one line.")

h(d,"5.9  Is sport and exercise science a healthcare field?  (78+ people)",2)
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
para(d,"**Our working answer: keep the ones that say *medicine*, drop the rest.** That is "
       "the same test as Question 1 — the work, not the subject.")

h(d,"6.  Three longer-term questions")
h(d,"6.1  A title stays in ONE profession — DECIDED 30 October, please confirm",2)
para(d,"A title belongs to exactly one profession today. Some people write both jobs "
       "into one title, and we have to choose. **We decided on 30 October to leave them "
       "where they are, and we would like you to confirm it.**")
table(d,["What the person wrote","Records","Our decision"],
 [["Teaching AND research — *lecturer and researcher*, *teaching and research*, *assistant professor research*",
   "**~47,000**","**Stay in Lecturer**"],
  ["Teaching AND leadership — *professor and chair*, *professor and head*, *professor and dean*",
   "**~31,000**","**Stay in Lecturer**"]],
 widths=[3.6,0.9,1.9])
para(d,"**Why.** Letting one title carry two professions is a change to how the system is "
       "built, not a setting. 78,000 records is not enough to justify it, and in both "
       "cases Lecturer is a defensible home: these people do teach.")
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
h(d,"6.1a  And one part of it is NOT settled",2)
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
para(d,"**Our recommendation is Head of Faculty**, because Lecturer is large enough not "
       "to notice and Head of Faculty is small, precise and currently missing people "
       "whose title literally says they head something. But the question is which "
       "audience you would rather reach them in.")

h(d,"6.2  Two deliberate exclusions from Librarian",2)
para(d,"**Archivists are not included** — the word pulled in archaeologists, glaciologists "
       "and clerks, and archivists are a separate call from the one you made. "
       "**\"Information specialist\" is not included** — it pulled in every IT job in the "
       "data. Either can be added as one line, as a decision rather than a guess.")
h(d,"6.3  Should Researcher split into early-career and senior?  — WITHDRAWN",2)
para(d,"**Merve closed this on 4 November: Researcher ships as one audience and we are not "
       "asking.** Nothing is needed from you. It is left on the page only so that nobody "
       "re-opens it on seeing that two research groups already exist in our dictionary.")
para(d,"Why it was closed rather than deferred. The split would be made entirely from "
       "job-title words, and that is fragile in a way that cannot be patched: bare "
       "`researcher` counts as early career while bare `scientist` counts as senior, so a "
       "thirty-year veteran who typed \"researcher\" is classified as early career and the "
       "person beside them who typed \"scientist\" is senior. If seniority is ever wanted "
       "the route is **dates** — career length is already in the data and does not depend "
       "on what someone called their job.")

# ---------------------------------------------------------------- DECIDED
h(d,"7.  Already decided — recorded so nobody re-opens them")
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
  ["Are school teachers in the Lecturer audience?",
   "**Not asking.** Measured at 0.2% of the group — too small to be worth a decision.","21 Oct"],
  ["Should we build audiences for students and support staff?",
   "**Students yes, support staff no.** Students is being built now.","21 and 23 Oct"],
  ["Is reachability any one of the consent bases, or all of them?",
   "**Any one.** A third basis was added on your instruction.","16 Oct"],
  ["Should Head of faculty include hospital-based leaders? (~2,000 people)",
   "**No.** University heads only. Small and certain beats large and arguable.","29 Oct"],
  ["Should a title that names two jobs count as both? (78,000 records)",
   "**No.** They stay in Lecturer. See 6.1 — please confirm.","30 Oct"],
  ["Should Researcher split into early-career and senior?",
   "**No, and withdrawn.** One Researcher audience. See 6.3.","4 Nov"],
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
h(d,"8.  What we need from this meeting")
table(d,["Priority","Question","Why it cannot wait"],
 [["1","Is healthcare about the work or the subject? (Q1)",
   "It settles five questions at once, it is priced on both sides, and the line today "
   "is inconsistent"],
  ["2","Which leadership titles are a head of faculty? (Q2)",
   "15% of that audience, and the 11 November principle says those 267 people should "
   "leave — we want your word before removing them"],
  ["3","Does book-author consent cover role campaigns? (Q4)",
   "Built and already going out; we want the permission recorded in writing"],
  ["4","One rule for *professor and director*, all six spellings (Q6.1a)",
   "68,000 records are split today by nothing but word order and a separator"],
  ["5","Everything else","One line each, any time"]],
 widths=[0.65,2.6,3.0], size=9)
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
