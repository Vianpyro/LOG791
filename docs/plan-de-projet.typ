// Plan de projet — sections exigées par le plan de cours LOG791 (A2026).
// Dû à la 2e semaine. Contenu seul ; point d'entrée : pdf/plan-de-projet.typ
#import "template.typ": todo

= Contexte et problématique

CTester est une plateforme d'évaluation automatisée de programmes en C développée pour le cours TCH009 et utilisée en production : les étudiants y écrivent, compilent et soumettent du code jugé par des tests exécutés dans un bac à sable gVisor. Elle a été conçue pour un seul cours, un seul langage et une seule machine.

Le cours LOG200 souhaite disposer d'une plateforme comparable, avec des contraintes que CTester ne couvre pas : plusieurs langages, des évaluations supervisées pouvant réunir environ 400 étudiants, une intégration avec Moodle et Safe Exam Browser, et un hébergement sur l'infrastructure de l'ÉTS.

*Problème d'ingénierie.* Comment concevoir une plateforme capable d'exécuter du code non fiable dans plusieurs langages, de supporter la charge d'un examen supervisé et de demeurer réutilisable d'un cours à l'autre, sur une infrastructure aux ressources limitées ?

Le problème combine quatre dimensions en tension : la *sécurité* (le code soumis est potentiellement hostile), la *performance* (des pointes de soumissions concentrées dans le temps), la *pédagogie* (rétroaction utile, confidentialité des tests) et l'*opérabilité* (une infrastructure reproductible, maintenable au-delà du projet).

#todo[Faire valider la formulation du problème par les professeurs attitrés (indicateur Q4-I1).]

= Objectifs du projet

+ Concevoir et justifier une architecture séparant l'application pédagogique du moteur de jugement.
+ Implémenter un moteur de jugement multi-langage dont l'isolation est indépendante du langage.
+ Évaluer expérimentalement au moins deux mécanismes d'isolation (gVisor, Firecracker) sur une charge réaliste.
+ Démontrer que la plateforme tient une charge d'examen simulée de 400 étudiants, avec des seuils de latence définis à l'avance.
+ Rendre l'infrastructure reconstructible à partir du dépôt.

#todo[Associer à chaque objectif un critère de réussite mesurable (seuils de latence P95, taux d'échec toléré, etc.).]

= Méthodologie

Le projet suit un processus itératif : chaque itération part d'une hypothèse d'architecture, l'implémente dans la mesure nécessaire pour la mesurer, puis consigne la décision dans une ADR.

#todo[Nommer le modèle reconnu retenu (OpenUP est recommandé par le plan de cours), la durée des itérations et les jalons (revue de conception, rapport d'avancement).]

= Composition de l'équipe et rôles

#todo[Membres, chef d'équipe (responsable de l'échéancier, des ordres du jour et des comptes rendus, avec des tâches techniques), rôles et rotation éventuelle.]

= Mandat et livrables

