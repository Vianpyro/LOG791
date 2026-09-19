// Content only: the page and title are set by the entry point
// (pdf/architecture.typ) or by the report. Do not add #set page here.
#import "template.typ": decision, hypothesis, mermaid, validation

= Purpose of the document

This document presents the architecture envisioned for a programming learning and assessment platform, initially intended for the LOG200 course at the École de technologie supérieure. The MVP targets about 50 students. LOG121 comes second; eventually, the platform must serve every LOG/GTI course and the computing courses of the DEG, for students and instructors alike (see the course inventory at the end of this document).

The platform is a conceptual evolution of CTester, a system originally developed for the automated assessment of C programs in the context of the TCH009 course.

The goal is not simply to reimplement CTester in a new technology. Rather, the project seeks to identify the architectural properties that allow such a platform to be reused across several courses, to support several programming languages and to operate in supervised assessment settings.

This document is deliberately evolving. Not all the decisions presented here are final. When a decision still has to be validated by measurements or experiments, it is explicitly identified as such.

= Problem statement

The platform must allow students to write, compile and run code directly in a controlled environment.

This feature introduces a fundamental constraint: student code must be treated as *untrusted* code.

A submitted program may be incorrect by accident, but it may also behave in an extremely costly way or deliberately try to exploit the execution environment.

The platform must at the same time be able to support ordinary learning activities and supervised assessments that may involve several hundred students.

#decision[
  The architectural problem is therefore treated as one combining pedagogy, security, performance and operability rather than as a mere web interface problem.
]

The guiding question of the project is the following:

#quote[
  How can we design a programming learning and assessment platform able to run untrusted code in several languages, to support heavy loads during supervised assessments and to remain flexible enough to be reused in different teaching contexts?
]

= Objectives

== Functional objectives

The platform must in particular allow:

- creating and publishing exercises;
- organizing exercises into activities, assignments and exams;
- writing code in a web environment;
- saving drafts;
- submitting programs;
- automated compilation and execution;
- test-based assessment;
- presenting a structured verdict;
- tracking progress;
- supporting several programming languages;
- integrating with Moodle;
- use in a supervised exam context.

== Non-functional objectives

The following properties are considered particularly important:

#table(
  columns: (2.8cm, 1fr),
  stroke: 0.5pt,
  [*Property*], [*Objective*],

  [Security],
  [Limit a student program's ability to access the hosting system, other submissions or sensitive data.],

  [Performance], [Keep latency acceptable even during heavy bursts of submissions.],

  [Scalability],
  [Allow judging capacity to grow independently of the main application's capacity.],

  [Reproducibility],
  [Be able to rebuild the infrastructure and deployment environments in an automated way.],

  [Extensibility], [Add a course, a language, a question type or an activity mode without modifying the core (ADR-0014).],

  [Maintainability],
  [Keep responsibilities clearly separated, boundaries checked in CI and components testable independently (ADR-0014).],
)

= Architectural principles

== Separation of concerns

The platform is designed around several distinct responsibilities.

#mermaid(
  "
  flowchart LR
      A[Student interface] --> B[API / Application]
      B --> C[Submission queue]
      C --> D[Judge engine]
      D --> E[Execution sandbox]
      E --> F[Compilation / Tests]
  ",
  document-context: true,
  width: 100%,
)

This separation notably allows the judge engine to evolve without modifying the pedagogical application.

== Zero-trust principle

Student code must never be run directly by the application process.

#decision[
  The API never compiles or runs student code directly.
]

A submission is turned into an asynchronous job and handled by a component specifically responsible for running untrusted code.

This separation reduces the main application's attack surface and allows different resource policies to be applied to code execution.

== Separation between application and judging

The main application is responsible in particular for:

* authentication;
* user management;
* courses;
* exercises;
* assignments;
* exams;
* results;
* progress;
* administration;
* Moodle integration.

The judge engine is responsible in particular for:

* receiving the jobs to run;
* scheduling their execution;
* selecting the appropriate runtime;
* enforcing resource limits;
* creating the isolated environment;
* compiling and running the program;
* running the tests;
* producing a verdict.

This separation also allows both parts of the system to be sized independently.

== Stable core and extension points

The courses to serve differ in language, question format and activity mode. The project is maintained by one person, so variation between courses must never accumulate as special cases in the core.

#decision(id: "ADR-0014")[
  The core knows no language, course or exercise by name. Everything that varies goes through an extension point made of declarative data, a versioned contract and a conformance suite run in CI. An extension point only exists if at least two real implementations are already known.
]

#table(
  columns: (3.4cm, 1fr),
  stroke: 0.5pt,
  [*Extension point*], [*Initial implementations*],
  [Question type], [Code exercise, multiple choice, short answer],
  [Activity mode], [Practice, assignment, exam],
  [Language pack], [P1 languages (ADR-0013)],
  [Test runner], [Standard I/O, unit tests, SQL],
  [Judging service], [Ephemeral PostgreSQL, shared Oracle],
  [Enrollment source], [LTI 1.3, CSV import (ADR-0012)],
  [Isolation backend], [gVisor, Firecracker],
  [Statement renderer], [Markdown, Typst],
)

An exam or an assignment is a list of items of any type combined with a mode. A course is an offering and a content repository, with no code of its own. Component boundaries (the API does not import the judge, the core imports no implementation) are checked by an architecture test in CI.

#validation[
  Adding LOG121 after LOG200 must only touch extension point implementations and content. Any core change it requires is recorded as an architecture defect.
]

= Overall architecture

== Logical view

The envisioned overall architecture is as follows:

#mermaid(
  "
  flowchart TB
    A[Student] --> B[Browser / SEB]

    subgraph AUTH[Authentication]
        IDP[Microsoft Entra ID]
    end

    RP[nginx reverse proxy<br/>TLS · static · rate limit]

    subgraph APP[Application]
        API[Web / API]
        DB[(PostgreSQL)]
    end

    subgraph EVAL[Assessment]
        Q[PostgreSQL queue<br/>Backpressure · Priorities · Fairness]
        S[Judge Scheduler]
        J1[Judge]
        J2[Judge]
        J3[Judge]
        JN[...]
    end

    subgraph SANDBOX[Isolation]
        SB[Sandbox Runtime]
        P[Student program]
        T[Private tests]
    end

    subgraph CONTENT[Content]
        CR[Content repository]
        PUB[Publishing<br/>validation · projection · Typst rendering]
        REL[(Public releases)]
    end

    CR --> PUB --> REL
    REL -->|read-only| API
    CR -->|assessment data| S

    B -->|OIDC| IDP
    B -->|HTTPS + token| RP
    RP --> API

    API --> DB
    API -->|Submission| Q

    Q --> S
    S --> J1
    S --> J2
    S --> J3
    S --> JN

    J1 --> SB
    J2 --> SB
    J3 --> SB
    JN --> SB

    SB -->|gVisor / Firecracker| P
    SB -->|Controlled access| T

    S -->|Verdict| DB
  ",
  document-context: true,
  width: 100%,
)

