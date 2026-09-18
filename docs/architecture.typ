// Contenu seul : la page et le titre sont posés par le point d'entrée
// (pdf/architecture.typ) ou par le rapport. Ne pas ajouter de #set page ici.
#import "template.typ": decision, hypothesis, mermaid, validation

= Objet du document

Ce document présente l'architecture envisagée pour une plateforme d'apprentissage et d'évaluation de la programmation destinée initialement au cours LOG200 de l'École de technologie supérieure. Le MVP vise environ 50 élèves ; à terme, la plateforme doit servir tous les enseignants du département LOG/TI et leurs groupes, ainsi qu'une partie du DEG.

La plateforme constitue une évolution conceptuelle de CTester, un système initialement développé pour l'évaluation automatisée de programmes en C dans le contexte du cours TCH009.

L'objectif n'est pas de simplement réimplémenter CTester dans une nouvelle technologie. Le projet cherche plutôt à identifier les propriétés architecturales qui permettent à une telle plateforme d'être réutilisable dans plusieurs cours, de prendre en charge plusieurs langages de programmation et de fonctionner dans des contextes d'évaluation supervisée.

Ce document est volontairement évolutif. Les décisions présentées ici ne sont pas toutes définitives. Lorsqu'une décision doit encore être validée par des mesures ou des expérimentations, elle est explicitement identifiée comme telle.

= Problématique

La plateforme doit permettre à des étudiants d'écrire, compiler et exécuter du code directement dans un environnement contrôlé.

Cette fonctionnalité introduit une contrainte fondamentale : le code étudiant doit être considéré comme du code *non fiable*.

Un programme soumis peut être incorrect par accident, mais également présenter un comportement extrêmement coûteux ou tenter volontairement d'exploiter l'environnement d'exécution.

La plateforme doit simultanément être capable de supporter des activités pédagogiques ordinaires et des évaluations supervisées pouvant impliquer plusieurs centaines d'étudiants.

#decision[
  La problématique architecturale est donc traitée comme un problème combinant   pédagogie, sécurité, performance et opérabilité plutôt que comme un simple   problème d'interface web.
]

La question directrice du projet est la suivante :

#quote[
  Comment concevoir une plateforme d'apprentissage et d'évaluation de la   programmation capable d'exécuter du code non fiable dans plusieurs langages, de supporter des charges importantes lors d'évaluations supervisées et de demeurer suffisamment flexible pour être réutilisée dans différents contextes pédagogiques ?
]

= Objectifs

== Objectifs fonctionnels

La plateforme doit permettre notamment :

- la création et la publication d'exercices ;
- l'organisation d'exercices en activités, devoirs et examens ;
- l'écriture de code dans un environnement web ;
- la sauvegarde de brouillons ;
- la soumission de programmes ;
- la compilation et l'exécution automatisées ;
- l'évaluation par tests ;
- la présentation d'un verdict structuré ;
- le suivi de la progression ;
- la gestion de plusieurs langages de programmation ;
- l'intégration avec Moodle ;
- l'utilisation dans un contexte d'examen supervisé.

== Objectifs non fonctionnels

Les propriétés suivantes sont considérées comme particulièrement importantes :

#table(
  columns: (2.8cm, 1fr),
  stroke: 0.5pt,
  [*Propriété*], [*Objectif*],

  [Sécurité],
  [Limiter les possibilités d'un programme étudiant d'accéder au système d'hébergement, aux autres soumissions ou aux données sensibles.],

  [Performance], [Maintenir une latence acceptable même lors de fortes concentrations de   soumissions.],

  [Scalabilité],
  [Permettre d'augmenter la capacité de jugement indépendamment de la capacité de l'application principale.],

  [Reproductibilité],
  [Pouvoir reconstruire l'infrastructure et les environnements de déploiement de manière automatisée.],

  [Extensibilité], [Ajouter un langage ou un type d'exercice sans modifier inutilement le reste du système.],

  [Maintenabilité],
  [Conserver des responsabilités clairement séparées et des composants pouvant être testés indépendamment.],
)

= Principes architecturaux

== Séparation des responsabilités

La plateforme est conçue autour de plusieurs responsabilités distinctes.

#mermaid(
  "
  flowchart LR
      A[Interface étudiante] --> B[API / Application]
      B --> C[File de soumissions]
      C --> D[Moteur de jugement]
      D --> E[Sandbox d'exécution]
      E --> F[Compilation / Tests]
  ",
  document-context: true,
  width: 100%,
)

Cette séparation permet notamment de faire évoluer le moteur de jugement sans modifier l'application pédagogique.

== Principe de non-confiance

Le code étudiant ne doit jamais être exécuté directement par le processus applicatif.

#decision[
  L'API ne compile et n'exécute jamais directement le code étudiant.
]

Une soumission est transformée en travail asynchrone et traitée par un composant spécifiquement responsable de l'exécution de code non fiable.

Cette séparation réduit la surface d'attaque de l'application principale et permet d'appliquer des politiques de ressources différentes à l'exécution du code.

== Séparation entre application et jugement

L'application principale est responsable notamment de :

* l'authentification ;
* la gestion des utilisateurs ;
* les cours ;
* les exercices ;
* les devoirs ;
* les examens ;
* les résultats ;
* la progression ;
* l'administration ;
* l'intégration avec Moodle.

Le moteur de jugement est responsable notamment de :

* recevoir les travaux à exécuter ;
* planifier leur exécution ;
* sélectionner le runtime approprié ;
* appliquer les limites de ressources ;
* créer l'environnement isolé ;
* compiler et exécuter le programme ;
* exécuter les tests ;
* produire un verdict.

Cette séparation permet également de dimensionner indépendamment les deux parties du système.

= Architecture générale

== Vue logique

L'architecture générale envisagée est la suivante :

#mermaid(
  "
  flowchart TB
    A[Étudiant] --> B[Navigateur / SEB]

    subgraph AUTH[Authentification]
        IDP[Microsoft Entra ID]
    end

    RP[Reverse proxy nginx<br/>TLS · statique · rate limit]

    subgraph APP[Application]
        API[Web / API]
        DB[(PostgreSQL)]
    end

    subgraph EVAL[Évaluation]
        Q[Queue PostgreSQL<br/>Backpressure · Priorités · Fairness]
        S[Judge Scheduler]
        J1[Judge]
        J2[Judge]
        J3[Judge]
        JN[...]
    end

    subgraph SANDBOX[Isolation]
        SB[Sandbox Runtime]
        P[Programme étudiant]
        T[Tests privés]
    end

    subgraph CONTENT[Contenu]
        CR[Dépôt de contenu]
        PUB[Publication<br/>validation · projection · rendu Typst]
        REL[(Releases publiques)]
    end

    CR --> PUB --> REL
    REL -->|lecture seule| API
    CR -->|données d'évaluation| S

    B -->|OIDC| IDP
    B -->|HTTPS + token| RP
    RP --> API

    API --> DB
    API -->|Soumission| Q

    Q --> S
    S --> J1
    S --> J2
    S --> J3
    S --> JN

    J1 --> SB
    J2 --> SB
    J3 --> SB
    JN --> SB

    SB -->|gVisor / Firecracker| P
    SB -->|Accès contrôlé| T

    S -->|Verdict| DB
  ",
  document-context: true,
  width: 100%,
)

