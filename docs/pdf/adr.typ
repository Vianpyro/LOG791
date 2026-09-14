// Point d'entrée : typst compile --root . docs/pdf/adr.typ  (depuis LOG795/)
#import "../template.typ": document

#show: document.with(
  titre: "Décisions d'architecture",
  sous-titre: [Plateforme d'apprentissage et d'évaluation de la programmation],
  slug: "adr",
)

#include "../adr/index.typ"