This diagram describes responsibilities rather than a final deployment topology.

Pedagogical content follows a path separate from submissions: it is published from its own repository, without going through the API or the queue.

#decision[
  The API only sees the public projection of the content. Only the judge engine reads the assessment data. The content lifecycle is detailed in its own section.
]

== Application and API

The web application is the part responsible for the pedagogical state.

It must not depend on the presence of a local compilation process. A submission is instead represented as a job that can be placed in a queue.

This makes it possible to decouple:

- the number of HTTP requests;
- the number of pending submissions;
- the number of available judges;
- the number of concurrent executions.

== Entry layer

The platform is deployed on several VMs with limited resources, replicable by Ansible, so that a failure during an exam does not interrupt the service (ADR-0010). Every additional infrastructure component consumes memory and CPU that are no longer available for judging.

#decision[
  An infrastructure component is only added when a measured need justifies it.
]

=== Reverse proxy

An nginx reverse proxy is the platform's only HTTP entry point. It is responsible for:

- TLS termination (ACME certificates obtained and renewed by certbot);
- serving the web interface's static files;
- response compression;
- request rate limiting (`limit_req`), notably on submissions;
- relaying the long-lived connections (SSE or WebSocket) used to notify verdicts.

#decision[
  nginx is chosen for its small memory footprint, its native rate limiting and its availability in the Ubuntu repositories.
]

#hypothesis[
  If the institution already terminates TLS upstream of the VM, nginx remains useful for static files and rate limiting.
]

=== Load balancing

No dedicated load balancer is planned as long as the API fits on one VM.

- On the HTTP side, the API is run by several processes (uvicorn workers) sharing the same socket; the kernel distributes connections among them.
- On the judging side, judges _pull_ jobs from the queue rather than having them pushed. The queue therefore acts as the dispatcher itself, and capacity is adjusted by changing the number of judges.

#decision[
  If the API is spread over several `web` VMs, an nginx `upstream` block balances the load and removes a failed instance; this choice will be settled based on load tests (ADR-0010).
]

== Submission queue

The queue is an important abstraction between the application and the judge engine.

It makes it possible to absorb load peaks without the application having to run the programs itself.

It will eventually need to support:

- exam priority;
- limiting the number of concurrent jobs;
- fair distribution of resources;
- backpressure;
- controlled retries;
- detection of abandoned jobs;
- measurement of waiting time.

#hypothesis[
  The exact queuing and scheduling policy will have to be determined
  experimentally based on the observed loads.
]

#decision[
  The queue is initially implemented in PostgreSQL (`SELECT … FOR UPDATE SKIP LOCKED` and `LISTEN/NOTIFY`) rather than with a dedicated service such as Redis or RabbitMQ.
]

This choice adds no service to the VM and places the queue state in the same transaction as the submission state. Retries, detection of abandoned jobs and exam priority can then be expressed directly in SQL.

#validation[
  Load tests will have to confirm that PostgreSQL is sufficient as a queue for an exam load. A dedicated broker will only be considered if a limit is measured.
]

= Judge engine

== Multi-language abstraction

One of the major objectives is not to design the engine around C.

The envisioned conceptual model is:

#mermaid(
  "
  flowchart TD
    J[Judge]

    J --> LR[Language Runtime]
    J --> SB[Sandbox Runtime]
    J --> RL[Resource Limits]

    subgraph LANG[Supported Languages]
        C[C] -.-> C1[Compiler]
        PY[Python] -.-> PY1[Interpreter]
        JAVA[Java] -.-> JAVA1[Compiler / JVM]
        RUST[Rust] -.-> RUST1[Compiler]
        Other[...] -.-> Other1[...]
    end

    LR --> C
    LR --> PY
    LR --> JAVA
    LR --> RUST
    LR --> Other[...]
  ",
  document-context: true,
  width: 100%,
)

A language must mainly define how to:

- prepare the files;
- compile the program;
- launch the program;
- interpret its result;
- possibly manage its dependencies.

The isolation mechanism should not depend on the language.

#decision(id: "ADR-0013")[
  Each language is a declarative _language pack_: pinned image built in CI, compile and run commands, version and options (for C, the standard is an exercise option), default limits with a time multiplier, and capabilities (browser, instruction counting). Test formats are separate _runners_ (standard I/O, unit tests, SQL) that all produce the same JSON report.
]

== Language catalog

LOG200 aims for as many languages as possible, prioritized by industry use and its expected trend, with the LeetCode and CodinGame catalogs as the horizon.

#table(
  columns: (1.4cm, 1fr, 3.2cm),
  stroke: 0.5pt,
  [*Tier*], [*Languages*], [*When*],
  [P1], [Python 3, Java, C, C++, JavaScript, TypeScript, C\#, Go, Rust, Kotlin], [With LOG200],
  [P2], [PHP, Ruby, Swift, Dart, Scala, Bash, SQL (PostgreSQL)], [After load validation],
  [P3], [Haskell, OCaml, Elixir, Erlang, Racket, Clojure, Lua, Perl, F\#, Groovy, VB.NET, Pascal, D, Objective-C, Pep/8], [On request or contribution],
)

Standard I/O is the default test format for LOG200: one set of tests is valid for every language. A function-signature harness requires a driver per language and is only added per exercise.

== Rust

The judge engine is a natural candidate for an implementation in Rust.

It is likely to handle:

- many concurrent jobs;
- external processes;
- execution timeouts;
- resource limits;
- job queues;
- communication with the sandboxes;
- metrics collection.

#decision[
  The pedagogical application can initially stay in Python/FastAPI while the judge engine is treated as an independent component, potentially implemented in Rust.
]

