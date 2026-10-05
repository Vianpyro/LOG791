#import "../template.typ": adr, arch, ext, validation

== ADR-0028 — LaTeX statements <adr-0028>

*Status:* proposed. Extends #adr("0005"); applies #adr("0023"). \
*See also:* #arch("purpose-of-the-document")[architecture], section #arch("statement-rendering")[Statement rendering]; #adr("0016").

=== Context

Statements are written in Markdown or #ext("typst")[Typst] (#arch("statement-rendering")[Statement rendering]). Most instructors in engineering and computing already write #ext("latex")[LaTeX], and few know Typst: asking them to learn a new language before writing a table or an aligned formula works against adoption. Existing course material and #ext("moodle")[Moodle] question banks are in LaTeX too.

LaTeX is also the riskiest of the three formats to accept from an untrusted author (#adr("0023")):

- TeX is a Turing-complete macro language whose primitives read and write files (`\input`, `\openin`, `\openout`) and, with shell escape, run commands (`\write18`);
- a TeX engine produces PDF or DVI, not HTML: its output reaches the page as SVG glyphs, with the accessibility limitation of Typst's SVG (#arch("typst")[Typst]);
- a #ext("texlive")[TeX Live] distribution weighs several gigabytes in the rendering image.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Pros*], [*Cons*],
  [Markdown and Typst only, LaTeX math syntax in formulas],
  [Nothing new to operate.],
  [Every existing document has to be rewritten; tables and environments stay out of Markdown.],

  [TeX engine at publication time, DVI to SVG],
  [Faithful rendering, any package, TikZ.],
  [Runs author code outside the sandbox's job model; SVG only, not accessible; TeX Live in the image.],

  [#ext("pandoc")[pandoc] at publication time, LaTeX to HTML],
  [No TeX is executed; HTML with #ext("mathml")[MathML], accessible; one static binary.],
  [Only a subset of LaTeX: no TikZ, no arbitrary package.],
)

=== Decision

A statement may be written in LaTeX, as `statement.tex`. An exercise still has exactly one statement file: two formats for the same exercise fail validation (#arch("validation")[Validation]).

*Rendering.* pandoc converts the statement to HTML at publication time, formulas to MathML: no TeX engine runs, so `\write18`, `\openout` and shell escape have nothing to act on. It runs in the existing rendering container under #ext("gvisor")[gVisor], without network, on a copy that contains only `statement.tex`, with pandoc's `--sandbox` (no read beyond the files named on the command line, so `\input` and `\include` read nothing), a timeout and a memory limit. The output goes through the same allow-list sanitizer as Typst's (#adr("0023")).

*Body only.* As with Typst, the author writes no preamble: `statement.tex` holds the body. `\documentclass`, `\usepackage`, `\input` and `\include` are refused, naming the exercise and the line.

*Nothing is dropped silently.* pandoc skips the LaTeX it cannot convert. Its machine-readable log (`--log`) is read after every conversion, and any skipped command or environment stops publishing, naming the exercise and the command. The previous release keeps being served (#adr("0005")).

*Supported subset.* What Markdown covers, plus what instructors use LaTeX for in a statement: sections, lists, emphasis, `verbatim` and `lstlisting` code blocks, `tabular` tables, inline and display math (`align`, `cases`, matrices), and macros defined in the statement with `\newcommand`. Images are not supported, as in Markdown. Diagrams are written in #ext("mermaid")[Mermaid] in a `mermaid` environment, extracted and rendered like a fenced Markdown block (#adr("0016")); TikZ is refused. A statement that needs more is written in Typst.

*Cache.* The rendering cache key includes the pandoc version, as it includes Typst's (#arch("typst")[Typst]).

=== Consequences

- Instructors write statements in a language they know; the supported subset is documented in the operations guide, and an unsupported command is reported at publication, not discovered by students.
- A third renderer to operate: pandoc is added to the rendering image, TeX Live is not.
- LaTeX statements are fully accessible: HTML text and MathML, with no SVG fallback.
- Fidelity is pandoc's, not TeX's: page layout, spacing and custom packages are not reproduced. A course that needs TikZ or a specific package writes those statements in Typst, or a later ADR reconsiders a TeX engine.
- Item text fields (#adr("0015")) stay in Markdown or Typst; LaTeX applies to exercise statements.

#validation(id: "V-0028")[
  A statement using `\begin{tikzpicture}`, an unknown environment or `\usepackage` stops publication, naming the exercise and the command. `\input{/etc/passwd}` and `\openin` read nothing. `\write18` has no effect. A self-recursive macro hits the timeout and stops this course's publication only. An `\href` to a `javascript:` URL is neutralized by the sanitizer. The same statement written in `.md` and `.tex` gives equivalent HTML for the constructs both support, and its formulas are read by a screen reader. An exercise with both `statement.md` and `statement.tex` fails validation.
]
