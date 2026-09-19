// Final technical report. Entry point: typst compile --root . report/main.typ
//
// Rule: a chapter that already exists in docs/ is INCLUDED, never copied.
// A chapter specific to the report stays here while it is short, and moves to
// its own file when it grows.
//
// ⚠ Provisional structure: to be aligned with the "Guide de rédaction du
// rapport de fin d'études" (ACCROS, https://accros.etsmtl.ca/Rapports/index.asp)
// cited in the course outline, which is authoritative.
#import "../docs/template.typ": document, ext, plan, todo

#show: document.with(
  title: "Final Technical Report",
  subtitle: [Programming Learning and Assessment Platform],
  slug: "report",
)

= Introduction

#todo[Context, problem statement, objectives and outline of the report — condensed from the #plan("context-and-problem-statement")[project plan], not copied.]

= State of the art

#todo[Existing judges (#ext("judge0")[Judge0], #ext("dmoj")[DMOJ], #ext("coderunner")[CodeRunner]), isolation mechanisms, automated assessment in education. Create docs/state-of-the-art.typ.]

= Methodology

#todo[Iterative process, hypothesis → measurement → decision cycle, project management.]

= Requirements

#todo[Identified requirements (FR-xx, NFR-xx). Create docs/requirements.typ.]

= Design

#[#set heading(offset: 1)
#include "../docs/architecture.typ"]

#[#set heading(offset: 1)
#include "../docs/adr/index.typ"]

= Implementation

#todo[What was built, deviations from the design.]

= Experimentation

#todo[Protocol (written BEFORE the measurements), environment, loads. Create docs/evaluation.typ.]

= Results

#todo[Measurements, answer to each hypothesis and validation by identifier.]

= Discussion

#todo[Interpretation, threats to validity, economic and social stakes revisited.]

= Conclusion and recommendations

#todo[Summary of the work, limitations, future work.]

= Appendices

#todo[Traceability matrix requirement → decision → test/experiment → result; glossary.]
