**ORCID ROLE ENRICHMENT**

# Where the nine audiences stand, and what we need you to decide

13 November 2026 · Analytics Engineering · one page, then the calls

We read the job title, employer and department that researchers typed into their own ORCID record, and sort them into nine audiences. All nine are built and all nine have been measured. Nothing below is a forecast.

## The nine audiences today

| Audience | People | Right, of the decided | Where that comes from | Verdict |
|---|---|---|---|---|
| **Lecturer** | 399,884 | **98.7% ± 1.1** | 400 read one by one | Solid |
| **Researcher** | 321,824 | **99.0% ± 1.0** | 400 read one by one | Solid |
| Healthcare (broad) | 126,869 | 90.6% ± 3.0 | 400 read one by one | **Not weak — undefined.** Question 1 |
| Practitioner | 60,937 | 93.4% ± 2.6 | 400 read one by one | Good |
| Clinical researcher | 50,600 | 90.0% ± 3.1 | 400 read one by one | Good. Grows with question 1 |
| **Head of faculty** | 17,528 | **83.3% ± 4.4** | 400 read one by one | **The weak one.** Cause known |
| Clinical administrator | 6,865 | 94.9% ± 2.2 | 400 read one by one | Good. Was 88.9% in October |
| Pharmacist | 2,245 | 95.7% ± 1.9 | 400 read one by one | Good. Was 81.8% in October |
| Librarian | 668 | 98.5% | all 692 read | Solid |

*Right, of the decided* leaves out the rows a reader marked **not sure**. Not sure means one of two things: a definition you have not settled yet, or a record that does not say enough to judge. It is never counted as correct.

> ### THE WHOLE PICTURE IN THREE LINES
>
> **Seven of the nine are at 93% or better**, and the two biggest are at 99%. These are safe to use today.
>
> **Head of Faculty is the one weak audience**, at 83.3%. The cause is not a bug: it is the only audience where the job title is the *only* evidence we have, so a vague title has nothing to contradict it. A third of its cases are titles like a bare *director* with no faculty word beside it.
>
> **Healthcare (broad) is not inaccurate — it is undefined.** It does what we built it to do; we just can no longer say in one sentence who is in it. That is question 1, and it is the only thing on this page that blocks us.

## What we need from you, biggest first

| | The call | How many people it moves | Urgency |
|---|---|---|---|
| 1 | **What should "Healthcare Professional (broad)" mean?** | 126,869 already in it, and up to 63,767 more arriving | **Blocks us** |
| 2 | Should doctoral researchers count as Students as well as Researchers? | 19,927 | Confirm only |
| 3 | Is a bare `dr` plus a clinical department enough to call someone clinical? | Large. Being re-counted — see the note | Medium |
| 4 | Are visiting scholars and visiting fellows teaching staff? | Large. Being re-counted | Medium |
| 5 | Should a job someone has left still count? | Affects seven of the nine audiences | Medium |
| 6 | Is an honorary professor still an active academic? | Being re-counted | Medium |
| 7 | Do statisticians and economists belong in an audience at all? | Being re-counted. In no audience today | Medium |
| 8 | Are veterinarians healthcare professionals? | 91 | Low |
| 9 | Is sport and exercise science a healthcare field? | 78 | Low |
| 10 | Two titles we chose to keep out of Librarian | Small | Low |

Every one of these is reversible in one line of configuration. Changing an answer later is cheap — **leaving it open is what costs us**, because until it is settled we cannot tell you what an audience means.

## 1. What should "Healthcare Professional (broad)" mean?

You told us on 11 November that biomedical researchers are healthcare professionals, and we have implemented it. It works. But it has a consequence worth one minute of your time.

Biomedical researchers enter *Clinical researcher*, and because that audience rolls up into *Healthcare Professional (broad)*, they enter the broad one too. Up to **63,767 people** who have never seen a patient will sit in an audience called *Healthcare Professional*. Nothing is broken — the name is simply no longer describing the audience.

**Two ways out, and we recommend the first.** Rename it, because *Practitioner* already is the clinical audience at 46,450 reachable people and nobody needs two of those. Or stop rolling researchers up into it, which keeps the name and shrinks the audience.

**What we need is one sentence from you:** who is in Healthcare Professional (broad), and what should it be called on a campaign brief.

## 2. Should doctoral researchers count as Students as well as Researchers?

About **19,927 people** write a title like *doctoral researcher* or *PhD researcher*. They are doing research and they are students, and until now a title could only mean one job, so they were researchers and the Students audience did not contain them.

We have now implemented the rule you gave us — a title that names two jobs counts as both — so they can be in both. **This is a confirmation, not an open question**, unless you want them out of Students.

## 3. Is a bare `dr` plus a clinical department enough?

A record that says only *Dr* in an oncology department tells us the person is medically qualified and works in a clinical setting, but not what they do. We currently accept it as clinical evidence. Saying no makes the healthcare audiences smaller and more certain; saying yes keeps them as they are.

## The remaining seven, one line each

- **4 Visiting scholars and fellows** — in Lecturer today. They teach, but the post is temporary and often unpaid.
- **5 Past jobs** — seven of the nine audiences count a job someone has left. A researcher in 2010 who runs a bakery today is still in Researcher. Head of Faculty and Librarian already use current posts only.
- **6 Honorary professors** — in Lecturer today. The title is usually a mark of respect rather than a job.
- **7 Statisticians and economists** — in no audience at all today. Their titles name a discipline, not a job we recognise. A third of the family is already in Lecturer correctly, as *professor of biostatistics*.
- **8 Veterinarians** — 91 people, in the healthcare audiences today by accident rather than by decision.
- **9 Sport and exercise science** — 78 people, same situation.
- **10 Librarian exclusions** — we keep out archivists, because the word also collected archaeologists and glaciologists, and *information specialist*, because it collected every IT job in the data.

> ### WHY FOUR SIZES SAY "BEING RE-COUNTED"
>
> Earlier versions of this document sized some questions in *records* rather than people. On 11 November we found a defect in the column those counts came from: it froze the first time each job title was seen, so it had been running 14 to 30 times high.
>
> It is fixed, and it never touched the classification itself — no audience changed, and no decision was made on a wrong basis. **Every number on this page is a people figure, counted directly, and unaffected.** The four record-based sizes come back next week, and none of them is question 1.
