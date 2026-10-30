# -*- coding: utf-8 -*-
import sys, os
SP = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, SP)
from docx_lib import *
from docx.shared import Pt, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH as AL
F = os.path.join(SP, "fig")
d = doc_new()

p=d.add_paragraph(); p.paragraph_format.space_after=Pt(2)
r=p.add_run("ORCID ROLE ENRICHMENT"); r.bold=True; r.font.size=Pt(9.5)
r.font.color.rgb=PLUM; r.font.name=SANS
p=d.add_paragraph(); p.paragraph_format.space_after=Pt(4)
r=p.add_run("Questions for Marketing"); r.bold=True; r.font.size=Pt(22)
r.font.color.rgb=INK; r.font.name=SANS
para(d,"Fifteen open decisions  ·  updated 29 October 2026  ·  Analytics Engineering",
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
 [["1","Switch on the second confidence tier?","718,607 people","Only the top tier ships","**High**"],
  ["2","Are biomedical researchers healthcare professionals?","15,588 people","No","**High**"],
  ["3","Is \"healthcare professional\" about the work or the subject?","settles 5 others","Work (treats patients)","**High**"],
  ["4","Which leadership titles are a head of faculty?","226,210 records","Keep ambiguous ones in. **Hospitals now excluded**","**High**"],
  ["5","Does the word \"research\" in a title decide the audience?","~55,000 records","No — **NEW**","**High**"],
  ["6","Are psychologists healthcare professionals?","~4,500 records","Yes, currently in","Medium"],
  ["7","Four smaller versions of the same question","2,743 records","Yes, currently in","Medium"],
  ["8","Are visiting scholars and fellows teaching staff?","81,749 records","Yes, currently in","Medium"],
  ["9","Is an honorary professor active?","6,651 records","Yes, currently in","Medium"],
  ["10","Is an uninformative title (dr, md) acceptable evidence?","146,865 records","Yes, if the department agrees","Medium"],
  ["11","Should a past role still count?","not measured","Yes, for seven of nine","Medium"],
  ["12","Does book-author consent cover a role campaign?","NEW","Assumed yes","**High**"],
  ["13","Should a job title be allowed in two professions?","463,603 records","No (design change)","**High** — now externally evidenced"],
  ["14","Two deliberate exclusions from Librarian","small","Both excluded","Low"],
  ["15","Should Researcher split into early and senior?","—","Not now","Low"]],
 widths=[0.3,2.55,1.05,1.55,0.6], size=8.5)

# ---------------------------------------------------------------- 1
h(d,"1.  Switch on the second confidence tier?")
para(d,"For every person we score the evidence. Strong evidence gets **Confirmed**. "
       "Evidence that points one way without being complete gets **Probable**. Today only "
       "Confirmed is delivered.")
box(d,"WHAT PROBABLE LOOKS LIKE",[
 "Somebody whose department is **Paediatrics** but whose job title is "
 "**Assistant Professor**.",
 "",
 "The department says clinical. The title says teaching. Which is right? Probably both — "
 "most medical school staff also see patients. So we mark them Probable. Not wrong. "
 "Unresolved.",
])
fig(d,f"{F}/probable.png",6.4,"What switching on the second tier would add, per audience.")
para(d,"**The answer is different for every audience.** Healthcare nearly doubles. "
       "Lecturer and Researcher gain almost nothing.")
box(d,"IT SOUNDS RISKIER THAN IT IS",[
 "Switching Probable on does not mostly bring in new people. It mostly adds a **second "
 "label** to people we already hold.",
 "",
 "That Assistant Professor is already in our list as a Lecturer. Switching this on also "
 "marks them as Healthcare. The unique total rises only **6.7%** while Healthcare nearly "
 "doubles.",
 "",
 "So this is not about emailing 87% more strangers. It is about being able to segment "
 "people we already have.",
])
para(d,"**Our recommendation:** switch it on for Healthcare, Pharmacist and Head of "
       "faculty. Leave it off for Lecturer and Researcher, where it gives nothing.")
