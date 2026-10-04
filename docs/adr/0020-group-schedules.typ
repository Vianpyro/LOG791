#import "../template.typ": adr, arch, course, ext, validation

== ADR-0020 — Schedules per course group <adr-0020>

*Status:* proposed. Refines #adr("0012"). \
*See also:* #arch("purpose-of-the-document")[architecture], sections #arch("opening-over-time")[Opening over time] and #arch("courses-and-roles")[Courses and roles].

=== Context

An offering is split into groups that do not meet at the same time: in #course("LOG200"), each group has its own lecture, lab and competitive programming slots. An assignment, a lab exercise or a contest therefore opens and closes at different instants for different groups. Until now, the opening date was written in `exercise.json`, in the content repository. That repository is shared by every group and every term of the course (#adr("0012")), so the date there is the same for everyone.

=== Options considered

- *Dates in the content* (current): a single date for every group and every term.
- *A schedule file per term in the content repository*: validated in CI like the rest, but every postponement (a snow day, a moved lab) needs a commit by the course owners and a publication.
- *A schedule in the database, per group, entered by the instructor*.

=== Decision

- *The content says what, the offering says when.* `exercise.json` and `exams/<id>.json` carry no date. The content keeps only the `draft` or `archived` state.
- *Schedule*: one row per activity and group, with `opens_at` and `closes_at`; for a timed session (exam, contest), a start instant, the duration coming from the activity mode (#adr("0014")). A row without a group applies to every group that has no row of its own, so a course with a single group enters one line.
- *Closed by default*: an activity without a row for the student's group is not open to them. An activity reserved for one group needs no other rule.
- *A single function* computes a student's window for an activity: the student's extension, otherwise their group's row, otherwise the offering's row; then the student's accommodation, if the activity mode applies accommodations (#adr("0014")). The access gate, the catalog, the judge's double check and the preview all use it.
- *Extension*: an absolute window for one student and one activity, entered by an instructor for a one-off case. It replaces the group's dates.
- *Accommodation* (#adr("0012")): kept per student and per offering, not per activity, and relative: extra time as a percentage or in minutes, and an optional shift of the start. It is applied on top of the window resolved above: to the duration of a timed session, otherwise to `closes_at`. It therefore follows a postponement of the group, and combines with an extension.
- *End of a session*: a session closes at the last window of its students, accommodations included, not at the group's. Grading of final submissions, feedback, grade release (#adr("0022")), the judge floor (#adr("0021")) and the deployment refusal (#adr("0024")) wait for it. Each student's final submission still closes at their own window.
- *Entry*: an instructor edits the dates of their groups, and a coordinator those of every group, in the platform or by CSV import. A change applies on the next request, with no publication.
- *Group membership*: a student is in exactly one group per offering. When the #ext("moodle")[Moodle] space matches one group, the #ext("lti")[LTI] context gives the group; when a space merges several groups, membership comes from the CSV import. Which case applies at ÉTS remains to be confirmed.
- *Capacity*: exams and contests reserve judges per group session (#adr("0021")); groups at different times spread the load.

=== Consequences

- An activity can be open for one group and closed for another at the same instant: the catalog and the details are resolved per student, never per release.
- The judge reads the schedule to recheck the opening; it already reads #ext("postgresql")[PostgreSQL] (#adr("0001")).
- A later group's content is sealed on the platform, but can still pass by word of mouth between groups; pool draws (#adr("0015")) reduce this, the platform does not prevent it.
- Changing a date is an instructor action, not a content change: it is not versioned in the content repository and is recorded in the logs instead.

#validation(id: "V-0020")[
  At the same instant, one activity is open for group 01 and closed for group 02, through the API and through the judge. A postponement entered by an instructor applies with no publication. An instructor of group 01 cannot change the dates of group 02. A student without a group sees nothing open. Postponing group 01 also moves the window of a student with one-third extra time; that extra time does not extend an assignment; an extension and an accommodation combine. Grades of the session are not released before the last accommodated student's window closes.
]
