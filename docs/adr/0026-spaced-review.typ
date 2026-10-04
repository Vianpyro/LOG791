#import "../template.typ": adr, arch, course, ext, validation

== ADR-0026 — Spaced review activity mode <adr-0026>

*Status:* proposed, after load validation (like tier Q2). Applies #adr("0014"). \
*See also:* #adr("0012"), #adr("0015"), #adr("0019"), #adr("0022"), #adr("0027").

=== Context

The practice mode serves an item when the student opens it; nothing brings back what the student has forgotten. Many items of #course("LOG200") and #course("LOG121") check knowledge rather than programming (single choice, short answer, matching, predicting an output), and they are written once per course bank (#adr("0015")). Flashcard tools such as #ext("anki")[Anki] schedule each card from the student's past answers so it comes back just before it would be forgotten. Their scheduler, #ext("fsrs")[FSRS], is open source and published as a Rust crate, the one Anki itself uses.

=== Options considered

- *No scheduling*: students pick practice items themselves, as today, and the forgotten ones never come back.
- *A scheduler written in the project* (Leitner boxes, SM-2): a few lines, but its intervals are guessed and tuned by us.
- *FSRS through the `fsrs` crate*: intervals fitted on millions of real reviews, maintained outside the project.

=== Decision

*Mode.* Review is an activity mode (#adr("0014")): full feedback, no Safe Exam Browser, no grade sent to Moodle, live base priority 300, between practice and re-judging (#adr("0022")).

*Eligible items.* Only items rated at once: the families graded instantly and deterministically (Choice, Key match, Arrangement and Derived key, #adr("0015")), and self-assessed Manual items (#adr("0027")). Judged code and Composite items are not reviewed: a sandbox run per review costs judge time for a weak memory signal. Manual items graded by the teaching team are not reviewed either, since their grade comes later.

*Rating.* When the item has a grader, the rating comes from it, not from the student: a wrong answer is _Again_, a right one is _Good_. FSRS loses a little precision without _Hard_ and _Easy_, but the review stays an observed answer. A self-assessed item is rated by the student, with the four levels, after the reveal (#adr("0027")), as in Anki. Rewards never depend on the rating (#adr("0027")).

*State.* One row per (student, offering, item): stability, difficulty, due date, lapses, last review. It is computed by `fsrs` with its default parameters. Fitting the parameters to an offering is postponed until an offering has enough reviews to justify it. The row is updated from the verdict row, once per verdict id, so a replayed event never counts a review twice. The judge stays unaware of the mode.

*Session.* The instructor chooses the pools (a tag or a category of the bank) open to review. A session serves the due items of those pools, then new items up to a daily cap set by the offering. A calculated item draws a new variant on each review: its seed includes the review count, so the student recalls the method, not the number. The exam seed of #adr("0015") is not used.

*Leeches.* An item that a student has failed at least _n_ times is a leech for that student. The teaching view of the dashboard (#adr("0019")) lists the items of an offering by share of students for whom they are leeches: an unclear stem or a wrong key shows up there first. It is a read-only query.

*Typed answer.* In practice and review, Key match feedback shows the difference between the answer and the key. Never in assignment or exam: the answer-shape rule of #adr("0015") still applies there.

*Not adopted from Anki.* Streaks, heatmaps and daily counters (gamification is excluded by the project plan), deck import (`.apkg`, to be handled with #arch("open-questions")[open question 19] if a course asks for it), offline use and a card editor (content is published through releases, #adr("0005")).

=== Consequences

- One dependency in the API, `fsrs`, and one table. No new process and no change to the judge.
- Review state is personal data: it is purged with its offering (#adr("0012")) and never leaves the platform.
- Review jobs go through the queue like any non-code grading (#adr("0015")); their base priority keeps them behind assignments and exams.
- A course that wants no review simply opens no pool to it.

#validation(id: "V-0026")[
  A student reviews a pool: an item answered wrongly comes back before an item answered correctly, a self-assessed item rated _Again_ before one rated _Good_, and the due dates match those `fsrs` computes for the same history. Replaying a verdict event leaves the state unchanged. A calculated item shows two different variants on two reviews. The leech list of LOG200 shows no LOG121 item. Purging an offering deletes its review state. Under exam load, no exam job waits behind a review job.
]