Cette représentation décrit les responsabilités plutôt qu'une topologie de déploiement définitive.

Le contenu pédagogique suit un chemin distinct des soumissions : il est publié à partir de son propre dépôt, sans passer par l'API ni par la file.

#decision[
  L'API ne voit que la projection publique du contenu. Seul le moteur de jugement lit les données d'évaluation. Le cycle de vie du contenu est détaillé dans la section dédiée.
]

== Application et API

L'application web constitue la partie responsable de l'état pédagogique.

Elle ne doit pas dépendre de la présence d'un processus de compilation local. Une soumission est plutôt représentée comme un travail pouvant être placé dans une file.

Cela permet de découpler :

- le nombre de requêtes HTTP ;
- le nombre de soumissions en attente ;
- le nombre de juges disponibles ;
- le nombre d'exécutions simultanées.

== Couche d'entrée

La plateforme est déployée sur plusieurs VM aux ressources limitées, répliquables par Ansible, afin qu'une panne pendant un examen n'interrompe pas le service (ADR-0010). Chaque composant d'infrastructure supplémentaire consomme de la mémoire et du CPU qui ne sont plus disponibles pour le jugement.

#decision[
  Un composant d'infrastructure n'est ajouté que lorsqu'un besoin mesuré le justifie.
]

=== Reverse proxy

Un reverse proxy nginx constitue le seul point d'entrée HTTP de la plateforme. Il est responsable de :

- la terminaison TLS (certificats ACME obtenus et renouvelés par certbot) ;
- la distribution des fichiers statiques de l'interface web ;
- la compression des réponses ;
- la limitation du débit des requêtes (`limit_req`), notamment sur les soumissions ;
- le relais des connexions longues (SSE ou WebSocket) utilisées pour notifier les verdicts.

#decision[
  nginx est retenu pour sa faible empreinte mémoire, sa limitation de débit native et sa disponibilité dans les dépôts Ubuntu.
]

#hypothesis[
  Si l'établissement termine déjà le TLS en amont de la VM, nginx demeure utile pour les fichiers statiques et la limitation de débit.
]

=== Répartition de charge

Aucun load balancer dédié n'est prévu tant que l'API tient sur une VM.

- Côté HTTP, l'API est exécutée par plusieurs processus (workers uvicorn) partageant la même socket ; le noyau répartit les connexions entre eux.
- Côté jugement, les juges _tirent_ les travaux de la file plutôt que de les recevoir. La file joue donc elle-même le rôle de répartiteur, et la capacité s'ajuste en modifiant le nombre de juges.

#decision[
  Si l'API est répartie sur plusieurs VM `web`, un bloc `upstream` nginx répartit la charge et écarte une instance défaillante ; ce choix sera tranché d'après les tests de charge (ADR-0010).
]

== File de soumissions

La file constitue une abstraction importante entre l'application et le moteur de jugement.

Elle permet d'absorber des pointes de charge sans que l'application doive elle-même exécuter les programmes.

Elle doit éventuellement prendre en charge :

- la priorité des examens ;
- la limitation du nombre de travaux simultanés ;
- la répartition équitable des ressources ;
- le backpressure ;
- les retries contrôlés ;
- la détection des travaux abandonnés ;
- la mesure du temps d'attente.

#hypothesis[
  La politique exacte de file d'attente et d'ordonnancement devra être déterminée
  expérimentalement en fonction des charges observées.
]

#decision[
  La file est initialement implémentée dans PostgreSQL (`SELECT … FOR UPDATE SKIP LOCKED` et `LISTEN/NOTIFY`) plutôt qu'avec un service dédié comme Redis ou RabbitMQ.
]

Ce choix n'ajoute aucun service à la VM et place l'état de la file dans la même transaction que l'état des soumissions. Les retries, la détection des travaux abandonnés et la priorité des examens s'expriment alors directement en SQL.

#validation[
  Les tests de charge devront confirmer que PostgreSQL suffit comme file pour une charge d'examen. Un broker dédié ne sera envisagé que si une limite est mesurée.
]

= Moteur de jugement

== Abstraction multi-langage

L'un des objectifs majeurs est de ne pas concevoir le moteur autour du C.

Le modèle conceptuel envisagé est :

#mermaid(
  "
  flowchart TD
    J[Judge]

    J --> LR[Language Runtime]
    J --> SB[Sandbox Runtime]
    J --> RL[Resource Limits]

    subgraph LANG[Supported Languages]
        C[C] -.-> C1[Compiler]
        PY[Python] -.-> PY1[Interpreter]
        JAVA[Java] -.-> JAVA1[Compiler / JVM]
        RUST[Rust] -.-> RUST1[Compiler]
        Other[...] -.-> Other1[...]
    end

    LR --> C
    LR --> PY
    LR --> JAVA
    LR --> RUST
    LR --> Other[...]
  ",
  document-context: true,
  width: 100%,
)

Un langage doit principalement définir comment :

- préparer les fichiers ;
- compiler le programme ;
- lancer le programme ;
- interpréter son résultat ;
- éventuellement gérer ses dépendances.

Le mécanisme d'isolation ne devrait pas dépendre du langage.

== Rust

Le moteur de jugement constitue un candidat naturel pour une implémentation en Rust.

Il est susceptible de gérer :

- de nombreux travaux concurrents ;
- des processus externes ;
- des délais d'exécution ;
- des limites de ressources ;
- des files de travaux ;
- la communication avec les sandboxes ;
- la collecte de métriques.

#decision[
  L'application pédagogique peut initialement rester en Python/FastAPI tandis que le moteur de jugement est considéré comme un composant indépendant, potentiellement implémenté en Rust.
]

Cette décision n'est toutefois pas fondée uniquement sur l'affirmation que Rust serait « plus rapide ».

#validation[
  Le choix du langage du moteur devra être validé par profilage et benchmarks. Une réécriture complète de CTester en Rust n'est pas considérée comme un objectif en soi.
]

= Isolation des soumissions

== Problème

Un conteneur classique n'est pas considéré comme une frontière de sécurité suffisante à lui seul pour l'exécution de code étudiant hostile.

L'architecture doit donc distinguer :

1. le mécanisme de gestion du processus ;
2. le runtime de conteneur éventuel ;
3. le mécanisme d'isolation principal ;
4. les limites de ressources.

Conceptuellement :

