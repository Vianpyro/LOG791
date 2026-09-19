#import "../template.typ": validation

== ADR-0013 — Language packs and test runners

*Status:* proposed. Applies ADR-0014. \
*See also:* architecture, sections "Multi-language abstraction" and "Language catalog".

=== Context

LOG200 wants as many languages as possible, prioritized by industry use and its expected trend, with the union of the LeetCode and CodinGame catalogs as the horizon. The other courses add specific toolchains: C89 and C99, Pep/8 assembly, Bash, Oracle SQL, Java and Kotlin. Maintaining thirty languages alone is only possible if a language is data rather than code.

=== Options considered

- *Languages hard-coded in the judge*: each language adds branches to the core.
- *A generic "run any command" runner*: no conformance guarantee and no declared capability.
- *Declarative language packs and a small set of test runners*.

=== Decision

*Language pack.* A directory per language describing: the image (built in CI, pinned), the compile and run commands, the language version and options (for C, the standard `c89`, `c99` or `c11` is an option chosen by the exercise, not a separate pack), default limits with a time multiplier (the JVM, .NET and Kotlin start slowly), and capabilities: runnable in the browser (ADR-0008), measurable by instruction counting (ADR-0007). A pack is accepted when its conformance suite passes: a correct solution, a timeout, a memory overrun and a hostile program.

*Tiers.*

#table(
  columns: (3cm, 1fr, 3cm),
  stroke: 0.5pt,
  [*Tier*], [*Languages*], [*When*],
  [P1], [Python 3, Java, C, C++, JavaScript, TypeScript, C\#, Go, Rust, Kotlin], [With LOG200],
  [P2], [PHP, Ruby, Swift, Dart, Scala, Bash, SQL (PostgreSQL)], [After load validation],
  [P3], [Haskell, OCaml, Elixir, Erlang, Racket, Clojure, Lua, Perl, F\#, Groovy, VB.NET, Pascal, D, Objective-C, Pep/8], [On request or contribution],
)

P1 images are preloaded on every judge; P2 and P3 images are pulled on first use, never during an exam.

*Test runners.* The judge only knows the contract "exercise and artifact in, JSON report out". Three runners:

- *Standard I/O* (CodinGame style): the default for LOG200, since one set of tests is valid for every language. A function-signature harness (LeetCode style) requires a driver per language and is added per exercise only if needed.
- *Unit tests*: JUnit, pytest and a C framework, for LOG121 and courses testing classes or functions.
- *SQL*: queries run against a disposable environment provided by a judging service: an ephemeral PostgreSQL inside the sandbox, or, for Oracle (TCH055), a schema created then dropped on a shared Oracle instance outside the sandbox, with quotas and a time limit, since one Oracle instance per submission is too heavy.

*Network.* Denied by default. An exercise may declare loopback-only networking (a namespace with no external interface) for socket exercises (LOG100, GTI611).

*Out of scope.* Mobile emulation (a WebAssembly emulator may be considered later), Windows commands and Windows Server roles, which do not run in a Linux sandbox (PowerShell 7 on Linux covers part of the commands), VBA, which only exists inside Office (VB.NET is the closest judgeable language), and multi-service projects.

=== Consequences

- Adding a language is a directory and a passing conformance suite, without changing the judge.
- Instruction counting is reliable for compiled languages and noisy for JIT or garbage-collected languages; a pack that declares itself unmeasurable gets a complexity verdict against a reference in the same language only.
- The judge image footprint grows with P1; the shared base layer must be kept small.
- The shared Oracle instance is a component outside the sandbox and must be isolated from the application's database and secrets.

#validation(id: "V-0013")[
  Each P1 pack passes its conformance suite under gVisor; the same LOG200 standard I/O exercise is judged identically in every P1 language; two concurrent SQL submissions cannot see each other's schema; a loopback-only exercise cannot reach the outside network.
]