#table(
  columns: (4.5cm, 1fr),
  stroke: 0.5pt,
  [*Livrable*], [*Contenu*],
  [Plan de projet], [Le présent document (2#super[e] semaine).],
  [Document d'architecture et ADR], [Conception de haut niveau et justification des choix.],
  [Modèle de menace], [Actifs, frontières de confiance, menaces et contre-mesures.],
  [Prototype], [Application, moteur de jugement et isolation déployables.],
  [Protocole et résultats d'évaluation], [Benchmarks reproductibles et analyse.],
  [Rapport technique final], [Deux jours après la présentation orale.],
  [Présentation orale], [Période des examens finaux.],
)

#todo[Préciser le client (cours LOG200, responsable), ce qui lui est remis, et les éléments du contrat d'encadrement.]

= Enjeux économiques et sociaux

*Économiques.*
- Coût d'hébergement : l'utilisation d'une VM de l'établissement évite un coût infonuagique récurrent, mais contraint les ressources ; l'architecture n'ajoute un service que sur un besoin mesuré.
- Coût d'exploitation : une plateforme développée localement doit rester maintenable après le projet. La reproductibilité de l'infrastructure réduit la dépendance à une seule personne.
- Licences : les composants envisagés (PostgreSQL, gVisor, Firecracker, Ubuntu, Ansible, FastAPI) sont libres, sans coût de licence.

*Sociaux et éthiques.*
- Confidentialité : la plateforme traite des renseignements personnels (identité, code, résultats) et est soumise à la Loi 25 du Québec. Minimisation des données, droit à l'effacement et absence d'identifiants dans les échanges non nécessaires.
- Équité des évaluations : une panne ou une latence inégale pendant un examen désavantage certains étudiants ; d'où la capacité réservée aux examens.
- Intégrité académique : confidentialité des tests privés et environnement contrôlé (Safe Exam Browser).
- Accessibilité : les énoncés et l'interface doivent rester utilisables avec des technologies d'assistance.
- Développement durable : partage d'une VM existante plutôt que provisionnement de ressources dédiées ; mesure de la consommation pendant les benchmarks.

#todo[Compléter avec les parties prenantes (étudiants, enseignants, service TI) et valider (indicateur Q9-I1).]

= Analyse des solutions techniques

L'analyse détaillée est consignée dans le document d'architecture et les ADR. Synthèse :

#table(
  columns: (3cm, 1fr, 3.2cm),
  stroke: 0.5pt,
  [*Question*], [*Solutions considérées*], [*Retenue*],
  [Isolation], [conteneur seul, gVisor, Firecracker, WebAssembly], [gVisor, comparé à Firecracker (ADR-0002)],
  [File], [PostgreSQL, Redis, RabbitMQ, spool fichiers], [PostgreSQL (ADR-0001)],
  [Système], [NixOS, distribution + Ansible, conteneurs seuls], [Ubuntu + Ansible (imposé, ADR-0006)],
  [Moteur], [Python, Rust], [À décider par profilage],
  [Contenu], [base de données, copie servie, releases immuables], [Releases (ADR-0005)],
  [Faire ou réutiliser], [étendre CTester, adopter un juge existant (DMOJ, Judge0), nouvelle plateforme], [À justifier],
)

#todo[Comparer explicitement aux juges existants (Judge0, DMOJ, CodeRunner pour Moodle) : c'est la question « pourquoi ne pas réutiliser » que le jury posera (indicateur Q4-I2).]

= Requis, contraintes et exclusions

*Requis de haut niveau.* Exécution isolée de code non fiable ; plusieurs langages ; soumission et verdict structuré ; confidentialité des tests ; mode examen avec capacité réservée ; authentification institutionnelle ; intégration Moodle.

*Contraintes.* Hébergement sur l'infrastructure de l'ÉTS ; ressources d'une VM ; environ 400 étudiants en examen ; données personnelles au Québec ; 180 heures par membre.

*Exclusions.*
#todo[Décider ce qui est hors du périmètre du PFE : fonctionnalités sociales (forum, chat), gamification, édition collaborative, plagiat, interface d'édition du contenu.]

= Planification sommaire

#todo[Itérations et jalons datés : plan de projet (semaine 2), revue de conception, rapport d'avancement, gel des fonctionnalités, campagne de benchmarks, rapport final, présentation.]

= Registre des risques

#table(
  columns: (0.9cm, 1fr, 1.4cm, 1.4cm, 1fr),
  stroke: 0.5pt,
  [*ID*], [*Risque*], [*Prob.*], [*Impact*], [*Mitigation*],
  [R1], [La VM de l'ÉTS n'est pas disponible à temps ou ne permet pas KVM.], [Moy.], [Élevé], [Environnement de validation reproductible hors ÉTS ; gVisor ne demande pas KVM.],
  [R2], [Évasion du bac à sable par du code hostile.], [Faible], [Critique], [Défense en profondeur, pas de réseau, pas de secrets dans le juge, tests hostiles en CI.],
  [R3], [Charge d'examen non tenue.], [Moy.], [Élevé], [Benchmarks tôt ; capacité réservée ; contre-pression.],
  [R4], [Portée trop large pour 180 heures.], [Élevée], [Élevé], [Exclusions explicites ; prototypage centré sur le jugement.],
  [R5], [Intégration Moodle / SEB bloquée par des accès administratifs.], [Moy.], [Moy.], [Démarches dès le début ; intégration traitée comme optionnelle si bloquée.],
  [R6], [Mesures non représentatives (charge synthétique, VM partagée).], [Moy.], [Moy.], [Protocole écrit avant les mesures ; menaces à la validité documentées.],
  [R7], [Non-conformité aux règles de confidentialité.], [Faible], [Élevé], [Minimisation des données ; revue avec l'établissement.],
)

= Technologies

Python/FastAPI (API), PostgreSQL (état et file), Rust envisagé (moteur de jugement), gVisor et Firecracker (isolation), Docker ou Podman (runtime), Ubuntu LTS et Ansible (système), nginx (entrée), Microsoft Entra ID (authentification), Typst (énoncés et documentation), GitHub Actions (CI).

= Références

#todo[Bibliographie (fichier `.bib`) : gVisor, Firecracker, juges existants, littérature sur l'évaluation automatisée de programmes.]