This decision is not, however, based solely on the claim that Rust would be "faster".

#validation[
  The choice of the engine's language will have to be validated by profiling and benchmarks. A complete rewrite of CTester in Rust is not considered a goal in itself.
]

= Submission isolation

== Problem

A classic container is not considered a sufficient security boundary on its own for running hostile student code.

The architecture must therefore distinguish:

1. the process management mechanism;
2. the container runtime, if any;
3. the main isolation mechanism;
4. resource limits.

Conceptually:

#mermaid(
  "
  flowchart LR
    J[Judge] --> S[Sandbox abstraction]

    subgraph CONSTRAINTS[Resource & execution constraints]
        FS[Filesystem]
        CPU[CPU]
        MEM[Memory]
        PROC[Processes]
        TIME[Timeout]
        NET[Network policy]
    end

    subgraph ISOLATION[Isolation boundary]
        G[gVisor]
        F[Firecracker]
        O[Other solutions]
    end

    S --> CONSTRAINTS
    S --> ISOLATION
  ",
  document-context: true,
  width: 100%,
)

== gVisor

gVisor is currently the preferred candidate for the first implementation.

It provides an additional isolation layer between the executed program and the host Linux kernel.

Systrap mode is particularly attractive when the platform itself runs inside a virtual machine.

#decision[
  gVisor Systrap is the initially envisioned isolation solution.
]

#hypothesis[
  gVisor should offer a sufficiently good trade-off between security, performance and operational complexity for the LOG200 context.
]

== Firecracker

Firecracker is a particularly attractive alternative when priority is given to a strong isolation boundary.

Its model relies on microVMs running their own Linux kernel under KVM.

On the other hand, the microVM lifecycle and the integration with the judge engine are more complex than an architecture based on containers.

#validation[
  gVisor and Firecracker should ideally be compared experimentally on the project's real workloads before the final choice is made.
]

== WebAssembly

WebAssembly is another possibility thanks to its strongly sandboxed execution model.

However, using it for a general multi-language platform raises a different question: the student program must be runnable in a WebAssembly environment compatible with its language and libraries.

#decision[
  WebAssembly is considered a complementary avenue rather than the platform's
  initial universal environment.
]

This avenue is adopted on the client side: in languages where it is easy, visible tests run in the browser before anything is sent to the server (ADR-0008). The judge remains the only reference.

== Container runtime

Docker or Podman can be used to manage the lifecycle of execution environments.

They are not, however, considered the main security boundary.

The target model is therefore rather:

#mermaid(
  "
  flowchart LR
    J[Judge] --> C[Container Runtime]
    C --> I[Isolation gVisor/Firecracker]
    I --> S[Student code]
  ",
  document-context: true,
  width: 100%,
)

#hypothesis[
  The exact choice between Docker and Podman should have less impact than the
  choice of the isolation mechanism itself.
]

= Resource management

Each execution must have an explicit set of limits.

These include in particular:

#table(
  columns: (4cm, 1fr),
  stroke: 0.5pt,
  [*Resource*], [*Envisioned limit*],

  [Time], [Maximum timeout per step and per submission.],

  [CPU], [Number of cores or amount of usable CPU.],

  [Memory], [Memory limit per execution.],

  [Processes], [Maximum number of processes or threads.],

  [Storage], [Maximum temporary space.],

  [Network], [Network access explicitly denied or limited.],
)

These limits must be enforced regardless of the program's correctness.

A program stuck in an infinite loop must produce a timeout rather than consume a system resource indefinitely.

== Performance measurement

Execution time is a safeguard, not a measurement. It varies with the VM's load and with the language, and therefore cannot be used to compare algorithms fairly.

#decision(id: "ADR-0007")[
  Performance is measured in executed instructions, deterministically, and compared with a reference solution in the same language, complexity being the main criterion. The limit of the measurement pass is an instruction budget. Measurement is done after the exam, on each student's last submission for each exercise.
]

= Load and performance

== Target load

An exam may involve about 400 students.

It would, however, be incorrect to model the load as simply 400 concurrent HTTP requests.

Each student may produce several submissions:

#mermaid(
  "
  flowchart LR
    A[~400 students] --> B[Burst of submissions]

    B --> C[Judging queue]

    C --> D[Fix]
    D --> E[New submission]
    E --> C
  ",
  document-context: true,
  width: 100%,
)

The actual load therefore depends heavily on the students' behavior over time.

== Sizing

The system must allow the number of judge workers to be increased independently of the main application.

For example:

#mermaid(
  "
  flowchart TD
    API[Application / API] --> Q[Queue]

    Q --> J1[Judge worker]
    Q --> J2[Judge worker]
    Q --> J3[Judge worker]
    Q --> JN[...]

    J1 --> S1[Sandbox]
    J2 --> S2[Sandbox]
    J3 --> S3[Sandbox]
    JN --> SN[...]
  ",
  document-context: true,
  width: 100%,
)

This architecture allows capacity to be adjusted without modifying the pedagogical logic.

== Cache

No dedicated cache server (Redis, Memcached) is planned initially. Caching is instead placed where it reduces a real cost:

#table(
  columns: (3.2cm, 1fr),
  stroke: 0.5pt,
  [*Location*], [*Content*],

  [Browser / nginx],
  [Static files versioned by hash and served with long-lived `Cache-Control` headers.],

  [API], [Published exercise data, rarely modified, kept in process memory.],

  [Judge],
  [Preloaded images and toolchains, sandboxes prepared in advance and, possibly, compiled artifacts of the private tests.],
)

Authentication relies on OIDC tokens issued by Microsoft Entra ID, which avoids maintaining server-side session storage.

#hypothesis[
  The dominant cost of a submission lies in sandbox startup and compilation rather than in data access. Judge-side caching should therefore have a greater impact than any application cache.
]

#decision[
  A shared cache will only be introduced if several API instances need to share the same state.
]

== Metrics

Benchmarks will have to measure in particular:

- submission throughput;
- time spent in the queue;
- total latency;
- P50;
- P95;
- P99;
- compilation time;
- execution time;
- CPU usage;
- memory usage;
- maximum number of concurrent jobs;
- timeout rate;
- infrastructure failure rate;
- the share of test runs handled in the browser (ADR-0008);
- the time to drain the measurement queue after an exam (ADR-0007).

#decision[
  Performance will be assessed with reproducible workloads rather than with a theoretical estimate alone.
]

