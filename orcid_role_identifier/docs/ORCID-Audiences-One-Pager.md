**ORCID ROLE ENRICHMENT**

# Where the ten audiences stand, and what we need you to decide

13 November 2026 · Analytics Engineering · one page, then the calls

We read the job title, employer and department that researchers typed into their own ORCID record, and sort them into ten audiences. All ten are built and all ten have been measured. Nothing below is a forecast.

## The ten audiences today

| Audience | People | Right, of the decided | Where that comes from | Verdict |
|---|---|---|---|---|
| **Lecturer** | 423,668 | **98.7% ± 1.1** | 400 read one by one | Solid |
| **Researcher** | 340,705 | **99.0% ± 1.0** | 400 read one by one | Solid |
| Healthcare (broad) | 181,295 | 90.6% ± 3.0 | 400 read one by one | **Not weak — undefined.** Question 1 |
| Clinical researcher | 108,805 | 90.0% ± 3.1 | 400 read one by one | Good. Grew with question 1 |
| **Students** | 105,658 | **98.7% ± 1.3** | 400 read one by one | **New.** Solid |
| Practitioner | 62,141 | 93.4% ± 2.6 | 400 read one by one | Good |
| Head of faculty | 17,218 | 83.3% ± 4.4 | 400 read one by one | **Parked** — not being delivered |
| Clinical administrator | 8,258 | 94.9% ± 2.2 | 400 read one by one | Good. Was 88.9% in October |
| Pharmacist | 2,064 | 95.7% ± 1.9 | 400 read one by one | Good. Was 81.8% in October |
| Librarian | 700 | 98.5% | all 700 read | Solid |

*Right, of the decided* leaves out the rows a reader marked **not sure**. Not sure means one of two things: a definition you have not settled yet, or a record that does not say enough to judge. It is never counted as correct.

> ### THE WHOLE PICTURE IN THREE LINES
>
> **Seven of the ten are at 93% or better**, and the two biggest are at 99%. These are safe to use today. The People column is a 12 November count and grows a little every week, because ORCID is added to continuously.
>
> **Head of Faculty is parked and is not being delivered.** It is the one weak audience at 83.3%, and the cause is not a bug: it is the only audience where the job title is the *only* evidence we have, so a vague title has nothing to contradict it. We are waiting on a second source before we offer it.
>
> **Healthcare (broad) is not inaccurate — it is undefined.** It does what we built it to do; we just can no longer say in one sentence who is in it. That is question 1, and it is the only thing on this page that blocks us.

## What we need from you, biggest first

| | The call | How many people it moves | Urgency |
|---|---|---|---|
| 1 | **What should "Healthcare Professional (broad)" mean?** | 181,295 in it — 54,426 of them arrived this month | **Blocks us** |
| 2 | Is a bare `dr` plus a clinical department enough to call someone clinical? | Large | Medium |
| 3 | Are visiting scholars and visiting fellows teaching staff? | Large | Medium |
| 4 | Should a job someone has left still count? | Affects seven of the ten audiences | Medium |
| 5 | Is an honorary professor still an active academic? | Medium size | Medium |
| 6 | Does Students mean doctoral candidates, or every student? | Master's and undergraduate students are in it today | Medium |
| 7 | Are veterinarians healthcare professionals? | 91 | Low |
| 8 | Is sport and exercise science a healthcare field? | 78 | Low |
| 9 | Two titles we chose to keep out of Librarian | Small | Low |

Every one of these is reversible in one line of configuration. Changing an answer later is cheap — **leaving it open is what costs us**, because until it is settled we cannot tell you what an audience means.

## 1. What should "Healthcare Professional (broad)" mean?

You told us on 11 November that biomedical researchers are healthcare professionals, and we have implemented it. It works. But it has a consequence worth one minute of your time.

