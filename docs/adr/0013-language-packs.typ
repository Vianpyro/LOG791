#import "../template.typ": adr, arch, course, ext, validation

== ADR-0013 — Language packs and test runners <adr-0013>

*Status:* proposed. Applies #adr("0014"). \
*See also:* #arch("purpose-of-the-document")[architecture], sections #arch("multi-language-abstraction")[Multi-language abstraction] and #arch("language-catalog")[Language catalog].

=== Context

#course("LOG200") wants as many languages as possible, prioritized by industry use and its expected trend, with the union of the #ext("leetcode")[LeetCode] and #ext("codingame")[CodinGame] catalogs as the horizon. The other courses add specific toolchains: C89 and C99, #ext("pep8")[Pep/8] assembly, Bash, #ext("oracle")[Oracle] SQL, Java and Kotlin. Maintaining thirty languages alone is only possible if a language is data rather than code.

=== Options considered

- *Languages hard-coded in the judge*: each language adds branches to the core.
- *A generic "run any command" runner*: no conformance guarantee and no declared capability.
- *Declarative language packs and a small set of test runners*.

=== Decision

*Language pack.* A directory per language describing: the image (built in CI, pinned), the compile and run commands, the language version and options (for C, the standard `c89`, `c99` or `c11` is an option chosen by the exercise, not a separate pack), default limits with a time multiplier (the JVM, .NET and Kotlin start slowly), and capabilities: runnable in the browser (#adr("0008")), measurable by instruction counting (#adr("0007")). A pack is accepted when its conformance suite passes: a correct solution, a timeout, a memory overrun and a hostile program.

*Tiers.*

#table(
  columns: (3cm, 1fr, 3cm),
  stroke: 0.5pt,
  [*Tier*], [*Languages*], [*When*],
  [P1], [Python 3, Java, C, C++, JavaScript, TypeScript, C\#, Go, Rust, Kotlin], [With LOG200],
  [P2], [PHP, Ruby, Swift, Dart, Scala, Bash, SQL (#ext("postgresql")[PostgreSQL])], [After load validation],
  [P3], [Haskell, OCaml, Elixir, Erlang, Racket, Clojure, Lua, Perl, F\#, Groovy, VB.NET, Pascal, D, Objective-C, Pep/8], [On request or contribution],
)

P1 images are preloaded on every judge; P2 and P3 images are pulled on first use, never during an exam.

*Judges and sandboxes.* Judges are generic: every judge holds every P1 image, and jobs are not routed to judges by language. Each submission gets its own sandbox, created from its pack's image only. The language is known from the submission, so choosing the image costs nothing. An image on disk uses no memory; only running sandboxes do. Concurrency per judge is therefore bounded by the sandboxes running, not by the number of installed languages. Specialized judges (Java-only VMs, for example) would split capacity: a burst in one language would wait while judges for other languages sit idle. Pre-started sandboxes per language may be kept to hide startup time; their number is sized from the observed language mix, since each one holds memory while idle.

*Test runners.* The judge only knows the contract "exercise and artifact in, JSON report out". Three runners:

- *Standard I/O* (CodinGame style): the default for LOG200, since one set of tests is valid for every language. A function-signature harness (LeetCode style) requires a driver per language and is added per exercise only if needed.
- *Unit tests*: #ext("junit")[JUnit], #ext("pytest")[pytest] and a C framework, for #course("LOG121") and courses testing classes or functions.
- *SQL*: queries run against a disposable environment provided by a judging service: an ephemeral PostgreSQL inside the sandbox, or, for Oracle (#course("TCH055")), a schema created then dropped on a shared Oracle instance outside the sandbox, with quotas and a time limit, since one Oracle instance per submission is too heavy.

*Network.* Denied by default. An exercise may declare loopback-only networking (a namespace with no external interface) for socket exercises (#course("LOG100"), #course("GTI611")).

*Out of scope.* Mobile emulation (a WebAssembly emulator may be considered later), Windows commands and Windows Server roles, which do not run in a Linux sandbox (#ext("powershell-linux")[PowerShell 7] on Linux covers part of the commands), VBA, which only exists inside Office (VB.NET is the closest judgeable language), and multi-service projects.

=== Consequences

- Adding a language is a directory and a passing conformance suite, without changing the judge.
- Instruction counting is reliable for compiled languages and noisy for JIT or garbage-collected languages; a pack that declares itself unmeasurable gets a complexity verdict against a reference in the same language only.
- The judge image footprint grows with P1; the shared base layer must be kept small.
- The shared Oracle instance is a component outside the sandbox and must be isolated from the application's database and secrets.

#validation(id: "V-0013")[
  Each P1 pack passes its conformance suite under #ext("gvisor")[gVisor]; the same LOG200 standard I/O exercise is judged identically in every P1 language; two concurrent SQL submissions cannot see each other's schema; a loopback-only exercise cannot reach the outside network. For each P1 language under gVisor, measure cold and pre-started sandbox startup time and the idle memory of one pre-started sandbox, then the maximum number of concurrent sandboxes per judge under a mixed-language load.
]