#mermaid(
  "
  flowchart LR
    J[Judge] --> S[Sandbox abstraction]

    subgraph CONSTRAINTS[Resource & execution constraints]
        FS[Filesystem]
        CPU[CPU]
        MEM[Memory]
        PROC[Processes]
        TIME[Timeout]
        NET[Network policy]
    end

    subgraph ISOLATION[Isolation boundary]
        G[gVisor]
        F[Firecracker]
        O[Autres solutions]
    end

    S --> CONSTRAINTS
    S --> ISOLATION
  ",
  document-context: true,
  width: 100%,
)

== gVisor

gVisor est actuellement le candidat privilégié pour la première implémentation.

Il fournit une couche d'isolation supplémentaire entre le programme exécuté et le noyau Linux hôte.

Le mode Systrap est particulièrement intéressant lorsque la plateforme est elle-même exécutée dans une machine virtuelle.

#decision[
  gVisor Systrap constitue la solution d'isolation initialement envisagée.
]

#hypothesis[
  gVisor devrait offrir un compromis suffisamment intéressant entre sécurité, performances et complexité opérationnelle pour le contexte de LOG200.
]

== Firecracker

Firecracker constitue une alternative particulièrement intéressante lorsque la priorité est donnée à une frontière d'isolation forte.

Son modèle repose sur des microVM exécutant leur propre noyau Linux sous KVM.

En contrepartie, le cycle de vie des microVM et l'intégration avec le moteur de jugement sont plus complexes qu'une architecture reposant sur des conteneurs.

#validation[
  gVisor et Firecracker devront idéalement être comparés expérimentalement sur les charges réelles du projet avant de considérer le choix définitif.
]

== WebAssembly

WebAssembly constitue une autre possibilité grâce à un modèle d'exécution fortement sandboxé.

Cependant, son utilisation pour une plateforme multi-langage générale pose une question différente : le programme étudiant doit pouvoir être exécuté dans un environnement WebAssembly compatible avec son langage et ses bibliothèques.

#decision[
  WebAssembly est considéré comme une piste complémentaire plutôt que comme
  l'environnement universel initial de la plateforme.
]

Cette piste est retenue côté client : dans les langages où c'est facile, les tests visibles s'exécutent dans le navigateur avant tout envoi au serveur (ADR-0008). Le juge reste la seule référence.

== Runtime de conteneur

Docker ou Podman peuvent servir à gérer le cycle de vie des environnements d'exécution.

Ils ne sont toutefois pas considérés comme la frontière de sécurité principale.

Le modèle recherché est donc plutôt :

#mermaid(
  "
  flowchart LR
    J[Judge] --> C[Container Runtime]
    C --> I[Isolation gVisor/Firecracker]
    I --> S[Student code]
  ",
  document-context: true,
  width: 100%,
)

#hypothesis[
  Le choix précis entre Docker et Podman devrait avoir un impact inférieur au
  choix du mécanisme d'isolation lui-même.
]

= Gestion des ressources

Chaque exécution doit disposer d'un ensemble explicite de limites.

On considère notamment :

#table(
  columns: (4cm, 1fr),
  stroke: 0.5pt,
  [*Ressource*], [*Limite envisagée*],

  [Temps], [Timeout maximal par étape et par soumission.],

  [CPU], [Nombre de cœurs ou quantité de CPU utilisable.],

  [Mémoire], [Limite de mémoire par exécution.],

  [Processus], [Nombre maximal de processus ou threads.],

  [Stockage], [Espace temporaire maximal.],

  [Réseau], [Accès réseau explicitement refusé ou limité.],
)

Ces limites doivent être appliquées indépendamment de la correction du programme.

Un programme qui boucle infiniment doit produire un timeout plutôt que consommer indéfiniment une ressource du système.

== Mesure de la performance

Le temps d'exécution sert de garde-fou, pas de mesure. Il varie avec la charge de la VM et avec le langage, et ne permet donc pas de comparer équitablement des algorithmes.

#decision(id: "ADR-0007")[
  La performance est mesurée en instructions exécutées, de façon déterministe, et comparée à une solution de référence du même langage, la complexité étant le critère principal. La limite de la passe de mesure est un budget d'instructions. La mesure est faite après l'examen, sur la dernière soumission de chaque élève pour chaque exercice.
]

= Charge et performance

== Charge cible

Un examen peut impliquer environ 400 étudiants.

Il serait toutefois incorrect de modéliser la charge comme simplement 400 requêtes HTTP simultanées.

Chaque étudiant peut produire plusieurs soumissions :

#mermaid(
  "
  flowchart LR
    A[~400 étudiants] --> B[Burst de soumissions]

    B --> C[File de jugement]

    C --> D[Correction]
    D --> E[Nouvelle soumission]
    E --> C
  ",
  document-context: true,
  width: 100%,
)

La charge réelle dépend donc fortement du comportement temporel des étudiants.

== Dimensionnement

Le système doit permettre d'augmenter le nombre de workers de jugement indépendamment de l'application principale.

Par exemple :

#mermaid(
  "
  flowchart TD
    API[Application / API] --> Q[Queue]

    Q --> J1[Judge worker]
    Q --> J2[Judge worker]
    Q --> J3[Judge worker]
    Q --> JN[...]

    J1 --> S1[Sandbox]
    J2 --> S2[Sandbox]
    J3 --> S3[Sandbox]
    JN --> SN[...]
  ",
  document-context: true,
  width: 100%,
)

Cette architecture permet d'ajuster la capacité sans modifier la logique pédagogique.

== Cache

Aucun serveur de cache dédié (Redis, Memcached) n'est prévu initialement. Le cache est plutôt placé là où il réduit un coût réel :

#table(
  columns: (3.2cm, 1fr),
  stroke: 0.5pt,
  [*Emplacement*], [*Contenu*],

  [Navigateur / nginx],
  [Fichiers statiques versionnés par empreinte et servis avec des en-têtes `Cache-Control` de longue durée.],

  [API], [Données d'exercice publiées, peu modifiées, conservées en mémoire du processus.],

  [Juge],
  [Images et chaînes de compilation préchargées, sandboxes préparées à l'avance et, éventuellement, artefacts compilés des tests privés.],
)

L'authentification repose sur des jetons OIDC émis par Microsoft Entra ID, ce qui évite de maintenir un stockage de sessions côté serveur.

#hypothesis[
  Le coût dominant d'une soumission se situe dans le démarrage de la sandbox et la compilation plutôt que dans l'accès aux données. Le cache côté juge devrait donc avoir un impact plus important que tout cache applicatif.
]

#decision[
  Un cache partagé ne sera introduit que si plusieurs instances de l'API doivent partager un même état.
]

== Métriques

Les benchmarks devront notamment mesurer :

- le débit de soumissions ;
- le temps passé dans la file ;
- la latence totale ;
- P50 ;
- P95 ;
- P99 ;
- le temps de compilation ;
- le temps d'exécution ;
- l'utilisation CPU ;
- l'utilisation mémoire ;
- le nombre maximal de jobs simultanés ;
- le taux de timeout ;
- le taux d'échec de l'infrastructure ;
- la part des exécutions de test traitées dans le navigateur (ADR-0008) ;
- la durée de vidage de la file de mesure après un examen (ADR-0007).

