#import "../template.typ": validation

== ADR-0006 — Ubuntu et Ansible pour la configuration de la VM

*Statut :* accepté. Remplace ADR-0003. \
*Voir aussi :* architecture, section « Infrastructure ».

=== Contexte

L'établissement fournit une VM sous Ubuntu LTS ; NixOS (ADR-0003) n'est pas retenu. L'infrastructure doit malgré tout pouvoir être reconstruite à partir du dépôt, et les pannes de CTester dues à une configuration répartie entre plusieurs dépôts ne doivent pas se reproduire.

=== Options considérées

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Avantages*], [*Inconvénients*],
  [Ubuntu + Ansible dans le monorepo],
  [Connu, supporté par l'établissement ; déjà utilisé pour CTester ; versionné avec l'application.],
  [Convergence impérative : l'état réel peut dériver ; pas de rollback système natif.],

  [Ubuntu + images de conteneurs seules],
  [Application reproductible.],
  [L'hôte (runtime, gVisor, pare-feu) reste configuré à la main.],
)

=== Décision

Ubuntu LTS, configuré par des playbooks Ansible idempotents versionnés dans le monorepo. Ansible porte tout l'état permanent de l'hôte : paquets, runtime de conteneurs, gVisor (`runsc` via le dépôt apt officiel), pare-feu, nginx et certbot, utilisateurs, journalisation.

=== Conséquences

- Une seule source de vérité pour l'état d'une machine : les playbooks du dépôt. Toute modification manuelle y est répercutée.
- La dérive est détectée en exécutant régulièrement les playbooks en mode `--check --diff`.
- Sans générations système, le rollback repose sur un snapshot de la VM avant chaque mise à jour et sur des versions de paquets épinglées.
- `unattended-upgrades` est limité aux correctifs de sécurité et suspendu à l'approche d'un examen.

#validation(id: "V-0006")[
  Confirmer avec l'équipe d'infrastructure de l'ÉTS la disponibilité des snapshots de VM et l'accès `sudo` pour Ansible ; vérifier le fonctionnement de gVisor sur le noyau Ubuntu fourni.
]
