# Presenter notes

One block per heading in the walkthrough. The boxed text is what to say — say it in your own words, it is written to be spoken, not read out. The notes underneath are the things worth remembering if you are asked.

1. **Open** — the four numbers
2. **Where we started** — one audience, English only
3. **The method** — we classify words, not people
4. **Two axes** — title and department
5. **Example words** — the multilingual table
6. **Why a score** — the consultant example *(the strongest part)*
7. **Nine audiences** — what can be pulled today
8. **Coverage** — the finding to act on
9. **What went wrong** — four problems
10. **Limits** — no accuracy figure, and why
11. **Next** — three decisions and the unused signal

About 15 minutes at a normal pace. If you only have eight, keep 1, 3, 6, 9 and 11.

1

## Open with the problem

90 sec

Let me start with the problem rather than the solution.

ORCID is where researchers write their own employment history — their job title, their organisation, their department. We have 1.8 million of those profiles. The problem is that all of it is free text. People type whatever they want. Some write "Professor". Some write "Resident Physician". Some write only "Dr". So we had the data, and we could not use it to build an audience.

What I built reads that text and decides what profession each person has.

Four numbers. We now know the profession of *673,553 people*. Of those, *501,522 are reachable* — and that means two things are true at the same time: they exist in our CDP, and they are opted in. If only one is true I do not count them.

Nine audiences, where before there was one. And 1.6 professions per person, which sounds small but matters — one person can have more than one, and it is the thing people get wrong when they read the audience table later.

if asked

"Reachable" is the only number worth planning with. The other three describe what we know; that one describes who we can contact.

2

## Where we started

60 sec · cuttable

Before this project there was exactly one audience: healthcare professional.

It worked like this. Someone wrote a list of English words — physician, nurse, surgeon. If a job title contained one of those words, the person counted. That is a reasonable way to start, and it has two hard limits. It covers one profession, and it only works in English.

And I can show you where it went wrong. I compared the two on healthcare. Of the people the old rules call healthcare professionals and I do not, about *53,000 work in engineering, earth science, mathematics or humanities departments*. They were picked up for *where* they worked — a medical school, a hospital — not for what they do.

careful

Do not oversell this. The old system was never measured either, and I cannot tell you how many of *my* extra people are wrong. The honest difference is that I know which part of mine is weak and I will tell you.

3

## The method

2 min

Here is the one idea I would like you to take away from this.

We never classify people. We classify the *vocabulary*. There are 310,299 different job titles in ORCID and 450,307 different department names. We classify those once, and store the answers. After that, giving 1.8 million people their profession is an ordinary database join.

That is why this does not get expensive as it grows. The AI thinking happens once, over the words. The daily refresh is a normal database query and costs nothing extra.

Four steps. An AI model turns each job title into a list of numbers that stand for its meaning. We compare it against example words we wrote by hand. We score the evidence from the title, the organisation and the department together. And then we label it — confirmed, or probable. Only confirmed people go out today.

why it matters

This is the answer to "what does the AI cost us". A manager usually wants that number, and the answer is that it does not scale with the number of people — only with how many new words appear.

4

## Two axes

45 sec · cuttable

One design choice worth a moment. A job title tells you the *kind* of work. A department tells you the *subject*. Those are two different questions, so I answer them separately and combine the answers afterwards.

And I measured that rather than assuming it. If you try to read the research field out of the job title, *73.5% of records tell you nothing* — "professor" has no field. Read it from the department instead and only 1.6% are unusable.

5

## Why we need example words

90 sec

Now, why example words at all.

I cannot write a rule for 310,299 job titles. And nobody can list every way the world says "nurse". So I do the opposite. I write a small number of clear examples — 143 job titles and 162 research fields — and the model finds everything that *means the same thing*.

This is the part that makes language stop being a problem, and I want to show you it working in the real data rather than claim it.

Look at the table. Every example word on the right is *English*. I never translated anything. And the titles reaching them were typed in Portuguese, Turkish, German, Spanish and Russian. The number is how close the meaning is.

The old keyword rules could not see a single one of these.

point at

директор библиотеки matching library director at 0.83 is the most convincing line on the page. Nothing about it is spelled like English.