#decision[
  Les performances seront évaluées avec des charges reproductibles plutôt qu'avec une estimation théorique uniquement.
]

== Comparaison des mécanismes d'isolation

Une expérimentation pourra notamment comparer :

#mermaid(
  "
  flowchart LR
    L[Charge identique] --> G[gVisor]
    L --> F[Firecracker]

    G --> GM[Mesures]
    F --> FM[Mesures]

    subgraph METRICS[Métriques]
        M1[Temps de démarrage]
        M2[Latence]
        M3[Débit]
        M4[CPU / mémoire]
    end

    GM --> METRICS
    FM --> METRICS

    METRICS --> C[Comparaison]
  ",
  document-context: true,
  width: 100%,
)

Les critères incluront au minimum :

- temps de démarrage ;
- latence de soumission ;
- débit ;
- mémoire consommée ;
- CPU consommé ;
- comportement sous forte charge ;
- comportement lors d'exécutions malveillantes ou pathologiques ;
- complexité opérationnelle.

= Mode d'examen

La plateforme doit distinguer le contexte d'apprentissage du contexte d'évaluation.

Trois modes conceptuels sont actuellement envisagés :

#mermaid(
  "
  flowchart LR
    P[Practice]
    A[Assignment]
    E[Exam]

    P --> P1[Exploration]
    P --> P2[Feedback complet]
    P --> P3[Fonctionnalités sociales]

    A --> A1[Échéance]
    A --> A2[Progression]
    A --> A3[Soumissions]

    E --> E1[Durée]
    E --> E2[Contrôle]
    E --> E3[Ressources réservées]
    E --> E4[Feedback limité]
  ",
  document-context: true,
  width: 100%,
)

== Safe Exam Browser

Safe Exam Browser est considéré comme un mécanisme complémentaire plutôt que comme une fonctionnalité que la plateforme devrait réimplémenter.

SEB contrôle principalement l'environnement de l'ordinateur étudiant, tandis que la plateforme contrôle l'état pédagogique de l'examen.

#mermaid(
  "
  flowchart LR
      subgraph PLATFORM[Plateforme]
        P[État pédagogique de l'examen]
        P --> P1[Examen]
        P --> P2[Exercices]
        P --> P3[Temps]
        P --> P4[Soumissions]
        P --> P5[Résultats]
    end

    subgraph SEB[Safe Exam Browser]
        S[Environnement étudiant]
        S --> S1[Verrouillage]
        S --> S2[Applications autorisées]
        S --> S3[Navigation]
        S --> S4[Configuration]
    end

    S -->|Accès contrôlé| P
  ",
  document-context: true,
  width: 100%,
)

=== Contraintes imposées par SEB

- *Vérification.* Le serveur vérifie la configuration de SEB sur les routes d'examen, même si l'examen démarre dans Moodle (ADR-0009).
- *Authentification.* Le filtre d'URL permet `login.microsoftonline.com`. L'authentification multifacteur par téléphone est incompatible avec l'interdiction des téléphones : la session est ouverte avant l'examen, ou une politique d'accès conditionnel s'applique aux salles.
- *Ressources.* Aucun CDN : les runtimes du navigateur (Pyodide, esbuild-wasm, etc.) sont servis par la plateforme.
- *Navigation.* Aucune nouvelle fenêtre ni aucun téléchargement : les énoncés sont rendus en HTML ou en SVG, pas en PDF. La remise automatique redirige vers la « Quit URL » de SEB.
- *Reprise.* Si SEB est relancé, l'élève retrouve ses brouillons autosauvegardés, le temps est calculé par le serveur et le flux SSE reprend grâce à `Last-Event-ID`.
- *Éditeur.* Les raccourcis clavier et le presse-papiers, que SEB peut restreindre, sont testés.
- *Moteurs.* SEB Windows repose sur Chromium ; SEB macOS et iOS reposent sur WebKit, où les service workers sont limités. Solution de repli : le cache HTTP.

== Ressources réservées

Un examen doit pouvoir disposer d'une capacité de jugement réservée.

L'objectif est d'éviter qu'une activité non critique puisse consommer l'ensemble des workers au moment où les étudiants passent un examen.

#hypothesis[
  Un système de priorités ou de pools de capacité distincts pourrait être
  suffisant pour garantir cette propriété sans nécessiter une infrastructure
  complètement séparée.
]

= Modèle pédagogique

L'architecture ne doit pas limiter un exercice à une paire « énoncé + solution ».

Un exercice est plutôt considéré comme une ressource déclarative contenant des informations pédagogiques et d'évaluation.

Conceptuellement :

```text
Exercise
│
├── metadata
├── statement
├── language constraints
├── difficulty
├── skills
├── prerequisites
├── context
├── tests
├── hints
└── release rules
```

Les tests publics et privés doivent rester séparés.

#mermaid(
  "
  flowchart LR
    E[Exercise] --> P[Public data]
    E --> PR[Private data]

    P --> UI[Student UI]
    PR --> J[Judge]
  ",
  document-context: true,
  width: 100%,
)

Cette séparation évite notamment d'exposer les cas de tests utilisés pour évaluer les soumissions.

== Extensibilité

Ajouter un exercice devrait idéalement être principalement une opération de configuration et de contenu plutôt qu'une modification du code source de la plateforme.

L'architecture doit donc favoriser un modèle déclaratif.

Le moteur d'évaluation interprète les données de l'exercice et sélectionne le runtime correspondant au langage demandé.

= Cycle de vie du contenu

Dans CTester, la plupart des incidents liés au contenu ne venaient pas du juge, mais du chemin entre le dépôt des enseignants et ce que l'étudiant reçoit : un corrigé exposé par accident, un exercice qui disparaît du menu la veille du cours, un catalogue vide servi en silence. Ce chemin est donc traité comme un composant architectural à part entière.

== Vue d'ensemble

#mermaid(
  "
  flowchart LR
    D[Dépôt privé<br/>du contenu] --> V[Validation]
    V --> P[Projection publique]
    P --> R[Release immuable<br/>révision = hachage]
    R --> PTR[Pointeur<br/>current]

    PTR --> API[API<br/>données publiques]
    D --> J[Juge<br/>tests privés]
    PTR -.->|revalide l'ouverture| J
  ",
  document-context: true,
  width: 100%,
)

Le contenu est édité dans un dépôt distinct du code de la plateforme. Chaque exercice y regroupe ses métadonnées, son énoncé, ses fichiers publics (gabarits) et ses données d'évaluation privées :

```text
exercises/<id>/
├── exercise.json      métadonnées, compétences, règles d'ouverture
├── statement.md       ou statement.typ, jamais les deux
├── public/            gabarits remis à l'étudiant
└── assessment/        tests, cas, configuration du juge (privé)
```

