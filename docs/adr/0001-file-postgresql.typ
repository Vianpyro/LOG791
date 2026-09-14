#import "../template.typ": validation

== ADR-0001 — File de soumissions dans PostgreSQL

*Statut :* accepté, sous réserve de validation par tests de charge. \
*Voir aussi :* architecture, section « File de soumissions ».

=== Contexte

L'application et le moteur de jugement doivent être découplés par une file capable d'absorber les pointes d'un examen (environ 400 étudiants), avec priorités, reprises contrôlées et détection des travaux abandonnés. La plateforme est déployée sur une VM unique aux ressources limitées, où chaque service ajouté prend de la mémoire et du CPU au jugement.

=== Options considérées

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Avantages*], [*Inconvénients*],
  [PostgreSQL (`SKIP LOCKED`, `LISTEN/NOTIFY`)],
  [Aucun service ajouté ; file et état des soumissions dans la même transaction ; priorités et reprises exprimées en SQL.],
  [Débit plafonné par la base ; pas conçu comme broker.],
  [Redis], [Rapide, simple.], [Service de plus ; persistance et transactions séparées de l'état.],
  [RabbitMQ], [Sémantique de file complète.], [Service lourd à opérer pour une seule VM.],
  [Répertoire de spool (CTester)], [Aucune dépendance ; éprouvé en production.], [Un seul hôte ; ordonnancement et équité à réécrire à la main.],
)

=== Décision

La file est implémentée dans PostgreSQL. Les juges tirent les travaux avec `SELECT … FOR UPDATE SKIP LOCKED` et sont réveillés par `LISTEN/NOTIFY`.

=== Conséquences

- La file joue le rôle de répartiteur : la capacité s'ajuste par le nombre de juges, sans load balancer.
- Un travail et son verdict sont écrits de façon atomique avec l'état pédagogique.
- Les juges ont besoin d'un accès à la base. Leurs droits doivent être restreints aux tables de la file (voir le modèle de menace).

#validation(id: "V-0001")[
  Mesurer le débit et la latence de la file sous une charge d'examen simulée. Un broker dédié n'est envisagé que si une limite est mesurée.
]