== Comparison of isolation mechanisms

An experiment may in particular compare:

#mermaid(
  "
  flowchart LR
    L[Identical load] --> G[gVisor]
    L --> F[Firecracker]

    G --> GM[Measurements]
    F --> FM[Measurements]

    subgraph METRICS[Metrics]
        M1[Startup time]
        M2[Latency]
        M3[Throughput]
        M4[CPU / memory]
    end

    GM --> METRICS
    FM --> METRICS

    METRICS --> C[Comparison]
  ",
  document-context: true,
  width: 100%,
)

The criteria will include at least:

- startup time;
- submission latency;
- throughput;
- memory consumed;
- CPU consumed;
- behavior under heavy load;
- behavior with malicious or pathological executions;
- operational complexity.

= Exam mode

The platform must distinguish the learning context from the assessment context.

Three conceptual modes are currently envisioned:

#mermaid(
  "
  flowchart LR
    P[Practice]
    A[Assignment]
    E[Exam]

    P --> P1[Exploration]
    P --> P2[Full feedback]
    P --> P3[Social features]

    A --> A1[Deadline]
    A --> A2[Progress]
    A --> A3[Submissions]

    E --> E1[Duration]
    E --> E2[Control]
    E --> E3[Reserved resources]
    E --> E4[Limited feedback]
  ",
  document-context: true,
  width: 100%,
)

== Safe Exam Browser

Safe Exam Browser is considered a complementary mechanism rather than a feature the platform should reimplement.

SEB mainly controls the environment of the student's computer, while the platform controls the pedagogical state of the exam.

#mermaid(
  "
  flowchart LR
      subgraph PLATFORM[Platform]
        P[Pedagogical state of the exam]
        P --> P1[Exam]
        P --> P2[Exercises]
        P --> P3[Time]
        P --> P4[Submissions]
        P --> P5[Results]
    end

    subgraph SEB[Safe Exam Browser]
        S[Student environment]
        S --> S1[Lockdown]
        S --> S2[Allowed applications]
        S --> S3[Navigation]
        S --> S4[Configuration]
    end

    S -->|Controlled access| P
  ",
  document-context: true,
  width: 100%,
)

=== Constraints imposed by SEB

- *Verification.* The server verifies the SEB configuration on exam routes, even if the exam starts in Moodle (ADR-0009).
- *Authentication.* The URL filter allows `login.microsoftonline.com`. Phone-based multi-factor authentication is incompatible with the ban on phones: the session is opened before the exam, or a conditional access policy applies to the rooms.
- *Resources.* No CDN: browser runtimes (Pyodide, esbuild-wasm, etc.) are served by the platform.
- *Navigation.* No new windows and no downloads: statements are rendered as HTML or SVG, not PDF. Automatic submission redirects to SEB's "Quit URL".
- *Recovery.* If SEB is restarted, the student gets their autosaved drafts back, time is computed by the server and the SSE stream resumes using `Last-Event-ID`.
- *Editor.* Keyboard shortcuts and the clipboard, which SEB may restrict, are tested.
- *Engines.* SEB for Windows relies on Chromium; SEB for macOS and iOS rely on WebKit, where service workers are limited. Fallback: the HTTP cache.
- *Language.* SEB does not pass on a language choice: the interface language is set in the platform itself (ADR-0011).

== Reserved resources

An exam must be able to rely on reserved judging capacity.

The goal is to prevent a non-critical activity from consuming all the workers while students are taking an exam.

#hypothesis[
  A priority system or separate capacity pools could be
  sufficient to guarantee this property without requiring a
  completely separate infrastructure.
]

= Courses and roles

The platform serves several courses, each taught every term by several people in several groups.

#decision(id: "ADR-0012")[
  Data belongs to an _offering_ (a course in a term, e.g. LOG200 A2026), split into groups. Roles are held per offering, never globally: `student`, `ta` (results, no private tests), `instructor` (publishes, previews, runs exams for their groups), `coordinator` (every group of the course). Only `admin` is global, for platform operations.
]

- *Enrollments* come from Moodle through LTI 1.3 (the LTI context identifies the offering, Names and Roles provides the roster, Assignment and Grade Services returns grades), or from a CSV import when Moodle is not available. Microsoft Entra ID provides identity only.
- *Shared capacity*: exams are scheduled in advance and reserve judges for their time slot; outside exams, each offering has a queue quota.
- *Accommodations*: extra time and a shifted time slot per student and per exam, computed by the server.
- *Instructor tools* (minimum): results per group, CSV export, re-judging an exercise after a test is fixed, individual extensions, preview.
- *Personal data*: an instructor only sees their offerings; retention is purged per completed offering (Law 25).
- *Accessibility*: the interface targets WCAG 2.1 AA, including a keyboard-navigable editor.

= Pedagogical model

The architecture must not limit an exercise to a "statement + solution" pair.

An exercise is instead considered a declarative resource containing pedagogical and assessment information.

Conceptually:

```text
Exercise
│
├── metadata
├── statement
├── language constraints
├── difficulty
├── skills
├── prerequisites
├── context
├── tests
├── hints
└── release rules
```

Public and private tests must remain separate.

#mermaid(
  "
  flowchart LR
    E[Exercise] --> P[Public data]
    E --> PR[Private data]

    P --> UI[Student UI]
    PR --> J[Judge]
  ",
  document-context: true,
  width: 100%,
)

This separation notably avoids exposing the test cases used to assess submissions.

== Extensibility

Adding an exercise should ideally be mainly a configuration and content operation rather than a change to the platform's source code.

The architecture must therefore favor a declarative model.

The assessment engine interprets the exercise data and selects the runtime matching the requested language.

= Content lifecycle

In CTester, most content-related incidents did not come from the judge, but from the path between the instructors' repository and what the student receives: an answer key exposed by accident, an exercise disappearing from the menu the day before class, an empty catalog served silently. This path is therefore treated as an architectural component in its own right.

== Overview

#mermaid(
  "
  flowchart LR
    D[Private content<br/>repository] --> V[Validation]
    V --> P[Public projection]
    P --> R[Immutable release<br/>revision = hash]
    R --> PTR[current<br/>pointer]

    PTR --> API[API<br/>public data]
    D --> J[Judge<br/>private tests]
    PTR -.->|re-checks opening| J
  ",
  document-context: true,
  width: 100%,
)

