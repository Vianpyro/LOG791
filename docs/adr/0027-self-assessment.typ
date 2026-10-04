#import "../template.typ": adr, arch, ext, validation

== ADR-0027 — Self-assessed activities <adr-0027>

*Status:* proposed. Applies #adr("0014"); extends #adr("0015"). \
*See also:* #adr("0005"), #adr("0019"), #adr("0023"), #adr("0026").

=== Context

Not every assignment is corrected by the teaching team: part of them is checked by the students themselves, against a reference answer. The platform does not cover this case. Manual items wait for a teaching assistant or an instructor (#adr("0015")), and an item has only two parts: a public one, shown before the attempt, and a private one, read by the judge only. A reference answer shown after the attempt fits in neither.

=== Options considered

- *Reference answer in the public part*: the student sees it before answering.
- *Reference answer outside the platform* (a PDF posted on Moodle after the deadline): the student leaves the platform, no self-assessment is recorded, and the item cannot be reviewed (#adr("0026")).
- *Who grades becomes part of the activity mode policy, and items gain a part revealed after the attempt.*

=== Decision

*Grader in the policy.* The activity mode policy (#adr("0014")) gains a `grading` field: `auto`, `staff`, `self` or `none`. It applies to items without an automatic grader; an item that has one keeps it in every mode, since an observed answer beats a self-assessment. An exam is always `auto` or `staff`: a release whose exam declares `self` or `none` is refused at publication.

*Revealed part.* An item gains a third part, `revealed`: reference answer, worked solution, rubric criteria. It is projected into the release in its own section (#arch("public-projection")[Public projection]) and read only through the single access gate (#arch("opening-over-time")[Opening over time]), never as a static file. The gate serves it to a student after that student's own submission of the item, or after the activity closes, as the policy says (`reveal: submission` or `close`). It goes through the statement renderers and the sanitizer like any text field (#adr("0016"), #adr("0023")). The reserved grader keys stay refused by negative enumeration in this section too (#adr("0005")): a key placed there by mistake stops publication.

*Self-rating.* Once the revealed part is shown, the student rates their submission. With a rubric, they tick the criteria met and the score is the sum of their weights. Without one, they pick one of the four levels used by review: _Again_, _Hard_, _Good_, _Easy_ (#adr("0026")). An empty submission cannot be rated. A new submission brings a new rating; earlier ones are kept.

*Records.* Every score carries its source: `auto`, `staff` or `self`. Self ratings are never added to graded scores. The teaching view of the dashboard (#adr("0019")) shows them apart, per item.

*Moodle.* Only an activity linked to a Moodle grade item sends anything (#arch("courses-and-roles")[Courses and roles]); most self-assessed activities will live in the platform alone. When linked, a self-assessed activity sends a completion without a score (#ext("ags")[AGS] allows a score message without `scoreGiven`), and a `none` activity sends nothing.

*Rewards.* No reward, counter or badge of the platform depends on a score or a rating, whatever its source: only on completion, which for a self-assessed item is a non-empty submission rated after the reveal. Every later mechanic of this kind applies the same rule. With no grade and no reward attached to the rating, a student who rates dishonestly only misleads their own review schedule.

=== Consequences

- One policy field, one item part and one projection rule. No new grader family: the graders of #adr("0015") are unchanged.
- The access gate gains one condition: the student's own submission, or the closing of the activity.
- Review (#adr("0026")) can schedule self-assessed items.
- The platform cannot detect a dishonest self-rating; it removes the reasons for one instead.
- Completion and rewards only count platform activities: work done in a Moodle-only activity is invisible to them.

#validation(id: "V-0027")[
  Before submitting, a student asking for the revealed part is refused, through the API and through any direct path to the release; after submitting, they receive it, while a classmate who has not submitted is still refused. A grader key placed in `revealed` stops publication, as does an exam declaring `self`. An empty submission cannot be rated. A self-assessed assignment sends Moodle a completion without a score. Two students who complete the same items, one rating everything _Again_ and the other _Easy_, get the same rewards.
]
