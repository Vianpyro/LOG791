// Point d'entrée : typst compile --root . docs/pdf/plan-de-projet.typ  (depuis LOG791/)
#import "../template.typ": document

#show: document.with(
  titre: "Plan de projet",
  sous-titre: [Plateforme d'apprentissage et d'évaluation de la programmation],
  superviseurs: [Patrick Cardinal],
  slug: "plan-de-projet",
)

#include "../plan-de-projet.typ"