Content is edited in a repository separate from the platform's code. Each exercise groups its metadata, its statement, its public files (templates) and its private assessment data:

```text
exercises/<id>/
├── exercise.json      metadata, skills, opening rules
├── statement.md       or statement.typ, never both
├── public/            templates handed to the student
└── assessment/        tests, cases, judge configuration (private)
```

#decision[
  Publishing is triggered by a change to the content repository and requires no redeployment or restart of the application or the judge.
]

== Validation

Invalid content must never replace the active publication.

Validation checks in particular the metadata schema, the uniqueness of identifiers, the consistency of collections and the absence of ambiguity, for example two statement formats for the same exercise. It fails *before* the first write.

#decision[
  A validation error stops publishing, naming the faulty exercise and field. The previous release keeps being served.
]

== Public projection

The public release is not a copy of the content repository. It is rebuilt field by field from an explicit list of what may be shown.

A second check then re-reads the produced projection and refuses to publish if a key reserved for assessment data (`answer`, `expect`, `cases`, `stdin`, internal paths…) appears in it.

#decision[
  The projection is built by positive enumeration (what is published) and checked by negative enumeration (what must never be). The first protects against today's oversight, the second against the field added tomorrow.
]

The published catalog contains *all* exercises, including those not yet open, with their opening date. An exercise's details (statement, templates, questions) are only written for open exercises.

#hypothesis[
  Showing a locked exercise with its date is better than hiding it: in CTester, an exercise missing from the menu was perceived by students as an outage.
]

== Releases and rollback

Each publication produces a release directory whose identifier is the hash of its content. Republishing unchanged content creates nothing, and a change creates a new release that coexists with the previous ones.

The active release is designated by a pointer, a file rather than a symbolic link. A container mount resolves the link at startup, so a change of link would only be visible after a restart.

#decision[
  Rolling back content consists of rewriting the pointer to a previous release. It is instantaneous and redeploys no component. Each course has its own content repository and its own pointer: rolling back one course leaves the others unchanged (ADR-0012).
]

Pruning keeps the latest releases according to a publication date written in their manifest, not according to the file system's modification time. In CTester, the latter had a different granularity on Windows and on Linux, which caused a release that was supposed to be kept to be deleted.

== Opening over time

Each exercise carries a state (`draft`, `scheduled`, `open`, `archived`) and, if needed, an opening date.

#decision[
  A single function decides whether an exercise is accessible at a given instant. A `scheduled` exercise whose date has passed is open, without any commit or scheduled task on the morning of the class.
]

All reads of an exercise (details, submission, draft, discussion) go through a single gate that resolves the identifier in the active release and refuses anything that is not open. A link shared ahead of time therefore bypasses nothing.

== Double check by the judge

The API only passes an exercise identifier to the judge. The judge itself resolves this identifier against the active release before reading the assessment data.

#decision[
  The judge does not trust the API about whether an exercise is open. A compromised API can lie about who authored a submission, but cannot get the tests of a closed exercise executed.
]

== Instructor preview

An instructor must be able to view and submit an exercise before it opens, under real conditions, without opening it to students.

The projection therefore writes a restricted copy of unopened exercises, served only to the instructors of that course and never cached by an intermediary. The role in the offering (ADR-0012) is recomputed server-side on every request, and again by the judge, from the authenticated identity.

#decision[
  Preview is a property of the authenticated identity, not a global flag. The access gate's default behavior is closed.
]

== Content proof

An incorrect test produces a wrong verdict that the student cannot contest.

#decision[
  Each exercise comes with a reference solution kept outside the published repository. A check compiles this solution and runs it through the real judge before opening. An exercise without a solution is flagged as "unproven".
]

#validation[
  This check must be integrated into the content repository's CI, and unproven exercises must be visible before their opening date.
]

= Statement rendering

A programming statement contains text, code, formulas and sometimes tables, figures or diagrams. Two formats are supported, with opposite rendering models.

#table(
  columns: (2.8cm, 1fr, 1fr),
  stroke: 0.5pt,
  [], [*Markdown*], [*Typst*],
  [Use], [Default, the vast majority of statements], [Tables, diagrams, figures, multi-page layout],
  [Rendering], [In the browser, at display time], [At publication time, in a container],
  [Delivered], [Source text], [HTML, with light and dark SVG as fallback],
  [Accessibility], [Full], [Reduced for SVG],
)

== Markdown

Markdown is rendered client-side by a deliberately restricted grammar: paragraphs, headings, lists, inline code, highlighted code blocks and emphasis. A general-purpose library is not used.

This decision stems from two observations made in CTester:

- a full Markdown library and its sanitizer weighed several times the rest of the page, on the path of students who are not logged in;
- CommonMark's rules are poorly suited to C: the asterisk is also the dereference and multiplication operator, and `*quotient and *remainder` becomes italics, losing both asterisks.

#decision[
  Emphasis is only recognized when the delimiter touches a word on the inner side and is separated from the text on the outer side. The underscore `_` is not an emphasis syntax, since it appears in most identifiers.
]

Formulas are explicitly delimited by `$…$` and converted to native MathML. The browser draws them without any library or external font, which requires no exception to the content security policy (CSP).

#decision[
  A formula is never guessed. In C, `z/4` is an integer division and not a fraction, and a fraction bar would teach the opposite. A formula that does not parse is displayed as inline code, never as an error.
]

Markdown content comes from the private repository reviewed by the teaching team. Any HTML output is nevertheless built from escaped fragments.

#hypothesis[
  Content written by students (forum, discussions) requires a different pipeline: escaping before parsing and allow-list sanitization on every display. The two pipelines must not be merged.
]

== Typst

Typst is reserved for what the Markdown grammar cannot express.

#mermaid(
  "
  flowchart LR
    S[statement.typ] --> C[Copy without<br/>private data]
    C --> T[typst container<br/>--root · no network]
    L[Shared template<br/>vendored packages] --> T
    T --> H[HTML]
    T --> SV[Light / dark SVG]
    H --> R[Release]
    SV --> R
  ",
  document-context: true,
  width: 100%,
)

#decision[
  Nothing is compiled per request. Typst runs during publishing, and the student receives static files. The Internet-facing service has no Typst compiler, no access to private content and no access to the container runtime.
]

Compilation treats the document as untrusted, even if it is written by the teaching team:

