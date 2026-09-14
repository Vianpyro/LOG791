// Point d'entrée : typst compile --root . docs/pdf/architecture.typ  (depuis LOG795/)
#import "../template.typ": document

#show: document.with(
  titre: "Architecture de la plateforme",
  sous-titre: [Plateforme d'apprentissage et d'évaluation de la programmation],
  version: [Version 0 — document de conception initiale],
  slug: "architecture",
)

#include "../architecture.typ"
