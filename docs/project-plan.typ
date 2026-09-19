// Project plan — LOG791 (special project, Fall 2026), carried out alone under the supervising professor.
// Content only; entry point: pdf/project-plan.typ
#import "template.typ": todo

= Context and problem statement

CTester is an automated assessment platform for C programs, developed for the TCH009 course and used in production: students write, compile and submit code there, which is judged by tests run in a gVisor sandbox. It was designed for a single course, a single language and a single machine.

The LOG200 course wants a comparable platform, with constraints that CTester does not cover: several languages, supervised assessments where an outage is critical, integration with Moodle and Safe Exam Browser, and hosting on ÉTS infrastructure. The MVP targets about 50 students; eventually, the platform must serve all instructors of the LOG/TI department and their groups, as well as part of the DEG.

*Problem.* How can we design a platform able to run untrusted code in several languages, withstand the load of a supervised exam and remain reusable from one course to another, on infrastructure with limited resources?

#todo[Have the problem statement validated by the supervising professor.]

= Objectives

+ Design and justify an architecture that separates the pedagogical application from the judge engine.
+ Implement a multi-language judge engine whose isolation is independent of the language.
+ Demonstrate that the platform withstands a simulated exam load of 400 students, with latency thresholds defined in advance.
+ Make the infrastructure rebuildable from the repository.

#todo[Attach a measurable success criterion to each objective (P95 latency, tolerated failure rate).]

= Supervision and method

Individual project supervised by the supervising professor. Work proceeds in short iterations: each iteration implements what is needed to validate an architectural hypothesis, then records the decision in an ADR. Regular follow-up with the professor serves as a checkpoint.

#todo[Set the frequency of follow-up meetings.]

= Deliverables

#table(
  columns: (4.5cm, 1fr),
  stroke: 0.5pt,
  [*Deliverable*], [*Content*],
  [Project plan], [This document.],
  [Architecture and ADRs], [High-level design and rationale for the choices, including the threat model.],
  [Prototype], [Deployable application, judge engine and isolation.],
  [Final report], [Approach, measurement results and recommendations for LOG200.],
)

#todo[Confirm the required deliverables and deadlines with the supervising professor.]

= Scope

*Required.* Isolated execution of untrusted code; several languages; submission and structured verdict; confidentiality of tests; exam mode with reserved capacity; institutional authentication; user interface in English and French (ADR-0011).

*Constraints.* Hosting on ÉTS infrastructure; several VMs replicable by Ansible and fault-tolerant (ADR-0010); 50 students for the MVP, then the scale of a department; personal data subject to Quebec's Law 25; workload of an individual project course.

*Exclusions.* Social features, gamification, collaborative editing, plagiarism detection, content editing interface, translations into languages other than English and French (left to contributors). Moodle / Safe Exam Browser integration is optional, depending on the access obtained.

= Technical choices

The detailed analysis is recorded in the architecture document and the ADRs.

#table(
  columns: (3cm, 1fr, 3.2cm),
  stroke: 0.5pt,
  [*Question*], [*Solutions considered*], [*Chosen*],
  [Isolation], [container only, gVisor, Firecracker, WebAssembly], [gVisor (ADR-0002)],
  [Queue], [PostgreSQL, Redis, RabbitMQ, file spool], [PostgreSQL (ADR-0001)],
  [System], [NixOS, distribution + Ansible, containers only], [Ubuntu + Ansible (ADR-0006)],
  [Content], [database, served copy, immutable releases], [Releases (ADR-0005)],
  [Build or reuse], [extend CTester, Judge0, DMOJ, CodeRunner], [To justify],
)

Technologies: Python/FastAPI, PostgreSQL (queue and streaming replication), gVisor, Docker or Podman, QEMU user mode (performance measurement), Pyodide/WebAssembly (visible tests in the browser), Ubuntu LTS and Ansible, nginx and certbot, Microsoft Entra ID, Safe Exam Browser, Moodle (LTI), Typst, GitHub Actions.

#todo[Justify why an existing judge (Judge0, DMOJ, CodeRunner) is not reused.]

= Schedule

#todo[Dated milestones: project plan, architecture, working prototype, load measurements, final report.]

= Risks

#table(
  columns: (0.9cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*ID*], [*Risk*], [*Mitigation*],
  [R1], [The ÉTS VM is not available in time.], [Reproducible environment outside ÉTS; gVisor does not require KVM.],
  [R2], [Sandbox escape by hostile code.], [Defense in depth, no network or secrets in the judge, hostile tests in CI.],
  [R3], [Exam load not sustained.], [Early measurements; reserved capacity; backpressure.],
  [R4], [Scope too broad for one person.], [Explicit exclusions; prototype focused on judging.],
  [R5], [The platform does not work under SEB (a prerequisite for the project).], [SEB is free and installs without ÉTS: prototype tested under SEB from the first weeks, with a test `.seb` file (ADR-0009); confirm early the SEB version and the exam workstation image; direct launch through a `sebs://` link, without Moodle.],
  [R6], [Moodle access blocked.], [Optional Moodle integration: the exam starts directly in the platform.],
  [R7], [A VM fails during an exam.], [Stateless, redundant judges, recovery of abandoned jobs, PostgreSQL replica, VMs rebuilt by Ansible (ADR-0010).],
)
