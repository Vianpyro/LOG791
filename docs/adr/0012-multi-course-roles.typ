#import "../template.typ": validation

== ADR-0012 — Courses, offerings and per-course roles

*Status:* proposed. Applies ADR-0014. \
*See also:* architecture, section "Courses and roles".

=== Context

The architecture was written for a single course. The instructor preview relies on "instructor accounts", which assumes a global role. Serving every LOG/GTI course and the DEG computing courses breaks that assumption: the same person can teach LOG121, be a teaching assistant in LOG200 and have no access to TCH055. Enrollments change every term and already exist in Moodle (ENA).

=== Options considered

- *Global roles*: simple, but an instructor would see every course; incompatible with Quebec's Law 25.
- *One platform instance per course*: strong separation, but one deployment per course to operate and an exam capacity that cannot be shared.
- *One instance, data attached to an offering, roles per offering*.

=== Decision

- *Model*: `Course` (code, e.g. LOG200) → `Offering` (course and term, e.g. LOG200 A2026) → `Group`. Every exercise publication, submission, activity and result belongs to an offering. One database, filtered by offering.
- *Roles, per offering, never global*: `student`; `ta` (sees results, not private tests); `instructor` (course instructor or lecturer: publishes, previews, runs exams for their groups); `coordinator` (every group of the course). Only `admin` is global, and it grants operations on the platform, not access to results.
- *Enrollment sources* (an extension point under ADR-0014): LTI 1.3 from Moodle, where the LTI `context` identifies the offering, Names and Roles provides the roster and Assignment and Grade Services returns grades; a CSV import by the instructor when Moodle is not available. Microsoft Entra ID provides identity only, never roles.
- *Content*: one content repository per course, with its own owners and its own proof CI; the `current` release pointer (ADR-0005) is kept per course, so rolling back LOG121 does not affect LOG200.
- *Capacity*: exams are scheduled in advance and reserve judges for their time slot; outside exams, each offering has a queue quota so that a large assignment does not starve a lab.
- *Accommodations*: extra time and a shifted time slot per student and per exam; time is still computed by the server.

=== Consequences

- Access checks are always "role in this offering"; the preview gate and the judge's double check (architecture, "Content lifecycle") use the same rule.
- Retention is purged per completed offering, which answers part of open question 10.
- A person's roles are recomputed at each LTI launch or import; a role removed in Moodle disappears at the next synchronization.

#validation(id: "V-0012")[
  An instructor of LOG121 cannot read any LOG200 result; a TA cannot read private tests; the same roles are produced by an LTI launch and by the equivalent CSV import; rolling back LOG121 content leaves LOG200 unchanged.
]
