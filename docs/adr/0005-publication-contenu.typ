== ADR-0005 — Publication du contenu par releases immuables

*Statut :* accepté, repris de CTester où il est en production. \
*Voir aussi :* architecture, section « Cycle de vie du contenu ».

=== Contexte

Le contenu d'un exercice mêle des données publiques (énoncé, gabarits) et des données d'évaluation privées (tests, cas, réponses). Il est modifié en cours de session, parfois pendant une séance, et une erreur de publication peut exposer un corrigé ou retirer un exercice du menu la veille d'un cours.

=== Options considérées

- *Contenu en base, édité dans l'application* : interface d'édition, mais données privées dans le processus exposé à Internet et historique à construire.
- *Copie du dépôt de contenu servie telle quelle* : simple, mais une seule erreur de filtrage expose les données d'évaluation.
- *Projection publique en releases immuables* : validation avant écriture, liste positive de champs publiés, révision adressée par contenu, pointeur de release active.

=== Décision

Le contenu est publié par projection en releases immuables. La release active est désignée par un pointeur, et le moteur de jugement lit les données d'évaluation directement dans le dépôt de contenu après avoir revalidé l'ouverture de l'exercice.

=== Conséquences

- Le rollback du contenu est une réécriture de pointeur, sans redéploiement.
- L'API ne peut exposer que ce que la projection a écrit.
- Les énoncés Typst sont compilés à la publication ; rien ne compile à la requête.
- L'édition passe par Git : l'équipe enseignante doit être à l'aise avec ce flux, ou un outil d'édition devra le produire.