#decision[
  La publication est déclenchée par une modification du dépôt de contenu et ne nécessite aucun redéploiement ni redémarrage de l'application ou du juge.
]

== Validation

Un contenu invalide ne doit jamais remplacer la publication active.

La validation vérifie notamment le schéma des métadonnées, l'unicité des identifiants, la cohérence des collections et l'absence d'ambiguïté, par exemple deux formats d'énoncé pour un même exercice. Elle échoue *avant* la première écriture.

#decision[
  Une erreur de validation arrête la publication en nommant l'exercice et le champ fautifs. La release précédente reste servie.
]

== Projection publique

La release publique n'est pas une copie du dépôt de contenu. Elle est reconstruite champ par champ à partir d'une liste explicite de ce qui peut être montré.

Une seconde vérification relit ensuite la projection produite et refuse de publier si une clé réservée aux données d'évaluation (`answer`, `expect`, `cases`, `stdin`, chemins internes…) y apparaît.

#decision[
  La projection est construite par énumération positive (ce qui est publié) et contrôlée par énumération négative (ce qui ne doit jamais l'être). La première protège contre l'oubli d'aujourd'hui, la seconde contre le champ ajouté demain.
]

Le catalogue publié contient *tous* les exercices, y compris ceux qui ne sont pas encore ouverts, avec leur date d'ouverture. Le détail d'un exercice (énoncé, gabarits, questions) n'est écrit que pour les exercices ouverts.

#hypothesis[
  Montrer un exercice verrouillé avec sa date est préférable à le masquer : dans CTester, un exercice absent du menu était perçu par les étudiants comme une panne.
]

== Releases et rollback

Chaque publication produit un répertoire de release dont l'identifiant est le hachage de son contenu. Republier un contenu inchangé ne crée rien, et une modification crée une nouvelle release qui coexiste avec les précédentes.

La release active est désignée par un pointeur, un fichier plutôt qu'un lien symbolique. Un montage de conteneur résout le lien au démarrage, donc un changement de lien ne serait visible qu'au redémarrage.

#decision[
  Le rollback du contenu consiste à réécrire le pointeur vers une release précédente. Il est instantané et ne redéploie aucun composant.
]

L'élagage conserve les dernières releases selon une date de publication écrite dans leur manifeste, et non selon la date de modification du système de fichiers. Dans CTester, cette dernière avait une granularité différente sous Windows et sous Linux, ce qui faisait supprimer une release qu'on avait promis de garder.

== Ouverture dans le temps

Chaque exercice porte un état (`draft`, `scheduled`, `open`, `archived`) et, au besoin, une date d'ouverture.

#decision[
  Une seule fonction décide si un exercice est accessible à un instant donné. Un exercice `scheduled` dont la date est passée est ouvert, sans commit ni tâche planifiée le matin du cours.
]

Toutes les lectures d'un exercice (détail, soumission, brouillon, discussion) passent par une porte unique qui résout l'identifiant dans la release active et refuse ce qui n'est pas ouvert. Un lien partagé en avance ne contourne donc rien.

== Double contrôle par le juge

L'API ne transmet au juge qu'un identifiant d'exercice. Le juge résout lui-même cet identifiant contre la release active avant de lire les données d'évaluation.

#decision[
  Le juge ne fait pas confiance à l'API sur l'ouverture d'un exercice. Une API compromise peut mentir sur l'auteur d'une soumission, mais ne peut pas obtenir l'exécution des tests d'un exercice fermé.
]

== Aperçu enseignant

Un enseignant doit pouvoir consulter et soumettre un exercice avant son ouverture, dans les conditions réelles, sans l'ouvrir aux étudiants.

La projection écrit donc une copie restreinte des exercices non ouverts, servie uniquement aux comptes enseignants et jamais mise en cache par un intermédiaire. Le rôle est recalculé côté serveur à chaque requête, et à nouveau par le juge, à partir de l'identité authentifiée.

#decision[
  L'aperçu est une propriété de l'identité authentifiée, pas un drapeau global. Le comportement par défaut de la porte d'accès est fermé.
]

== Preuve du contenu

Un test incorrect produit un verdict faux que l'étudiant ne peut pas contester.

#decision[
  Chaque exercice est accompagné d'une solution de référence conservée hors du dépôt publié. Un contrôle compile cette solution et la fait passer dans le véritable juge avant l'ouverture. Un exercice sans solution est signalé comme « non prouvé ».
]

#validation[
  Ce contrôle doit être intégré à la CI du dépôt de contenu, et les exercices non prouvés doivent être visibles avant leur date d'ouverture.
]

= Rendu des énoncés

Un énoncé de programmation contient du texte, du code, des formules et parfois des tableaux, des figures ou des diagrammes. Deux formats sont pris en charge, avec des modèles de rendu opposés.

#table(
  columns: (2.8cm, 1fr, 1fr),
  stroke: 0.5pt,
  [], [*Markdown*], [*Typst*],
  [Usage], [Défaut, la grande majorité des énoncés], [Tableaux, diagrammes, figures, mise en page multi-page],
  [Rendu], [Dans le navigateur, à l'affichage], [À la publication, dans un conteneur],
  [Livré], [Texte source], [HTML, avec SVG clair et sombre en repli],
  [Accessibilité], [Complète], [Réduite pour le SVG],
)

== Markdown

Le Markdown est rendu côté client par une grammaire volontairement restreinte : paragraphes, titres, listes, code en ligne, blocs de code colorés et emphase. Une bibliothèque générale n'est pas utilisée.

Cette décision découle de deux constats faits dans CTester :

- une bibliothèque Markdown complète et son assainisseur pesaient plusieurs fois le reste de la page, sur le chemin des étudiants non connectés ;
- les règles de CommonMark sont mal adaptées au C : l'astérisque est aussi l'opérateur de déréférencement et de multiplication, et `*quotient et *reste` devient de l'italique en perdant ses deux astérisques.

#decision[
  L'emphase n'est reconnue que lorsque le délimiteur est collé à un mot du côté intérieur et séparé du texte du côté extérieur. Le soulignement `_` n'est pas une syntaxe d'emphase, car il apparaît dans la plupart des identifiants.
]

Les formules sont délimitées explicitement par `$…$` et converties en MathML natif. Le navigateur les dessine sans bibliothèque ni police externe, ce qui ne demande aucune exception à la politique de sécurité du contenu (CSP).

#decision[
  Une formule n'est jamais devinée. En C, `z/4` est une division entière et non une fraction, et une barre de fraction enseignerait le contraire. Une formule qui ne s'analyse pas est affichée comme du code en ligne, jamais comme une erreur.
]

Le contenu Markdown provient du dépôt privé relu par l'équipe enseignante. Toute sortie HTML est néanmoins construite à partir de fragments échappés.

#hypothesis[
  Les contenus rédigés par les étudiants (forum, discussions) demandent une chaîne différente : échappement avant l'analyse et assainissement par liste blanche à chaque affichage. Les deux chaînes ne doivent pas être fusionnées.
]

