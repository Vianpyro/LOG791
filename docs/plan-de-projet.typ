// Plan de projet — LOG791 (projet spécial, A2026), réalisé seul sous la supervision du professeur attitré.
// Contenu seul ; point d'entrée : pdf/plan-de-projet.typ
#import "template.typ": todo

= Contexte et problématique

CTester est une plateforme d'évaluation automatisée de programmes en C développée pour le cours TCH009 et utilisée en production : les étudiants y écrivent, compilent et soumettent du code jugé par des tests exécutés dans un bac à sable gVisor. Elle a été conçue pour un seul cours, un seul langage et une seule machine.

Le cours LOG200 souhaite disposer d'une plateforme comparable, avec des contraintes que CTester ne couvre pas : plusieurs langages, des évaluations supervisées où une panne est critique, une intégration avec Moodle et Safe Exam Browser, et un hébergement sur l'infrastructure de l'ÉTS. Le MVP vise environ 50 élèves ; à terme, la plateforme doit servir tous les enseignants du département LOG/TI et leurs groupes, ainsi qu'une partie du DEG.

*Problème.* Comment concevoir une plateforme capable d'exécuter du code non fiable dans plusieurs langages, de supporter la charge d'un examen supervisé et de demeurer réutilisable d'un cours à l'autre, sur une infrastructure aux ressources limitées ?

#todo[Faire valider la formulation du problème par le professeur attitré.]

= Objectifs

+ Concevoir et justifier une architecture séparant l'application pédagogique du moteur de jugement.
+ Implémenter un moteur de jugement multi-langage dont l'isolation est indépendante du langage.
+ Démontrer que la plateforme tient une charge d'examen simulée de 400 étudiants, avec des seuils de latence définis à l'avance.
+ Rendre l'infrastructure reconstructible à partir du dépôt.

#todo[Associer à chaque objectif un critère de réussite mesurable (latence P95, taux d'échec toléré).]

= Encadrement et méthode

Projet individuel supervisé par le professeur attitré. Le travail avance par itérations courtes : chaque itération implémente ce qu'il faut pour valider une hypothèse d'architecture, puis consigne la décision dans une ADR. Un suivi régulier avec le professeur sert de point de contrôle.

#todo[Fixer la fréquence des rencontres de suivi.]

= Livrables

#table(
  columns: (4.5cm, 1fr),
  stroke: 0.5pt,
  [*Livrable*], [*Contenu*],
  [Plan de projet], [Le présent document.],
  [Architecture et ADR], [Conception de haut niveau et justification des choix, incluant le modèle de menace.],
  [Prototype], [Application, moteur de jugement et isolation déployables.],
  [Rapport final], [Démarche, résultats des mesures et recommandations pour LOG200.],
)

#todo[Confirmer les livrables et échéances exigés avec le professeur attitré.]

= Portée

*Requis.* Exécution isolée de code non fiable ; plusieurs langages ; soumission et verdict structuré ; confidentialité des tests ; mode examen avec capacité réservée ; authentification institutionnelle.

*Contraintes.* Hébergement sur l'infrastructure de l'ÉTS ; plusieurs VM répliquables par Ansible et tolérantes aux pannes (ADR-0010) ; 50 élèves pour le MVP, puis l'échelle d'un département ; données personnelles soumises à la Loi 25 ; charge de travail d'un cours de projet individuel.

*Exclusions.* Fonctionnalités sociales, gamification, édition collaborative, détection de plagiat, interface d'édition du contenu. L'intégration Moodle / Safe Exam Browser est optionnelle, selon les accès obtenus.

= Choix techniques

L'analyse détaillée est consignée dans le document d'architecture et les ADR.

#table(
  columns: (3cm, 1fr, 3.2cm),
  stroke: 0.5pt,
  [*Question*], [*Solutions considérées*], [*Retenue*],
  [Isolation], [conteneur seul, gVisor, Firecracker, WebAssembly], [gVisor (ADR-0002)],
  [File], [PostgreSQL, Redis, RabbitMQ, spool fichiers], [PostgreSQL (ADR-0001)],
  [Système], [NixOS, distribution + Ansible, conteneurs seuls], [Ubuntu + Ansible (ADR-0006)],
  [Contenu], [base de données, copie servie, releases immuables], [Releases (ADR-0005)],
  [Faire ou réutiliser], [étendre CTester, Judge0, DMOJ, CodeRunner], [À justifier],
)

Technologies : Python/FastAPI, PostgreSQL, gVisor, Docker ou Podman, Ubuntu LTS et Ansible, nginx, Microsoft Entra ID, Typst, GitHub Actions.

#todo[Justifier pourquoi ne pas réutiliser un juge existant (Judge0, DMOJ, CodeRunner).]

= Échéancier

#todo[Jalons datés : plan de projet, architecture, prototype fonctionnel, mesures de charge, rapport final.]

= Risques

#table(
  columns: (0.9cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*ID*], [*Risque*], [*Mitigation*],
  [R1], [La VM de l'ÉTS n'est pas disponible à temps.], [Environnement reproductible hors ÉTS ; gVisor ne demande pas KVM.],
  [R2], [Évasion du bac à sable par du code hostile.], [Défense en profondeur, pas de réseau ni de secrets dans le juge, tests hostiles en CI.],
  [R3], [Charge d'examen non tenue.], [Mesures tôt ; capacité réservée ; contre-pression.],
  [R4], [Portée trop large pour une seule personne.], [Exclusions explicites ; prototype centré sur le jugement.],
  [R5], [La plateforme ne fonctionne pas sous SEB (condition nécessaire au projet).], [SEB est libre et s'installe sans l'ÉTS : prototype testé sous SEB dès les premières semaines, avec un `.seb` de test (ADR-0009) ; confirmer tôt la version de SEB et l'image des postes d'examen ; démarrage direct par lien `sebs://`, sans Moodle.],
  [R6], [Accès Moodle bloqué.], [Intégration Moodle optionnelle : l'examen démarre directement dans la plateforme.],
  [R7], [Panne d'une VM pendant un examen.], [Juges sans état et redondants, reprise des travaux abandonnés, réplica PostgreSQL, VM reconstruites par Ansible (ADR-0010).],
)
