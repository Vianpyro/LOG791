// Entry point: typst compile --root . docs/pdf/project-plan.typ  (from LOG791/)
#import "../template.typ": document

#show: document.with(
  title: "Project Plan",
  subtitle: [Programming Learning and Assessment Platform],
  supervisors: ([Patrick Cardinal],),
  slug: "project-plan",
)

#include "../project-plan.typ"