- it is done from a *copy* of the exercise that does not contain the assessment data;
- the Typst project root is limited to this copy, which rejects outgoing relative paths and re-roots absolute paths;
- the container has no network access, and the packages used (course template, Mermaid) are vendored;
- a maximum timeout bounds a heavy document that would block publishing.

The course template is distributed as a local Typst package. The instructor writes no preamble: the platform applies the template, then includes the statement.

=== Themes and formats

An SVG is painted once and for all and cannot follow the page's theme. Each statement is therefore rendered twice, in light and in dark.

Typst's HTML export is preferred when it is complete. Publishing detects elements ignored by the HTML export and then publishes only the SVGs.

#decision[
  HTML is displayed first and SVG serves as a fallback, with no choice exposed to the student. An HTML failure does not block publishing; an SVG failure does.
]

=== Rendering cache

The cache key covers everything rendering depends on: Typst version, template, vendored packages and the exercise tree *except* its assessment data. Fixing a test case therefore recompiles no statement.

Rendered files are part of the release hash. A template change therefore produces a new release, which can be rolled back through the pointer like any other publication.

#decision[
  The rendering cache is content-addressed and kept outside the releases directory, which is pruned at each publication.
]

=== Accessibility limitation

Typst vectorizes its glyphs in the SVG: the text there is not selectable, not searchable and not readable by a screen reader. HTML does not have this limitation, but it is not always available.

#decision[
  Markdown remains the default format. Typst is only used for content that cannot be expressed otherwise.
]

#validation[
  The maturity of Typst's HTML export will have to be reassessed with each release. If it becomes sufficient, the SVG fallback can be dropped and the accessibility limitation will disappear.
]

= Internationalization

The platform's interface is multilingual, while the project itself (code, documentation) is written in English only.

#decision(id: "ADR-0011")[
  Every interface string goes through a message key, with one translation file per language. English is the source language; English and French are maintained by the project and kept complete by CI. Other languages are contributed externally and may be partial: a missing key falls back to English. The API and the judge return codes, never sentences, and the interface translates them.
]

Pedagogical content is not translated by the platform: a statement is displayed in the language its author wrote it in.

= Infrastructure

The infrastructure must be reproducible, versioned and sufficiently independent of manual operations to allow a deployment environment to be rebuilt reliably.

The envisioned architecture distinguishes several levels of responsibility:

#mermaid(
  "
  flowchart TD
    I[Infrastructure]

    I --> T[Terraform]
    I --> VM[ÉTS VM]

    T -.->|Provisioning if available| VM

    VM --> U[Ubuntu LTS]
    A[Ansible] -->|Configuration| U

    U --> SYS[System]
    U --> SEC[Security]
    U --> SVC[Services]

    SVC --> API[API]
    SVC --> J[Judge]

    J --> ISO[gVisor / other isolation mechanisms]
  ",
  document-context: true,
  width: 100%,
)

== Infrastructure provisioning

Terraform is envisioned to describe and provision infrastructure resources when the hosting environment provides a compatible interface.

It could in particular be used to manage:

- virtual machines;
- networks;
- volumes;
- access rules;
- the resources needed for deployment.

However, the infrastructure provided by the institution may not offer an interface allowing Terraform to create or modify these resources directly.

#decision[
  Terraform will be used when the hosting environment allows infrastructure to be provisioned in an automated way. Otherwise, the VM provided by the institution will be considered a resource external to the project.
]

This distinction avoids introducing Terraform artificially into an environment where it would bring no operational value.

== Operating system

The VMs provided by the institution run Ubuntu LTS. NixOS, initially envisioned (ADR-0003), is not retained; see ADR-0006.

Ubuntu does not offer native declarative configuration. The system configuration is therefore described by idempotent Ansible playbooks, versioned with the rest of the project, so that a machine can be rebuilt or added from the repository. An inventory by groups (`web`, `judge`, `db`) describes the VMs; adding one amounts to registering it in the inventory and running a playbook (ADR-0010).

The target model is:

#mermaid(
  "
  flowchart LR
    Git     --> Ansible[Ansible playbooks]
    Ansible --> VM[Ubuntu VM]
    VM      --> A[Reproducible system state]
  ",
  document-context: true,
  width: 100%,
)

The playbooks describe in particular:

- installed packages;
- system services;
- network configuration;
- the firewall;
- the required users and permissions;
- logging mechanisms;
- monitoring services;
- the container runtime;
- the components needed for submission isolation.

#decision[
  The main VM uses Ubuntu LTS, imposed by the institution. Its permanent state is described by the repository's Ansible playbooks.
]

Unlike NixOS, Ubuntu does not keep system generations allowing a return to a previous configuration. This risk is offset by:

- a VM snapshot before each system or platform update;
- pinning the versions of critical packages (container runtime, gVisor, nginx, PostgreSQL);
- limiting `unattended-upgrades` to security fixes, suspended ahead of an exam.

#hypothesis[
  VM snapshots and version pinning can reduce operational risk during platform updates, especially ahead of an assessment period.
]

== Role of Ansible

Ansible is the host configuration mechanism. It covers both the machine's permanent state and one-off operations, for example:

- coordinating an update;
- some deployment operations;
- administrative tasks.

The intended boundary is therefore:

#mermaid(
  "
  flowchart LR
    T[Terraform] --> T1[Infrastructure provisioning]
    A[Ansible]   --> A1[Machine state and operations]
    C[CI/CD]     --> C1[Application build and deployment]
  ",
  document-context: true,
  width: 100%,
)

#decision[
  The system's persistent configuration is declared in the Ansible playbooks. Any manual change to the machine must be carried back into them.
]

Imperative convergence can let the actual state drift from what the repository describes. The playbooks are therefore run regularly in `--check --diff` mode to detect any drift.

== Deployment environment

The target infrastructure should ideally be split into several environments when the available resources allow it:

#mermaid(
  "
  flowchart LR
    I[Infrastructure]

    I --> V[Staging]
    I --> P[Production]

    V --> V1[Tests / CI]
    P --> P1[Teaching / exams]
  ",
  document-context: true,
  width: 100%,
)

The staging environment makes it possible in particular to test a new version of the system, the judge or the isolation mechanisms before using it in a real teaching context.

#hypothesis[
  A separate pre-production environment can be particularly useful before exams, since some changes to the judging system or to isolation can have significant consequences on the platform's availability.
]