== Typst

Typst est réservé à ce que la grammaire Markdown ne permet pas d'écrire.

#mermaid(
  "
  flowchart LR
    S[statement.typ] --> C[Copie sans<br/>données privées]
    C --> T[Conteneur typst<br/>--root · sans réseau]
    L[Gabarit partagé<br/>paquets vendorés] --> T
    T --> H[HTML]
    T --> SV[SVG clair / sombre]
    H --> R[Release]
    SV --> R
  ",
  document-context: true,
  width: 100%,
)

#decision[
  Rien n'est compilé à la requête. Typst est exécuté pendant la publication, et l'étudiant reçoit des fichiers statiques. Le service exposé à Internet n'a ni compilateur Typst, ni accès au contenu privé, ni accès au runtime de conteneurs.
]

La compilation traite le document comme non fiable, même s'il est rédigé par l'équipe enseignante :

- elle est faite depuis une *copie* de l'exercice qui ne contient pas les données d'évaluation ;
- la racine du projet Typst est limitée à cette copie, ce qui refuse les chemins relatifs sortants et ré-enracine les chemins absolus ;
- le conteneur n'a pas d'accès réseau, et les paquets utilisés (gabarit du cours, Mermaid) sont vendorés ;
- un délai maximal borne un document lourd qui bloquerait la publication.

Le gabarit du cours est distribué comme paquet Typst local. L'enseignant n'écrit aucun préambule : la plateforme applique le gabarit puis inclut l'énoncé.

=== Thèmes et formats

Un SVG est peint une fois pour toutes et ne peut pas suivre le thème de la page. Chaque énoncé est donc rendu deux fois, en clair et en sombre.

L'export HTML de Typst est privilégié lorsqu'il est complet. La publication détecte les éléments ignorés par l'export HTML et ne publie alors que les SVG.

#decision[
  Le HTML est affiché en priorité et le SVG sert de repli, sans choix exposé à l'étudiant. Un échec du HTML ne bloque pas la publication, un échec du SVG la bloque.
]

=== Cache de rendu

La clé de cache couvre tout ce dont le rendu dépend : version de Typst, gabarit, paquets vendorés et arbre de l'exercice *sauf* ses données d'évaluation. Corriger un cas de test ne recompile donc aucun énoncé.

Les fichiers rendus entrent dans le hachage de la release. Une modification du gabarit produit alors une nouvelle release, qui peut être annulée par le pointeur comme toute autre publication.

#decision[
  Le cache de rendu est adressé par contenu et conservé hors du répertoire des releases, qui est élagué à chaque publication.
]

=== Limite d'accessibilité

Typst vectorise ses glyphes dans le SVG : le texte n'y est ni sélectionnable, ni trouvable par recherche, ni lisible par un lecteur d'écran. Le HTML n'a pas cette limite, mais il n'est pas toujours disponible.

#decision[
  Markdown reste le format par défaut. Typst n'est utilisé que pour un contenu qui ne peut pas être exprimé autrement.
]

#validation[
  La maturité de l'export HTML de Typst devra être réévaluée à chaque version. Si elle devient suffisante, le repli SVG pourra être abandonné et la limite d'accessibilité disparaîtra.
]

= Infrastructure

L'infrastructure doit être reproductible, versionnée et suffisamment indépendante des opérations manuelles pour permettre de reconstruire un environnement de déploiement de manière fiable.

L'architecture envisagée distingue plusieurs niveaux de responsabilité :

#mermaid(
  "
  flowchart TD
    I[Infrastructure]

    I --> T[Terraform]
    I --> VM[VM ÉTS]

    T -.->|Provisionnement si disponible| VM

    VM --> U[Ubuntu LTS]
    A[Ansible] -->|Configuration| U

    U --> SYS[Système]
    U --> SEC[Sécurité]
    U --> SVC[Services]

    SVC --> API[API]
    SVC --> J[Judge]

    J --> ISO[gVisor / autres mécanismes d'isolation]
  ",
  document-context: true,
  width: 100%,
)

== Provisionnement de l'infrastructure

Terraform est envisagé pour décrire et provisionner les ressources d'infrastructure lorsque l'environnement d'hébergement fournit une interface compatible.

Il pourrait notamment être utilisé pour gérer :

- les machines virtuelles ;
- les réseaux ;
- les volumes ;
- les règles d'accès ;
- les ressources nécessaires au déploiement.

Toutefois, l'infrastructure fournie par l'établissement peut ne pas offrir d'interface permettant à Terraform de créer ou de modifier directement ces ressources.

#decision[
  Terraform sera utilisé lorsque l'environnement d'hébergement permet de provisionner l'infrastructure de manière automatisée. Dans le cas contraire, la VM fournie par l'établissement sera considérée comme une ressource externe au projet.
]

Cette distinction permet de ne pas introduire Terraform artificiellement dans un environnement où il n'apporterait pas de valeur opérationnelle.

== Système d'exploitation

Les VM fournies par l'établissement fonctionnent sous Ubuntu LTS. NixOS, initialement envisagé (ADR-0003), n'est pas retenu ; voir ADR-0006.

Ubuntu n'offre pas de configuration déclarative native. La configuration du système est donc décrite par des playbooks Ansible idempotents, versionnés avec le reste du projet, afin de pouvoir reconstruire ou ajouter une machine à partir du dépôt. Un inventaire par groupes (`web`, `judge`, `db`) décrit les VM ; en ajouter une revient à l'inscrire dans l'inventaire et à exécuter un playbook (ADR-0010).

Le modèle recherché est :

#mermaid(
  "
  flowchart LR
    Git     --> Ansible[Playbooks Ansible]
    Ansible --> VM[VM Ubuntu]
    VM      --> A[État système reproductible]
  ",
  document-context: true,
  width: 100%,
)

Les playbooks décrivent notamment :

- les paquets installés ;
- les services système ;
- la configuration réseau ;
- le pare-feu ;
- les utilisateurs et permissions nécessaires ;
- les mécanismes de journalisation ;
- les services de supervision ;
- le runtime de conteneurs ;
- les composants nécessaires à l'isolation des soumissions.

#decision[
  La VM principale utilise Ubuntu LTS, imposé par l'établissement. Son état permanent est décrit par les playbooks Ansible du dépôt.
]

Contrairement à NixOS, Ubuntu ne conserve pas de générations du système permettant de revenir à une configuration précédente. Ce risque est compensé par :

- un snapshot de la VM avant chaque mise à jour du système ou de la plateforme ;
- l'épinglage des versions des paquets critiques (runtime de conteneurs, gVisor, nginx, PostgreSQL) ;
- la limitation de `unattended-upgrades` aux correctifs de sécurité, suspendue à l'approche d'un examen.

#hypothesis[
  Les snapshots de VM et l'épinglage des versions peuvent réduire le risque opérationnel lors des mises à jour de la plateforme, notamment à l'approche d'une période d'évaluation.
]

