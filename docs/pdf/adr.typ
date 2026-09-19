// Entry point: typst compile --root . docs/pdf/adr.typ  (from LOG791/)
#import "../template.typ": document

#show: document.with(
  title: "Architecture Decision Records",
  subtitle: [Programming Learning and Assessment Platform],
  slug: "adr",
)

#include "../adr/index.typ"
