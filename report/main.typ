// Rapport technique final. Point d'entrée : typst compile --root . rapport/main.typ
//
// Règle : un chapitre qui existe déjà dans docs/ est INCLUS, jamais recopié.
// Un chapitre propre au rapport reste ici tant qu'il est court, et passe dans
// son propre fichier quand il grossit.
//
// ⚠ Structure provisoire : à aligner sur le « Guide de rédaction du rapport de
// fin d'études » (ACCROS) cité par le plan de cours, qui fait autorité.
#import "../docs/template.typ": document, todo

#show: document.with(
  titre: "Rapport technique final",
  sous-titre: [Plateforme d'apprentissage et d'évaluation de la programmation],
  slug: "rapport",
)

= Introduction

#todo[Contexte, problématique, objectifs et plan du rapport — condensés du plan de projet, sans les recopier.]

= État de l'art

#todo[Juges existants (Judge0, DMOJ, CodeRunner), mécanismes d'isolation, évaluation automatisée en enseignement. Créer docs/etat-de-l-art.typ.]

= Méthodologie

#todo[Processus itératif, cycle hypothèse → mesure → décision, gestion de projet.]

= Exigences

#todo[Exigences identifiées (EF-xx, ENF-xx). Créer docs/requirements.typ.]

= Conception

#[#set heading(offset: 1)
#include "../docs/architecture.typ"]

#[#set heading(offset: 1)
#include "../docs/adr/index.typ"]

= Implémentation

#todo[Ce qui a été réalisé, écarts avec la conception.]

= Expérimentation

#todo[Protocole (écrit AVANT les mesures), environnement, charges. Créer docs/evaluation.typ.]

= Résultats

#todo[Mesures, réponse à chaque hypothèse et validation par identifiant.]

= Discussion

#todo[Interprétation, menaces à la validité, enjeux économiques et sociaux revisités.]

= Conclusion et recommandations

#todo[Rappel du travail, limites, travaux futurs.]

= Annexes

#todo[Matrice de traçabilité exigence → décision → test/expérience → résultat ; glossaire.]