6

## Why a score, not a yes or no

2 min · the strongest part

This is my favourite example, and it explains why the system scores evidence instead of just matching words.

In Britain, a hospital specialist is called a *consultant*. Almost everywhere else, a consultant is a business adviser. Same word. Completely different job. No list of words can tell them apart.

So look at the two sides. Same job title both times. On the left, the department is cardiology — the score comes to 1.00, clearly confirmed. On the right, the department is a business school — the score is exactly 0.60, which is the line.

And the arithmetic is doing real work here. To be confirmed on a job title alone, with no department agreeing, the title has to match an example word *exactly* and the organisation has to be fully identified. Anything less cannot reach 0.60. So "business consultant", which the model scores at 0.84, can *never* get into the healthcare audience. Only 1,008 people out of 126,270 are in there on a title alone.

I also checked this by country. Where consultant means a hospital doctor — Britain, Qatar, Singapore — 68 to 88% of them also name a clinical department. In the United States it is 20%. In Brazil, 8%. The department was already separating them for us.

this is the one

If your manager remembers one slide, make it this one. It shows a real-world problem, a design that handles it, and a number proving the design works — in about ninety seconds.

7

## The nine audiences

90 sec

This is what marketing can pull today. Every line is an audience they can select for a campaign.

Each one has its own rule about what evidence it needs — some accept a job title on its own, some need the title and the field to agree — and its own threshold. None of those were guessed. Each was set after measuring what it let in and what it kept out.

Two warnings, because both are easy to get wrong. The four indented rows sit *inside* healthcare professional, not next to it — if you select the parent you already have all four. And the numbers *cannot be added*. People hold 1.6 professions on average, so a professor who publishes research appears as both a Lecturer and a Researcher. If you need one total, use 501,522 people.

if asked

Librarian is only 666 people and that is expected — marketing asked for it because a publisher sells to libraries, not because it would be large. It is also the one audience where every single assignment is exact rather than scored.

8

## Where the people go

60 sec

This is the finding I would actually act on.

Read the third bar. We can name a profession for 673,553 people out of 1.8 million. That leaves *1,139,149 people with no audience at all*.

And most of that is a choice, not a failure. There is no audience yet for students — that is 1.9 million job records — or for technical and support staff, another 1.4 million.

Compare that with what we lose to CDP membership and opt-in together: 172,000. So the ceiling moved. It used to be permission. It is now coverage. The place to grow is a new audience, not more consent.

9

## What went wrong

2.5 min

I want to show you four problems, because none of them failed loudly. Each one looked fine and produced wrong numbers, and each was found by measuring something rather than by noticing it.

*One.* Veterinarians were being called dentists. 2,684 records. There was no example word for "veterinarian", so the model picked the closest one it had. Same for anaesthetists, optometrists and midwives. The method was fine; the vocabulary I gave it was incomplete. I added 31 missing professions.

*Two.* For the librarian audience I wrote the word in eleven languages, expecting better coverage. It got much worse. In Spanish and Portuguese a short job word sits in a thin part of the model's space, so "bibliotecario" attracted anything that merely *looked* similar — biólogo, catedrática, nutricionista. Nearly seven records in ten were wrong. I deleted all eleven, and the real foreign librarians stayed, because they were reaching the English word on their own.

*Three*, and this is the one that bothers me most. Deleting an example word did nothing at all. The table only ever added rows, so anything I removed stayed live. And it had already been misdiagnosed once: corporate job titles kept arriving in the leadership group after we removed "chief executive officer" and "founder", and the note in the code concluded that the model simply generalises to them. It does not. The deletion had never happened.

*Four.* Adding "pathologist" as an example pulled in every science that ends the same way — epidemiologist, toxicologist, hydrologist. 7,779 records. I moved them back by hand and kept the example word, because real pathologists need it. What I learned is that what makes an example word dangerous is not how it is spelled, it is how crowded its neighbourhood is.

And here is the result on the hardest group. The share of clinical job titles the model was unsure about went from *40.6% to 34.3%* in one day.

why say this