= CI/CD

The envisioned pipeline is:

#mermaid(
  "
  flowchart TD
    G[Git push] --> T

    subgraph T[Tests]
      T1[Unit tests]
      T2[Integration tests]
      T3[Security tests]
    end

    T --> B

    subgraph B[Build]
      B1[Web]
      B2[API]
      B3[Judge]
    end

    B --> IMG[Images / artifacts]
    IMG --> REG[Registry / artifact storage]
    REG --> D[Deployment]

    D --> VAL[Staging environment]
    D --> PROD[Production]
  ",
  document-context: true,
  width: 100%,
)

The Ansible configuration must itself be tested (`ansible-lint`, runs in `--check` mode) and versioned in the same development cycle.

The pipeline must in particular make it possible to verify that a change to the system or the application can be built before being deployed.

#decision[
  Deployment must be automated as much as possible and reproducible from the repository. Manual changes to production must be avoided or, when necessary, documented and carried back into the declarative configuration.
]

CI/CD must not, however, automatically deploy any change directly to the environment used for exams.

A distinction must be maintained between:

* automatic validation;
* deployment to pre-production;
* human validation;
* deployment to production.

= Code organization

A monorepo is currently preferred in order to keep a consistent view of the project's various components.

A possible layout is:

```text
log-platform/
│
├── apps/
│   ├── web/
│   ├── api/
│   └── judge/
│
├── packages/
│
├── content/
│
├── infrastructure/
│   ├── ansible/
│   │   ├── site.yml
│   │   ├── inventory/
│   │   └── roles/
│   │
│   └── terraform/
│
├── deployment/
│
├── tests/
│
├── docs/
│
└── .github/
```

The `infrastructure/ansible/` directory contains the configuration of the machines administered by the project as well as the administrative operations.

The `terraform/` directory contains only the resources actually managed by Terraform.

#decision[
  The monorepo is preferred in order to keep a consistent version of the application, the judge engine, the pedagogical content and the infrastructure.
]

Boundaries between components must nevertheless remain explicit.

A monorepo does not mean that all components share the same code, the same language or the same deployment cycle.

= Security

== Defense in depth

Execution security does not rely on the operating system or on a single isolation mechanism.

An execution should ideally cross several layers of protection:

#mermaid(
  "
  flowchart LR
    C[Student code]             --> V[Application validation]
    V                           --> J[Judge]
    J                           --> R[Resource limits]
    R                           --> RT[Container / runtime]
    RT                          --> ISO[gVisor / microVM]
    ISO                         --> H[Ubuntu host]
    H                           --> VM[Institution VM]
  ",
  document-context: true,
  width: 100%,
)

Each layer must reduce the potential consequences of a failure in another layer.

The role of Ubuntu and Ansible in this architecture is mainly to provide a reproducible and manageable system environment. They do not by themselves constitute the isolation boundary for student programs.

== Separation of secrets

The process responsible for running student code should not have access to the application's critical secrets.

In particular, the judge engine should run with the minimum privileges needed to operate.

A possible compromise of an execution environment must therefore not directly yield the credentials giving access to the platform's critical services.

== Separation of responsibilities on the VM

When the available resources allow it, components with different trust levels should be separated.

A possible model is:

#mermaid(
  "
  flowchart TB
    subgraph VM[Ubuntu VM]
        API[Application<br/>API / Web]
        J[Judge]

        subgraph ISO[Isolation]
            S[Sandbox]
            C[Student code]
        end

        J --> S
        S --> C
    end

    API -->|Submission| J
  ",
  document-context: true,
  width: 100%,
)

A stronger physical or virtual separation between the application and the judge engine may be considered if the threat analysis or load constraints justify it.

#validation[
  The distribution of roles (`web`, `judge`, `db`) across the VMs (ADR-0010) will have to be determined based on the available resources, the threat model and the results of the load tests.
]

== Network

Student code normally has no reason to access the Internet or the institution's internal network.

#decision[
  Network access for student programs must be denied by default. An exercise may only declare loopback networking (a namespace with no external interface), for socket exercises such as LOG100 or GTI611 (ADR-0013).
]

Network and firewall configuration must be considered part of the declarative infrastructure and not a manual configuration of the machine.

== Resources

Each execution must have explicit limits concerning in particular:

- CPU time;
- total execution time;
- memory;
- the number of processes and threads;
- temporary disk space;
- network connections;
- accessible files.

These limits must be enforced at the level of the isolated execution mechanism and not only by the student's program.

= Reproducibility

The overall goal of the infrastructure is to be able to answer the question:

> "Can a working and sufficiently identical environment be rebuilt
> from the project's repository?"

The target level of reproducibility is:

#mermaid(
  "
  flowchart LR
    G[Git repository] --> SRC[Application source code]
    G            --> INF[Infrastructure]

    INF --> N[Ansible configuration]
    N   --> VM
    VM  --> SVC[Configured services]
    SVC --> APP[Application]
  ",
  document-context: true,
  width: 100%,
)

Reproducibility does not necessarily mean that every piece of production data must be rebuilt from scratch. Persistent data, secrets and some resources provided by the institution are external dependencies that must be explicitly identified.

#decision[
  The infrastructure must document its external dependencies so that a working configuration does not depend on implicit knowledge held only by an administrator.
]

= Decisions to validate

The following choices remain conditional or will have to be confirmed experimentally:

#table(
  columns: (3.2cm, 5cm, 1fr),
  stroke: 0.5pt,

  [*Topic*], [*Current position*], [*Validation*],

  [Main OS], [Ubuntu LTS (imposed by the institution)], [gVisor compatibility with the provided kernel],

  [Provisioning], [Terraform if a compatible API is available], [Actual capabilities of the ÉTS environment],

  [Configuration], [Ansible playbooks], [Drift detection, VM snapshots and `sudo` access],

  [Runtime], [Docker or Podman], [Compatibility with the isolation mechanism],

  [Isolation], [gVisor initially envisioned], [Benchmark and security tests],

  [Isolation alternative], [Firecracker], [Comparative benchmark],

  [Topology], [Several VMs replicable by Ansible (ADR-0010)], [Load, security and available resources],

  [Reverse proxy], [nginx; `upstream` if several `web` VMs], [TLS handling by the institution],

  [Queue], [PostgreSQL (`SKIP LOCKED`)], [Exam load tests],

  [Cache], [No dedicated service; judge-side cache], [Profiling of a submission's cost],

  [Performance measurement],
  [Instruction counting under QEMU (ADR-0007)],
  [Determinism under load and compatibility with gVisor],

  [Visible tests],
  [Browser for easy languages (ADR-0008)],
  [Load reduction, discrepancies with the judge, Safe Exam Browser],

  [Internationalization],
  [Translation files; English and French complete, others fall back to English (ADR-0011)],
  [CI check on `fr`/`en` keys, fallback, language under SEB],
)