== Rôle d'Ansible

Ansible est le mécanisme de configuration de l'hôte. Il couvre à la fois l'état permanent de la machine et les opérations ponctuelles, par exemple :

- la coordination d'une mise à jour ;
- certaines opérations de déploiement ;
- des tâches administratives.

La frontière recherchée est donc :

#mermaid(
  "
  flowchart LR
    T[Terraform] --> T1[Provisionnement de l'infrastructure]
    A[Ansible]   --> A1[État de la machine et opérations]
    C[CI/CD]     --> C1[Construction et déploiement de l'application]
  ",
  document-context: true,
  width: 100%,
)

#decision[
  La configuration persistante du système est déclarée dans les playbooks Ansible. Toute modification manuelle de la machine doit y être répercutée.
]

Une convergence impérative peut laisser l'état réel dériver de ce que décrit le dépôt. Les playbooks sont donc exécutés régulièrement en mode `--check --diff` pour détecter toute dérive.

== Environnement de déploiement

L'infrastructure cible devrait idéalement être séparée en plusieurs environnements lorsque les ressources disponibles le permettent :

#mermaid(
  "
  flowchart LR
    I[Infrastructure]

    I --> V[Validation]
    I --> P[Production]

    V --> V1[Tests / CI]
    P --> P1[Enseignement / examens]
  ",
  document-context: true,
  width: 100%,
)

L'environnement de validation permet notamment de tester une nouvelle version du système, du juge ou des mécanismes d'isolation avant son utilisation dans un contexte pédagogique réel.

#hypothesis[
  Un environnement de préproduction distinct peut être particulièrement utile avant les examens, puisque certaines modifications du système de jugement ou de l'isolation peuvent avoir des conséquences importantes sur la disponibilité de la plateforme.
]

= CI/CD

Le pipeline envisagé est :

#mermaid(
  "
  flowchart TD
    G[Git push] --> T

    subgraph T[Tests]
      T1[Tests unitaires]
      T2[Tests d'intégration]
      T3[Tests de sécurité]
    end

    T --> B

    subgraph B[Build]
      B1[Web]
      B2[API]
      B3[Judge]
    end

    B --> IMG[Images / artefacts]
    IMG --> REG[Registry / stockage d'artefacts]
    REG --> D[Déploiement]

    D --> VAL[Environnement de validation]
    D --> PROD[Production]
  ",
  document-context: true,
  width: 100%,
)

La configuration Ansible doit elle-même être testée (`ansible-lint`, exécution en `--check`) et versionnée dans le même cycle de développement.

Le pipeline doit notamment permettre de vérifier qu'une modification du système ou de l'application peut être construite avant d'être déployée.

#decision[
  Le déploiement doit être automatisé autant que possible et reproductible à partir du dépôt. Les modifications manuelles de la production doivent être évitées ou, lorsqu'elles sont nécessaires, documentées et répercutées dans la configuration déclarative.
]

La CI/CD ne doit cependant pas déployer automatiquement n'importe quelle modification directement dans l'environnement utilisé pour les examens.

Une distinction doit être maintenue entre :

* validation automatique ;
* déploiement en préproduction ;
* validation humaine ;
* déploiement en production.

= Organisation du code

Un monorepo est actuellement privilégié afin de conserver une vue cohérente des différents composants du projet.

Une organisation possible est :

```text
log-platform/
│
├── apps/
│   ├── web/
│   ├── api/
│   └── judge/
│
├── packages/
│
├── content/
│
├── infrastructure/
│   ├── ansible/
│   │   ├── site.yml
│   │   ├── inventory/
│   │   └── roles/
│   │
│   └── terraform/
│
├── deployment/
│
├── tests/
│
├── docs/
│
└── .github/
```

Le répertoire `infrastructure/ansible/` contient la configuration des machines administrées par le projet ainsi que les opérations d'administration.

Le répertoire `terraform/` contient uniquement les ressources effectivement gérées par Terraform.

#decision[
  Le monorepo est privilégié afin de conserver une version cohérente de l'application, du moteur de jugement, du contenu pédagogique et de l'infrastructure.
]

Les frontières entre composants doivent néanmoins rester explicites.

Un monorepo ne signifie pas que tous les composants partagent le même code, le même langage ou le même cycle de déploiement.

= Sécurité

== Principe de défense en profondeur

La sécurité de l'exécution ne repose pas sur le système d'exploitation ou sur un seul mécanisme d'isolation.

Une exécution doit idéalement traverser plusieurs niveaux de protection :

#mermaid(
  "
  flowchart LR
    C[Code étudiant]            --> V[Validation applicative]
    V                           --> J[Judge]
    J                           --> R[Limites de ressources]
    R                           --> RT[Conteneur / runtime]
    RT                          --> ISO[gVisor / microVM]
    ISO                         --> H[Hôte Ubuntu]
    H                           --> VM[VM de l'établissement]
  ",
  document-context: true,
  width: 100%,
)

Chaque couche doit réduire les conséquences potentielles d'une défaillance d'une autre couche.

Le rôle d'Ubuntu et d'Ansible dans cette architecture est principalement de fournir un environnement système reproductible et administrable. Il ne constitue pas à lui seul la frontière d'isolation des programmes étudiants.

== Séparation des secrets

Le processus responsable de l'exécution du code étudiant ne devrait pas avoir accès aux secrets critiques de l'application.

En particulier, le moteur de jugement devrait fonctionner avec le minimum de privilèges nécessaire à son fonctionnement.

La compromission éventuelle d'un environnement d'exécution ne doit donc pas permettre d'obtenir directement les identifiants permettant d'accéder aux services critiques de la plateforme.

== Séparation des responsabilités sur la VM

Lorsque les ressources disponibles le permettent, les composants présentant des niveaux de confiance différents devraient être séparés.

Un modèle possible est :

#mermaid(
  "
  flowchart TB
    subgraph VM[VM Ubuntu]
        API[Application<br/>API / Web]
        J[Judge]

        subgraph ISO[Isolation]
            S[Sandbox]
            C[Code étudiant]
        end

        J --> S
        S --> C
    end

    API -->|Soumission| J
  ",
  document-context: true,
  width: 100%,
)

Une séparation physique ou virtuelle plus forte entre l'application et le moteur de jugement pourra être envisagée si l'analyse de menace ou les contraintes de charge le justifient.

#validation[
  La répartition des rôles (`web`, `judge`, `db`) entre les VM (ADR-0010) devra être déterminée en fonction des ressources disponibles, du modèle de menace et des résultats des tests de charge.
]

== Réseau

Le code étudiant n'a normalement aucune raison d'accéder à Internet ou au réseau interne de l'établissement.

#decision[
  L'accès réseau des programmes étudiants doit être refusé par défaut et explicitement autorisé uniquement lorsqu'un exercice particulier le nécessite.
]

La configuration du réseau et du pare-feu doit être considérée comme une partie de l'infrastructure déclarative et non comme une configuration manuelle de la machine.