para(d,"**One precondition for healthcare.** The word *consultant* means a hospital "
       "specialist in the UK, Ireland and much of the Commonwealth, and a business adviser "
       "everywhere else. We can see this in the data: the share of consultants with a "
       "clinical department is 0.88 in Qatar and 0.68 in Britain, against 0.20 in the "
       "United States and 0.03 in Peru. About **1,613 people** in low-share countries are "
       "held in Probable on a consultant title alone. A country rule should land before "
       "Probable is switched on for healthcare.")

# ---------------------------------------------------------------- 2+3
h(d,"2.  One question settles five of the others")
para(d,"Questions 2, 5, 6 and 7 are the same question asked about different jobs. Answer "
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

# ---------------------------------------------------------------- 4
h(d,"3.  Which leadership titles count as a head of faculty?")
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
para(d,"One note for a publisher. `editor-in-chief`, **5,172 records**, was in this group "
       "until 21 October — an editorial role reading as institutional leadership. Now moved.")

h(d,"3a.  NEW — the hospital side of the same question",2)
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
h(d,"4.  NEW — Does the word \"research\" in a job title decide the audience?")
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

h(d,"4a.  The biggest single case of the same pattern",2)
para(d,"`research officer` carries **34,376 records** and sits in the group that feeds no "
       "audience. `research analyst` (5,894 records) is in the Researcher audience. The "
       "role library lists them as the same job.")
para(d,"This one is larger than the whole statistician family put together, and it moves "
       "in whichever direction you choose for question 4.")

# ---------------------------------------------------------------- 12 NEW
h(d,"5.  NEW — Does book-author consent cover a role-based campaign?")
para(d,"We are about to add a fourth consent basis, `is_book_author_communications_opted_in`, "
       "to the definition of \"reachable\". Anyone holding any one of the four bases counts.")
box(d,"THE QUESTION",[
 "Somebody opted in to hear about **books**.",
 "",
 "Does that cover a **healthcare practitioner campaign**?",
 "",
 "This is a legal scope question, not a technical one. \"Reachable\" is the number that "
 "goes to Braze, and the basis has to match the message being sent. We added the third "
 "basis on 16 October on your instruction; we would like the fourth recorded the same way, "
 "in writing.",
], fill="FDF8EF", accent=AMBER)
para(d,"**A measurement worth doing first.** The existing legitimate-interest basis is "
       "author-based, and so is this one. They may be largely the same people. Librarians "
       "are reachable at 54% against 70–78% everywhere else for exactly this reason — they "
       "publish less. We would measure the overlap before promising a number.")

# ---------------------------------------------------------------- MEDIUM BLOCK
h(d,"6.  Six medium questions, each one line to change")

h(d,"6.1  Are psychologists healthcare professionals?  (~4,500 records)",2)
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

h(d,"6.2  Four smaller versions of the same question  (2,743 records)",2)
table(d,["Question","Records","Today"],
 [["Are mental health support workers healthcare professionals?","326","Yes"],
  ["Are medical physicists and clinical scientists?","346","Yes"],
  ["Are genetic counsellors?","866","Yes"],
  ["Are counsellors?","1,205","Yes"]],
 widths=[3.5,0.8,0.9])
para(d,"All four are regulated health roles in some countries and support roles in others. "
       "Question 2 settles all of them at once.")

h(d,"6.3  Are visiting scholars and fellows teaching staff?  (81,749 records)",2)
para(d,"`visiting scholar` 60,561, `visiting fellow` 15,832, `visiting research scholar` "
       "5,356 — all currently counted as teaching staff because of the word *visiting*.")
para(d,"A visiting scholar may teach, or may only do research. We already moved "
       "`visiting scientist` (32,662 records) out without asking, because a scientist does "
       "not teach. These three are genuinely ambiguous and the word *scholar* leans academic.")

h(d,"6.4  Is an honorary professor active?  (6,651 records)",2)
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

h(d,"6.5  Is an uninformative title acceptable evidence?  (146,865 records)",2)
para(d,"`dr` carries **96,676 records** and `md` **50,189**. Together that is 9.1% of the "
       "clinical group. Neither says anything about a profession beyond holding a "
       "doctorate.")
para(d,"Both are resolved entirely by the department. A clinical department confirms them; "
       "without one they stay in the second tier. The question is whether that is "
       "acceptable, or whether a title carrying no occupational information should be "
       "excluded outright.")

h(d,"6.6  Should a past role still count?",2)
para(d,"Seven of the nine audiences count past employment. Somebody who was a researcher "
       "in 2010 and works in a bank today is still in the Researcher audience — on the "
       "reasoning that *researcher* is a profession you have rather than a post you hold.")
para(d,"**Head of faculty and Librarian are the exceptions** and count current posts only, "
       "because a former dean is not a dean. If you want the others to behave the same way "
       "it is one line per audience. **The size of that change has not been measured** and "
       "should be before it is made.")

# ---------------------------------------------------------------- LOW
h(d,"6.7  NEW — What the Students audience will and will not contain",2)
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

h(d,"7.  Three longer-term questions")
h(d,"7.1  Should a job title be allowed in two professions?  (463,603 records)",2)
para(d,"A title belongs to exactly one profession today. That is a design choice and it "
       "has a measurable cost. **This moved from low priority to high on 30 October, "
       "when an outside source measured the cost for the first time.**")
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
h(d,"7.2  Two deliberate exclusions from Librarian",2)
para(d,"**Archivists are not included** — the word pulled in archaeologists, glaciologists "
       "and clerks, and archivists are a separate call from the one you made. "
       "**\"Information specialist\" is not included** — it pulled in every IT job in the "
       "data. Either can be added as one line, as a decision rather than a guess.")
h(d,"7.3  Should Researcher split into early-career and senior?",2)
para(d,"Possible, and it would be a settings change with no new code. **Not proposed now.** "
       "Recorded because the option exists.")
para(d,"One warning if it is ever wanted. The split is made entirely from job-title words, "
       "and that is fragile: bare `researcher` counts as early career while bare "
       "`scientist` counts as senior, so a thirty-year veteran who typed \"researcher\" is "
       "classified as early career. A better route is **dates** — career length is already "
       "in the data and does not depend on what someone called their job.")

# ---------------------------------------------------------------- DECIDED
h(d,"8.  Already decided — recorded so nobody re-opens them")
table(d,["Question","Decision","When"],
 [["Are teaching assistants in the Lecturer audience? (178,205 records)",
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
   "**No.** University heads only. Small and certain beats large and arguable.","29 Oct"]],
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
h(d,"9.  What we need from this meeting")
table(d,["Priority","Question","Why it cannot wait"],
 [["1","Is healthcare about the work or the subject? (Q2)",
   "It settles five questions at once and the line today is inconsistent"],
  ["2","Switch on the second tier, and for which audiences? (Q1)",
   "It is the single biggest change available and the answer differs per audience"],
  ["3","Does book-author consent cover role campaigns? (Q5)",
   "We are adding it this week and want it recorded in writing"],
  ["4","Which leadership titles are a head of faculty? (Q3)",
   "226,210 records, and the never-academic list is ready to apply"],
  ["5","Everything else","One line each, any time"]],
 widths=[0.65,2.6,3.0], size=9)
para(d,"**One thing we cannot give you, and will not invent.** There is no accuracy "
       "percentage for any of this. ORCID has no profession field, so there is no correct "
       "answer anywhere to compare against. What we have instead is that every decision is "
       "inspectable: name any person and we can show you the words they typed, what it "
       "matched, how close it was, and whether a human or the model decided. We are also "
       "now matching against survey answers, where people told us their own job title — "
       "that will be the first outside check this project has had.")

out=os.path.join(os.path.expanduser("~"),"Downloads","ORCID-Questions-for-Marketing.docx")
d.save(out); print("saved:",out,os.path.getsize(out),"bytes")