Biomedical researchers enter *Clinical researcher*, and because that audience rolls up into *Healthcare Professional (broad)*, they enter the broad one too. It is built now, so this is a count and not an estimate: Clinical researcher went from 50,600 to **108,805** and the broad audience from 126,869 to **181,295**. So **54,426 people** who have never seen a patient joined an audience called *Healthcare Professional* this month. Nothing is broken — the name is simply no longer describing the audience.

**Two ways out, and we recommend the first.** Rename it, because *Practitioner* already is the clinical audience at 46,526 reachable people and nobody needs two of those. Or stop rolling researchers up into it, which keeps the name and shrinks the audience.

**What we need is one sentence from you:** who is in Healthcare Professional (broad), and what should it be called on a campaign brief.

## 2. Is a bare `dr` plus a clinical department enough?

A record that says only *Dr* in an oncology department tells us the person is medically qualified and works in a clinical setting, but not what they do. We currently accept it as clinical evidence. Saying no makes the healthcare audiences smaller and more certain; saying yes keeps them as they are.

## The remaining seven, one line each

- **3 Visiting scholars and fellows** — in Lecturer today. They teach, but the post is temporary and often unpaid.
- **4 Past jobs** — ORCID keeps a person's whole job history, and seven of the ten audiences accept any of it. A researcher in 2010 who runs a bakery today is still in Researcher. And a label is never replaced by a newer job, only added to: somebody who treated patients in 2020 and runs a clinical department in 2026 is in Practitioner **and** Clinical Administration. Head of Faculty, Librarian and Students are the three that already count current posts only. Whichever way you decide, one thing is worth knowing: the job title and employer we show you are the ones that put the person in the audience, so for anybody who is in on a past job they can be years out of date.
- **5 Honorary professors** — in Lecturer today. An honorary professor is not paid by the university and holds no post there: the title is given to them, not held by them. The trouble is that it covers two opposite people. A hospital consultant who treats patients full time is often made an honorary professor so they can supervise doctoral students — working, just not for the university. A professor who has retired is often kept on as one out of courtesy — not working at all. The record does not tell us which. Worth weighing: on 16 October you rejected `emeritus professor`, `retired professor` and `honorary researcher`, and `honorary professor` is the one nobody looked at.
- **6 What Students means** — two separate things here. **One: it is one bucket, not three.** PhD, master's and undergraduate students are all in it together, because we never split them — people wrote *PhD student*, *master student*, *undergraduate student* and all three count. If you want doctoral candidates only, tell us and we will narrow it; that is one line to change. **Two, and this one is a warning rather than a question: the employer has to be a university.** We test that on the employer, not on the person. Every organisation named in ORCID is looked up in ROR, a public register that gives each one a type, and Students accepts only the type *Education*. A research institute such as Max Planck comes back as *Facility* or *Funder*, and a teaching hospital as *Healthcare*, so a PhD student at either is **not** in the audience even when their job title says *PhD student* plainly. We never read the education section of someone's profile — their degrees play no part in this. That rule costs us 10,316 people, and it was confirmed on 11 November after we measured the bill.
- **7 Veterinarians** — 91 people, in the healthcare audiences today by accident rather than by decision.
- **8 Sport and exercise science** — 78 people, same situation.
- **9 Librarian exclusions** — we keep out archivists, because the word also collected archaeologists and glaciologists, and *information specialist*, because it collected every IT job in the data.

> ### TWO THINGS ABOUT THE NUMBERS ON THIS PAGE
>
> **Every figure here is a people figure, counted directly on 12 November.** Earlier versions sized some questions in *records*, from a column we found to be defective on 11 November — it froze the first time each job title was seen and had been running 14 to 30 times high. It is fixed, it never touched the classification, and no audience changed and no decision was taken on a wrong basis. The sizes on this page do not come from it.
>
> **Students was the newest audience and is now read like the rest** — 400 records, one by one, finished 13 November. It came out at 98.7%, third of the ten. Its one known soft spot is people who wrote only a qualification as their job title, such as *PhD* or *Master*: 6% of the sample, where we cannot tell from the record whether the person is studying for it or has held it for twenty years.
