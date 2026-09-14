== ADR-0004 — Monorepo pour le code, l'infrastructure et la documentation

*Statut :* accepté. \
*Voir aussi :* architecture, section « Organisation du code ».

=== Contexte

La plateforme comprend une interface web, une API, un moteur de jugement, une configuration d'infrastructure et une documentation de conception. Dans CTester, l'application et son déploiement vivent dans deux dépôts, et les droits de la base de données ont dû être rapatriés dans le dépôt applicatif après trois pannes de désynchronisation.

=== Options considérées

- *Monorepo* : une version cohérente de tous les composants, une seule CI, changements transverses atomiques.
- *Un dépôt par composant* : cycles de publication indépendants, mais compatibilité à coordonner à la main.

=== Décision

Un monorepo est retenu pour l'application, le juge, l'infrastructure et la documentation.

Le *contenu pédagogique* reste dans un dépôt distinct : il contient les données d'évaluation privées, il est modifié par l'équipe enseignante et il est publié sans redéploiement (voir « Cycle de vie du contenu »).

=== Conséquences

- Les frontières entre composants doivent rester explicites : un monorepo ne signifie ni un langage commun, ni un cycle de déploiement commun.
- La CI doit construire et tester sélectivement les composants modifiés.