The architecture will be considered stable only after validation of the hypotheses that have a significant impact on the system's security, performance or operability.

= Open questions

Several important questions are deliberately left open.

1. Is PostgreSQL sufficient as a submission queue under an exam load?
2. Which scheduling policy minimizes perceived latency during an
  exam?
3. How many workers are needed for a load of 400 students?
4. How many resources should be allocated to each submission?
5. What is the real cost of gVisor for realistic compilations?
6. Under what conditions does Firecracker become preferable to gVisor?
7. Which strategy effectively limits resource-exhaustion
  attacks?
8. How fine-grained should the language abstraction be?
9. How should language-specific dependencies be managed?
10. How much state should be persisted in PostgreSQL, and for how long? The retention period for submissions, results and logs follows Quebec's _Access to Information Act_ and the ÉTS retention schedule (_Archives Act_); it remains to be confirmed with ÉTS. Purging relies on autovacuum and, if the volume justifies it, on partitioning by date rather than on `VACUUM FULL`.
11. How can recovery be guaranteed after the failure of a worker, a VM or the PostgreSQL primary during an exam? An approach is proposed in ADR-0010.
12. What observability is needed to diagnose an ongoing exam?
13. How can Moodle and Safe Exam Browser be integrated cleanly? SEB verification is proposed in ADR-0009; the handoff from Moodle to the platform through LTI remains to be specified.
14. Which part of the architecture should be common to the different courses? A first answer is given by ADR-0012 and ADR-0014; LOG121 will test it.
15. How is assessment data distributed to the judges when they are spread over several machines: shared mount, copy at publication time or versioned artifact?
16. Is performance graded by a complexity verdict (one reference per exercise) or by a full ranking (one reference per language)? To be settled with the instructor.
17. Is code that does not pass all tests measured? If the last submission fails while an earlier one passed, which one is measured?
18. Which languages does each course support, and which of them can run in the browser? A first inventory is given in the appendix and the tiers in ADR-0013; it remains to be confirmed with each course coordinator.

= Validation methodology

Important decisions must come with a technical justification and, when possible, an experimental validation.

The preferred design cycle is:

#mermaid(
  "
  flowchart LR
    P[Problem]        --> H[Hypothesis]
    H                 --> C[Design]
    C                 --> I[Implementation]
    I                 --> E[Experiment]
    E                 --> M[Measurement]
    M                 --> A[Analysis]
    A                 --> D[Decision]
  ",
  document-context: true,
  width: 100%,
)

This approach avoids choosing a technology solely on the basis of its theoretical characteristics.

It also makes it possible to turn some parts of the project into measurable contributions within the special project.

= Planned evolution of the document

This document is a first snapshot of the architecture.

The following sections should gradually be completed with:

- functional and non-functional requirements;
- a formal threat model;
- the ADRs;
- deployment diagrams;
- protocols between components;
- the definition of the judge engine's interfaces;
- the benchmark methodology;
- experimental results;
- decisions made following the experiments;
- identified limitations;
- conclusions.

= Appendix: course inventory

Courses the platform is designed for, in priority order: LOG200, then LOG121, then the others on request. DEG codes come from the DEG course planning published by ÉTS; languages are to be confirmed with each coordinator.

#table(
  columns: (1.6cm, 1fr, 3.6cm, 3.4cm),
  stroke: 0.5pt,
  [*Course*], [*Title*], [*Languages / tools*], [*Test format*],
  table.cell(colspan: 4)[*Software and IT engineering (LOG/GTI)*],
  [LOG200], [Structures de données et algorithmes], [Full catalog (ADR-0013)], [Standard I/O, performance],
  [LOG121], [Conception orientée objet], [Java], [Unit tests, design questions],
  [LOG100], [Programmation et réseautique en génie logiciel], [C, Python, sockets], [Standard I/O, loopback network],
  [LOG210], [Analyse et conception de logiciels], [Java, TypeScript], [Unit tests],
  [LOG240], [Tests et maintenance], [Java, TypeScript], [Unit tests, coverage],
  [LOG635], [Systèmes intelligents et algorithmes], [Python (NumPy)], [Unit tests],
  [LOG660], [Bases de données de haute performance], [SQL], [SQL],
  [GTI350], [Conception et évaluation des interfaces utilisateurs], [JavaScript], [Unit tests],
  [GTI611], [Réseaux de communication IP], [C, Python], [Loopback network],
  table.cell(colspan: 4)[*General studies department (DEG)*],
  [INF111], [Programmation orientée objet], [Java], [Unit tests],
  [INF130], [Ordinateurs et programmation], [VBA (VB.NET judged)], [Standard I/O],
  [INF136], [Introduction à la programmation en Python], [Python], [Standard I/O, browser],
  [INF147], [Programmation procédurale], [C89], [Standard I/O, unit tests],
  [INF155], [Introduction à la programmation], [C99], [Standard I/O],
  [INF270], [Programmation Web pour le design UX], [HTML, CSS, JavaScript], [Unit tests],
  [TCH009], [Informatique], [C], [Standard I/O],
  [TCH016], [Systèmes d'exploitation et services Internet], [Bash, PowerShell], [Standard I/O],
  [TCH017], [Architecture des ordinateurs], [Pep/8 assembly], [Standard I/O],
  [TCH055], [Bases de données], [Oracle SQL], [SQL (shared Oracle)],
  [TCH056], [Programmation Web], [JavaScript, TypeScript], [Unit tests],
  [TCH057], [Applications mobiles], [Java, Kotlin], [Unit tests, no emulator],
  [TCH099], [Projet intégrateur en informatique], [JavaScript, PHP, Java, Kotlin], [Practice exercises],
)

Out of scope: courses without judged code (GTI510, LOG410, LOG430, LOG795), mobile emulation, Windows commands and Windows Server roles, and multi-service projects.
