#import "../template.typ": adr, arch, ext, validation

== ADR-0018 — Build the judge or reuse an existing one <adr-0018>

*Status:* accepted for the first implementation; validated by V-0018. Applies #adr("0025"). \
*See also:* #arch("purpose-of-the-document")[architecture], section #arch("judge-engine")[Judge engine]; #adr("0002"), #adr("0013").

=== Context

Several judges already exist. Reusing one could remove the judge from the project's scope, and a known, maintained tool also eases the handover to the supervising professor and the ÉTS IT service. It must be settled before the first line of judge code.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Known facts*], [*Findings*],
  [#ext("judge0")[Judge0]], [REST API, many languages, isolation through isolate.], [The caller sends the tests with each request, so the API would hold assessment data. Its own queue and database sit outside PostgreSQL (#adr("0001")), so exam priority would live in another system. Ruby, Redis and a privileged container. Three sandbox escapes to root on the host in 2024 through symbolic links in the sandbox directory (CVE-2024-28185, CVE-2024-28189, CVE-2024-29021), fixed in 1.13.1.],
  [#ext("dmoj")[DMOJ]], [Full contest platform with its own judge and sandbox.], [The judge is written in Python (#adr("0025")) and sandboxes with ptrace and seccomp, not gVisor (#adr("0002")). It talks to its site through its own bridge protocol, which the API would have to reimplement.],
  [#ext("coderunner")[CodeRunner] and Jobe], [Moodle question type already known at ÉTS; Jobe runs the code.], [Jobe runs code as a low-privileged user under runguard, with resource limits but no system call filtering. It is a synchronous REST service with no queue. Questions and tests live in Moodle, which is optional (R6).],
  [Extend #ext("ctester")[CTester]], [Rust judge with gVisor in production, by the same author, in the language of #adr("0025"); single language (C), file spool as queue.], [The sandbox, the standard I/O comparison, the non-code graders and the logs carry over. The spool, the result tree and the gate are replaced by the PostgreSQL queue and `packages/content`. The C-specific parts (Unity, gcc diagnostics) become the C pack.],
  [Build], [Isolation by gVisor (#adr("0002")), language packs (#adr("0013")).], [Same result as extending CTester, without the lessons already encoded in its tests.],
)

Criteria: isolation strength, Java and Python support, exam priority and reserved capacity, confidentiality of private tests, operability by the IT service, activity of the project.

=== Decision

The judge is built in the workspace (`apps/judge`) by porting CTester's judge module by module. No external judge is reused, and CTester is not forked as a whole.

- *Kept and adapted*: the sandbox (gVisor through the Docker CLI, argv only, never a shell), standard I/O case comparison (normalization, numeric tolerance), the non-code graders as the first grader families of #adr("0015"), and the structured logs.
- *Replaced*: the spool and the result tree by the PostgreSQL queue and its claim query (#adr("0001"), #adr("0022")); CTester's gate by the shared opening rule in `packages/content` (#adr("0020")); the C-only build scripts by language packs (#adr("0013")), Python first, then Java.
- *Deferred*: the verdict cache (#arch("cache")[Cache]) and the interactive console.

A module is ported, with its tests, when the first end-to-end path needs it, not ahead of time.

Each external judge breaks at least two decisions already taken: the API never sees assessment data (#adr("0023")), exam priority is the claim query (#adr("0022")), isolation is gVisor (#adr("0002")), and the server has one language (#adr("0025")). CTester only lacks several languages, which #adr("0013") already covers.

=== Consequences

- The judge stays in the project's scope, the main risk for one person (R4); porting tested code rather than writing it reduces that cost.
- No external project to follow for security fixes: only gVisor and Docker.
- The judge only runs on Linux (`openat2`, Unix process interfaces): it is built and tested in the dev container and in CI, not on a Windows host.
- CTester and the platform diverge after the port; a fix in one is not carried to the other automatically.

#validation(id: "V-0018")[
  The retained option judges the same standard I/O exercise in Java and Python under the exam load of the #arch("target-load")[target load].
]