== Ressources

Chaque exécution doit disposer de limites explicites concernant notamment :

- le temps CPU ;
- le temps total d'exécution ;
- la mémoire ;
- le nombre de processus et threads ;
- l'espace disque temporaire ;
- les connexions réseau ;
- les fichiers accessibles.

Ces limites doivent être appliquées au niveau du mécanisme d'exécution isolée et non uniquement par le programme de l'étudiant.

= Reproductibilité

L'objectif global de l'infrastructure est de pouvoir répondre à la question :

> « Peut-on reconstruire un environnement fonctionnel et suffisamment
> identique à partir du dépôt du projet ? »

Le niveau de reproductibilité recherché est :

#mermaid(
  "
  flowchart LR
    G[Dépôt Git] --> SRC[Code source de l'application]
    G            --> INF[Infrastructure]

    INF --> N[Configuration Ansible]
    N   --> VM
    VM  --> SVC[Services configurés]
    SVC --> APP[Application]
  ",
  document-context: true,
  width: 100%,
)

La reproductibilité ne signifie pas nécessairement que chaque donnée de production doit être reconstruite à partir de zéro. Les données persistantes, les secrets et certaines ressources fournies par l'établissement constituent des dépendances externes qui doivent être explicitement identifiées.

#decision[
  L'infrastructure doit documenter ses dépendances externes afin qu'une configuration fonctionnelle ne dépende pas de connaissances implicites détenues uniquement par un administrateur.
]

= Décisions à valider

Les choix suivants restent conditionnels ou devront être confirmés expérimentalement :

#table(
  columns: (3.2cm, 5cm, 1fr),
  stroke: 0.5pt,

  [*Sujet*], [*Position actuelle*], [*Validation*],

  [OS principal], [Ubuntu LTS (imposé par l'établissement)], [Compatibilité de gVisor avec le noyau fourni],

  [Provisionnement], [Terraform si une API compatible est disponible], [Capacités réelles de l'environnement ÉTS],

  [Configuration], [Playbooks Ansible], [Détection de dérive, snapshots de VM et accès `sudo`],

  [Runtime], [Docker ou Podman], [Compatibilité avec le mécanisme d'isolation],

  [Isolation], [gVisor initialement envisagé], [Benchmark et tests de sécurité],

  [Alternative d'isolation], [Firecracker], [Benchmark comparatif],

  [Topologie], [Plusieurs VM répliquables par Ansible (ADR-0010)], [Charge, sécurité et ressources disponibles],

  [Reverse proxy], [nginx ; `upstream` si plusieurs VM `web`], [Prise en charge du TLS par l'établissement],

  [File], [PostgreSQL (`SKIP LOCKED`)], [Tests de charge d'examen],

  [Cache], [Aucun service dédié ; cache côté juge], [Profilage du coût d'une soumission],

  [Mesure de performance],
  [Comptage d'instructions sous QEMU (ADR-0007)],
  [Déterminisme sous charge et compatibilité avec gVisor],

  [Tests visibles],
  [Navigateur pour les langages faciles (ADR-0008)],
  [Gain de charge, écarts avec le juge, Safe Exam Browser],
)

L'architecture sera considérée comme stabilisée uniquement après validation des hypothèses ayant un impact important sur la sécurité, la performance ou l'opérabilité du système.

= Questions ouvertes

Plusieurs questions importantes restent volontairement ouvertes.

1. PostgreSQL suffit-il comme file de soumissions sous une charge d'examen ?
2. Quelle politique d'ordonnancement minimise la latence perçue pendant un
  examen ?
3. Combien de workers sont nécessaires pour une charge de 400 étudiants ?
4. Quelle quantité de ressources doit être attribuée à chaque soumission ?
5. Quel est le coût réel de gVisor pour des compilations réalistes ?
6. Dans quelles conditions Firecracker devient-il préférable à gVisor ?
7. Quelle stratégie permet de limiter efficacement les attaques par
  consommation de ressources ?
8. Quelle granularité doit avoir l'abstraction des langages ?
9. Comment gérer les dépendances spécifiques à chaque langage ?
10. Quelle quantité d'état doit être persistée dans PostgreSQL, et combien de temps ? La durée de conservation des soumissions, des résultats et des journaux suit la _Loi sur l'accès_ et le calendrier de conservation de l'ÉTS (_Loi sur les archives_) ; elle reste à confirmer auprès de l'ÉTS. La purge s'appuie sur l'autovacuum et, si le volume le justifie, sur le partitionnement par date plutôt que sur `VACUUM FULL`.
11. Comment garantir la reprise après panne d'un worker, d'une VM ou du primaire PostgreSQL pendant un examen ? Une approche est proposée dans l'ADR-0010.
12. Quelle observabilité est nécessaire pour diagnostiquer un examen en cours ?
13. Comment intégrer proprement Moodle et Safe Exam Browser ? La vérification de SEB est proposée dans l'ADR-0009 ; le passage de Moodle à la plateforme par LTI reste à préciser.
14. Quelle partie de l'architecture doit être commune aux différents cours ?
15. Comment les données d'évaluation sont-elles distribuées aux juges lorsqu'ils sont répartis sur plusieurs machines : montage partagé, copie à la publication ou artefact versionné ?
16. La performance est-elle notée par un verdict de complexité (une référence par exercice) ou par un classement complet (une référence par langage) ? À trancher avec l'enseignant.
17. Un code qui ne passe pas tous les tests est-il mesuré ? Si la dernière soumission échoue alors qu'une précédente passait, laquelle mesure-t-on ?
18. Quels langages chaque cours supporte-t-il, et lesquels peuvent être exécutés dans le navigateur ?

= Méthodologie de validation

Les décisions importantes doivent être accompagnées d'une justification technique et, lorsque cela est possible, d'une validation expérimentale.

Le cycle de conception privilégié est :

#mermaid(
  "
  flowchart LR
    P[Problème]       --> H[Hypothèse]
    H                 --> C[Conception]
    C                 --> I[Implémentation]
    I                 --> E[Expérience]
    E                 --> M[Mesure]
    M                 --> A[Analyse]
    A                 --> D[Décision]
  ",
  document-context: true,
  width: 100%,
)

Cette approche permet d'éviter de choisir une technologie uniquement sur la base de ses caractéristiques théoriques.

Elle permet également de transformer certaines parties du projet en contributions mesurables dans le cadre du projet spécial.

= Évolution prévue du document

Ce document constitue une première photographie de l'architecture.

Les sections suivantes devraient progressivement être complétées par :

- les exigences fonctionnelles et non fonctionnelles ;
- un modèle de menace formel ;
- les ADR ;
- les diagrammes de déploiement ;
- les protocoles entre composants ;
- la définition des interfaces du moteur de jugement ;
- la méthodologie de benchmark ;
- les résultats expérimentaux ;
- les décisions prises à la suite des expériences ;
- les limites identifiées ;
- les conclusions.