It is tempting to skip this section. Do not. It is the part that shows the review is working — a manager who hears only good news has no way to judge the rest. Problem three in particular shows something being *re-opened and corrected*, which is harder to fake than a clean result.

10

## What we cannot claim

90 sec

I want to be straight about the limits, and the first one is the important one.

*There is no accuracy percentage, and there never will be one.* ORCID has no "profession" field. The job title is free text the researcher typed, so there is no correct answer anywhere for me to compare mine against. And the old system is not a reference either — I just showed you 53,000 cases it got wrong. If I gave you a number like "94% accurate", I would be inventing it, and I am not going to do that.

What I do instead is make every decision inspectable. For any person, I can tell you which words they typed, which example word it matched, how close the match was, and whether a human or the model decided. *96 decisions are pinned by hand* and always beat the model. And ten automated tests guard the specific ways this system has failed before — I wrote them from this project's own history, not from a checklist.

Two smaller limits. Reachable means opted in, not deliverable — the CDP holds no bounce data, so I cannot promise an address works. And seven of the nine audiences count past jobs, not just current ones, because researcher is a profession you have rather than a post you hold.

if pushed

If someone insists on a percentage, the answer is: I can give you one, but I would have to invent the ground truth to measure it against, and then the number would be measuring my invention. What I can give you instead is every case you want to inspect.

11

## Next

60 sec

Three questions are waiting on marketing, and I have deliberately not answered them, because each is a definition rather than a technical problem.

Should the second confidence tier be switched on — it nearly doubles the healthcare audience and adds almost nothing to the others. Are biomedical researchers healthcare professionals — that turns on 15,588 people. Is a "Director" at a university a head of faculty — about 2,900.

The biggest technical opportunity is something we already hold and have never touched. ORCID also records each person's *degrees*. A degree is far more standard than a job title — MD, MBBS, BDS mean one thing worldwide. That is exactly what would settle the *146,865 records* where the job title is just "dr" or "md" and tells us nothing at all.

And the biggest audience opportunity is students: 1.9 million job records already classified, feeding nothing. For a publisher, that is probably the most valuable group we are currently ignoring.

## If they ask

### "Is this using AI? What does it cost us?"

Yes, for one step — turning job titles into meaning so they can be compared. But that runs once over the vocabulary, 310,299 titles, not once per person. The result is stored. Every refresh after that is a normal database query and costs nothing extra.

### "Can we trust it?"

You can inspect it, which I think is better. For any person I can show the words they typed, what it matched, how close, and who decided. What I cannot give you is a single accuracy number, and I would rather say that than invent one.

### "Why only half a million people?"

That is individual people, not campaign size — a Lecturer campaign reaches 309,206 on its own. And the limit is no longer permission. 1.1 million people get no audience because we have not built one for students or support staff yet. That is where the growth is.

### "How do you handle someone with twenty jobs in their history?"

All of them are considered, and each is tested separately against each audience. If any one of their jobs qualifies them, they are in. For the evidence we show, we pick their most recent job *of that type* — so for Lecturer you see their newest teaching post and for Researcher their newest research post.

### "Why is healthcare still the weakest group?"

Clinical job titles are the least standardised vocabulary in the data. Resident, Registrar, Facharzt, Interno and Senior House Officer all overlap in meaning and share no common word. Academic titles are nearly the same everywhere — Professor, Associate Professor, Lecturer — which is why that group sits at 7% unsure and clinical sits at 34%.

### "What happens if you are not available?"

Every decision is written down in the repository with the reason and the number behind it, not just the change. The 96 human decisions each carry a note explaining why. There are ten tests covering the ways it has broken before, and a register of every open question with its size. Someone picking it up reads the register, not me.

### "Could we use this method on anything else?"

Yes — nothing about it is specific to ORCID or to job titles. It works on any free-text vocabulary where you need consistent categories and the values are written in many languages. Department names already go through the same machinery as a second axis.

### "What is the biggest risk?"

That a mistake is silent. Three of the four problems I showed you produced wrong numbers without failing, and one had been misdiagnosed before. That is why the tests are written from this project's own failures rather than from general good practice — they guard the things that have actually gone wrong here.

Figures from the build of 20 October 2026. Pair these notes with the walkthrough page — the headings match in order.