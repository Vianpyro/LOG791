#import "../template.typ": validation

== ADR-0010 — Plusieurs VM répliquables et tolérantes aux pannes

*Statut :* proposé. Précise ADR-0001 et ADR-0006, qui supposaient une VM unique. \
*Voir aussi :* architecture, sections « Couche d'entrée » et « Infrastructure ».

=== Contexte

Le MVP vise environ 50 élèves. La plateforme doit ensuite servir tous les enseignants du département LOG/TI de l'ÉTS et leurs groupes, ainsi qu'une partie du DEG. À cette échelle, il est peu probable que l'établissement fournisse une seule grosse VM. De plus, une VM unique est un point de défaillance unique : une panne pendant un examen touche tous les étudiants au pire moment.

=== Options considérées

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Avantages*], [*Inconvénients*],
  [Une VM unique agrandie],
  [Aucune coordination entre machines.],
  [Point de défaillance unique ; taille bornée par ce que l'ÉTS fournit.],

  [Plusieurs VM configurées par les mêmes rôles Ansible],
  [Capacité ajoutée VM par VM ; une VM perdue n'arrête pas le service.],
  [Réplication de la base et répartition HTTP à opérer.],
)

=== Décision

Plusieurs VM Ubuntu identiques par rôle, décrites dans un inventaire Ansible par groupes (`web`, `judge`, `db`). Ajouter ou remplacer une VM se fait en l'ajoutant à l'inventaire puis en exécutant un seul playbook.

- *Juges* : sans état et interchangeables. Ils tirent les travaux de la file PostgreSQL ; un travail abandonné par un juge en panne est repris par un autre (ADR-0001). La perte d'un juge réduit la capacité sans perdre de soumission.
- *Base de données* : seul composant avec état. Un réplica PostgreSQL en attente chaude (réplication en continu) peut être promu en cas de panne du primaire, avec des sauvegardes régulières hors de la VM.
- *API web* : sans état. Si plusieurs VM `web` sont nécessaires, un bloc `upstream` nginx répartit la charge entre elles et écarte une instance défaillante. Ce choix sera tranché d'après les tests de charge.

=== Conséquences

- Une panne de VM en cours d'examen dégrade le service sans l'interrompre ni perdre de soumission, à condition que chaque rôle ait au moins deux instances.
- Les playbooks d'ADR-0006 deviennent multi-hôtes ; la reproductibilité à partir du dépôt est aussi le mécanisme de remplacement d'une machine.
- Le MVP (50 élèves) peut rester sur une ou deux VM ; la topologie est la même, seul l'inventaire change.
- La bascule de la base et la répartition HTTP sont à tester avant chaque période d'examen.

#validation(id: "V-0010")[
  Confirmer avec l'équipe d'infrastructure de l'ÉTS le nombre de VM disponibles, la possibilité d'une IP flottante (ou d'un répartiteur fourni par l'établissement) et l'emplacement des sauvegardes ; simuler la perte d'un juge et du primaire PostgreSQL pendant un test de charge.
]
