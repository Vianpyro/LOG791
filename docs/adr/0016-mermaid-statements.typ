#import "../template.typ": adr, arch, ext, validation

== ADR-0016 — Mermaid diagrams in statements <adr-0016>

*Status:* proposed. Extends #adr("0005"). \
*See also:* #arch("purpose-of-the-document")[architecture], section #arch("mermaid")[Mermaid].

=== Context

Statements and questions (#adr("0015")) are written in Markdown or #ext("typst")[Typst], as in #ext("ctester")[CTester]. Both need diagrams: flowcharts, sequence and class diagrams, state machines, graphs for data structures. #ext("mermaid")[Mermaid] is the syntax instructors already know, and the platform's own documentation uses it through the #ext("merman")[merman] Typst package. Constraints: no CDN and no new windows under Safe Exam Browser, a strict #ext("csp")[content security policy], nothing compiled per request (#arch("typst")[architecture]).

=== Options considered

- *mermaid.js in the browser*: a large library on the student's path, served by the platform, rendering at display time and needing a CSP exception for its inline styles.
- *mermaid-cli at publication time*: faithful rendering, but it drives a headless Chromium, a heavy component in the publishing container.
- *merman at publication time*: a Typst package, already vendored for Typst statements; it runs in the existing sandboxed Typst container.

=== Decision

Mermaid is rendered at publication time by merman, in both formats:

- *Typst*: the course template exposes `mermaid(...)`, as in this documentation.
- *Markdown*: a fenced block tagged `mermaid` is extracted during publishing, wrapped in a one-line Typst document using the course template, and compiled in the same container, with the same limits, as a Typst statement.

Each diagram is delivered as inline SVG, in light and dark, like Typst statements. The Mermaid source is kept as the SVG's `<title>` and `<desc>` text alternative. The rendering cache key includes the merman version.

A diagram type that merman does not support, or a diagram that fails to render, stops publishing and names the exercise and the block; the previous release keeps being served.

=== Consequences

- No diagram library is sent to the browser; diagrams work the same under Safe Exam Browser.
- Only the diagram types supported by merman are available; the list is part of the content repository's validation.
- A Markdown statement with a diagram now depends on the Typst container at publication time.

#validation(id: "V-0016")[
  The same diagram written in a `.md` and a `.typ` statement produces equivalent SVGs. An unsupported diagram type fails validation with the exercise and block named. The student page loads no JavaScript diagram library.
]
