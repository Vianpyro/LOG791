#import "../template.typ": adr, arch, ext, todo, validation

== ADR-0018 — Build the judge or reuse an existing one <adr-0018>

*Status:* to write; blocks the judge implementation. \
*See also:* #arch("purpose-of-the-document")[architecture], section #arch("judge-engine")[Judge engine]; #adr("0002"), #adr("0013").

=== Context

Several judges already exist. Reusing one could remove the judge from the project's scope, and a known, maintained tool also eases the handover to the supervising professor and the ÉTS IT service. It must be settled before the first line of judge code.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Known facts*], [*To check*],
  [#ext("judge0")[Judge0]], [REST API, many languages, isolation through isolate.], [Exam priority, test confidentiality, maintenance activity.],
  [#ext("dmoj")[DMOJ]], [Full contest platform with its own judge and sandbox.], [Reusing the judge alone, Python/Java support under load.],
  [#ext("coderunner")[CodeRunner] and Jobe], [Moodle question type already known at ÉTS; Jobe runs the code.], [Isolation of Jobe, exam load, dependency on Moodle.],
  [Extend #ext("ctester")[CTester]], [Rust judge with gVisor in production, by the same author, in the language of #adr("0025"); single language (C), file spool as queue.], [Replacing the spool with the PostgreSQL queue (#adr("0001")); fitting language packs (#adr("0013")) into its judge.],
  [Build], [Isolation by gVisor (#adr("0002")), language packs (#adr("0013")).], [Cost for one person and for the maintainers after the handover.],
)

Criteria: isolation strength, Java and Python support, exam priority and reserved capacity, confidentiality of private tests, operability by the IT service, activity of the project.

=== Decision

#todo[Compare the options against the criteria, then decide.]

#validation(id: "V-0018")[
  The retained option judges the same standard I/O exercise in Java and Python under the exam load of the #arch("target-load")[target load].
]
