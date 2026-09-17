#import "../template.typ": validation

== ADR-0003 — NixOS pour la configuration de la VM

*Statut :* remplacé par ADR-0006 (l'établissement fournit une VM Ubuntu). \
*Voir aussi :* architecture, section « Infrastructure ».

=== Contexte

L'infrastructure doit pouvoir être reconstruite à partir du dépôt. Dans CTester, la configuration vit dans un rôle Ansible séparé (`VHome`), et plusieurs pannes ne sont apparues qu'en production parce qu'un fait de configuration vivait dans un dépôt et sa dépendance dans un autre.

=== Options considérées

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Avantages*], [*Inconvénients*],
  [NixOS],
  [Configuration déclarative et versionnée ; générations et rollback du système entier.],
  [Courbe d'apprentissage ; peut ne pas être supporté par l'équipe d'infrastructure.],

  [Distribution classique + Ansible],
  [Connue, supportée ; déjà utilisée pour CTester.],
  [Convergence impérative : l'état réel peut dériver de ce que le dépôt décrit.],

  [Distribution classique + images de conteneurs],
  [Application reproductible.],
  [L'hôte (runtime, gVisor, pare-feu) reste configuré à la main.],
)

=== Décision

NixOS est le système privilégié pour la VM principale si l'établissement l'autorise. Ansible n'est conservé que pour l'orchestration qui ne constitue pas l'état permanent d'une machine.

=== Conséquences

- Une seule source de vérité pour l'état d'une machine.
- Le rollback d'une mise à jour système est une génération précédente, ce qui réduit le risque à l'approche d'un examen.
- Si NixOS est refusé, cette décision est remplacée par une nouvelle ADR ; les autres ne dépendent pas d'elle.

#validation(id: "V-0003")[
  Obtenir la position de l'équipe d'infrastructure de l'ÉTS et vérifier la compatibilité de gVisor avec la version de NixOS retenue.
]
