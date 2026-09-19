// Entry point: typst compile --root . docs/pdf/architecture.typ  (from LOG791/)
#import "../template.typ": document

#show: document.with(
  title: "Platform Architecture",
  subtitle: [Programming Learning and Assessment Platform],
  slug: "architecture",
)

#include "../architecture.typ"
