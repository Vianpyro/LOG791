#import "@preview/cetz:0.3.4"
#import "@preview/fletcher:0.5.8"
#import "@preview/merman:0.3.0": mermaid

#set document(
  title: "Architecture de la plateforme d'apprentissage et d'évaluation de la programmation",
  author: "Vianney Veremme",
  date: datetime.today(),
)

#set page(
  paper: "a4",
  margin: (
    top: 2.2cm,
    bottom: 2.2cm,
    left: 2.4cm,
    right: 2.4cm,
  ),
  numbering: "1",
)

#set text(
  font: "New Computer Modern",
  size: 10.5pt,
)

#set heading(numbering: "1.1")

#show link: set text(fill: blue)

#let decision(body) = block(
  fill: luma(245),
  inset: 10pt,
  radius: 3pt,
  width: 100%,
)[
  *Décision actuelle.* #body
]

#let hypothesis(body) = block(
  fill: luma(250),
  inset: 10pt,
  radius: 3pt,
  width: 100%,
)[
  *Hypothèse.* #body
]

#let validation(body) = block(
  fill: luma(250),
  inset: 10pt,
  radius: 3pt,
  width: 100%,
)[
  *À valider.* #body
]

#align(center)[
  #text(size: 22pt, weight: "bold")[
    Architecture de la plateforme
  ]

  #v(0.4cm)

  #text(size: 15pt)[
    Plateforme d'apprentissage et d'évaluation
    de la programmation
  ]

  #v(1.2cm)

  Version 0 — document de conception initiale

  #v(0.4cm)

  Vianney Veremme

  #v(0.2cm)

  École de technologie supérieure
]

#pagebreak()

= Objet du document

Ce document présente l'architecture envisagée pour une plateforme d'apprentissage et d'évaluation de la programmation destinée initialement au cours LOG200 de l'École de technologie supérieure.

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

  [Performance],
  [Maintenir une latence acceptable même lors de fortes concentrations de   soumissions.],

  [Scalabilité],
  [Permettre d'augmenter la capacité de jugement indépendamment de la capacité de l'application principale.],

  [Reproductibilité],
  [Pouvoir reconstruire l'infrastructure et les environnements de déploiement de manière automatisée.],

  [Extensibilité],
  [Ajouter un langage ou un type d'exercice sans modifier inutilement le reste du système.],

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

== Application et API

L'application web constitue la partie responsable de l'état pédagogique.

Elle ne doit pas dépendre de la présence d'un processus de compilation local. Une soumission est plutôt représentée comme un travail pouvant être placé dans une file.

Cela permet de découpler :

- le nombre de requêtes HTTP ;
- le nombre de soumissions en attente ;
- le nombre de juges disponibles ;
- le nombre d'exécutions simultanées.

== Couche d'entrée

La plateforme est initialement déployée sur une VM unique dont les ressources sont limitées. Chaque composant d'infrastructure supplémentaire consomme de la mémoire et du CPU qui ne sont plus disponibles pour le jugement.

#decision[
  Un composant d'infrastructure n'est ajouté que lorsqu'un besoin mesuré le justifie.
]

=== Reverse proxy

Un reverse proxy nginx constitue le seul point d'entrée HTTP de la plateforme. Il est responsable de :

- la terminaison TLS (certificats gérés par NixOS via ACME) ;
- la distribution des fichiers statiques de l'interface web ;
- la compression des réponses ;
- la limitation du débit des requêtes (`limit_req`), notamment sur les soumissions ;
- le relais des connexions longues (SSE ou WebSocket) utilisées pour notifier les verdicts.

#decision[
  nginx est retenu pour sa faible empreinte mémoire, sa limitation de débit native et son intégration déclarative dans NixOS.
]

#hypothesis[
  Si l'établissement termine déjà le TLS en amont de la VM, nginx demeure utile pour les fichiers statiques et la limitation de débit.
]

=== Répartition de charge

Aucun load balancer dédié n'est prévu dans la topologie initiale.

- Côté HTTP, l'API est exécutée par plusieurs processus (workers uvicorn) partageant la même socket ; le noyau répartit les connexions entre eux.
- Côté jugement, les juges _tirent_ les travaux de la file plutôt que de les recevoir. La file joue donc elle-même le rôle de répartiteur, et la capacité s'ajuste en modifiant le nombre de juges.

#decision[
  Un load balancer (par exemple un bloc `upstream` nginx) ne sera introduit que si l'application est répartie sur plusieurs VM.
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

[Temps],
[Timeout maximal par étape et par soumission.],

[CPU],
[Nombre de cœurs ou quantité de CPU utilisable.],

[Mémoire],
[Limite de mémoire par exécution.],

[Processus],
[Nombre maximal de processus ou threads.],

[Stockage],
[Espace temporaire maximal.],

[Réseau],
[Accès réseau explicitement refusé ou limité.],
)

Ces limites doivent être appliquées indépendamment de la correction du programme.

Un programme qui boucle infiniment doit produire un timeout plutôt que consommer indéfiniment une ressource du système.

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

  [API],
  [Données d'exercice publiées, peu modifiées, conservées en mémoire du processus.],

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
- le taux d'échec de l'infrastructure.

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

L'intégration avec Moodle et les mécanismes de vérification de configuration de SEB devront être étudiés séparément.

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

    VM --> N[NixOS]

    N --> SYS[Système]
    N --> SEC[Sécurité]
    N --> SVC[Services]

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

NixOS est envisagé comme système d'exploitation de référence pour la VM principale, sous réserve de l'acceptation et du support de cette distribution par l'équipe responsable de l'infrastructure de l'établissement.

NixOS permet de décrire de manière déclarative une grande partie de la configuration du système. La configuration peut ainsi être versionnée avec le reste du projet et reconstruite à partir du dépôt.

Le modèle recherché est :

#mermaid(
  "
  flowchart LR
    Git   --> NixOS[Configuration NixOS]
    NixOS --> Build[Build/déploiment]
    Build --> VM
    VM    --> A[État système reproductible]
  ",
  document-context: true,
  width: 100%,
)

La configuration peut notamment décrire :

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
  NixOS est le système d'exploitation privilégié pour la VM principale si l'établissement autorise son utilisation et si son équipe d'administration peut raisonnablement en assurer l'exploitation.
]

Le choix de NixOS n'est pas motivé par une recherche de performance du système d'exploitation. Son intérêt principal est la reproductibilité et le caractère déclaratif de la configuration.

Il permet également de conserver différentes générations d'une configuration et de revenir à une génération précédente en cas de problème.

#hypothesis[
  La reproductibilité et les possibilités de rollback de NixOS peuvent réduire le risque opérationnel lors des mises à jour de la plateforme, notamment à l'approche d'une période d'évaluation.
]

== Rôle d'Ansible

L'utilisation de NixOS réduit le besoin d'utiliser Ansible pour configurer individuellement les machines.

Ansible peut néanmoins rester pertinent pour des opérations qui ne constituent pas l'état permanent du système, par exemple :

- l'orchestration de plusieurs machines ;
- certaines opérations de déploiement ;
- des tâches administratives ;
- la coordination d'une mise à jour ;
- des environnements qui ne peuvent pas utiliser NixOS.

La frontière recherchée est donc :

```text
Terraform
    │
    └── Provisionnement de l'infrastructure

NixOS
    │
    └── État déclaratif de la machine

Ansible
    │
    └── Orchestration et opérations lorsque nécessaire

CI/CD
    │
    └── Construction et déploiement de l'application
```

#decision[
  Ansible n'est plus considéré comme le mécanisme obligatoire de configuration des machines. Lorsque NixOS est disponible, la configuration persistante du système doit autant que possible être déclarée dans NixOS.
]

Cette organisation évite de maintenir simultanément plusieurs sources de vérité pour la configuration d'une même machine.

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

```text
Git push
   │
   ▼
Tests
   │
   ├── tests unitaires
   ├── tests d'intégration
   └── tests de sécurité
   │
   ▼
Build
   │
   ├── Web
   ├── API
   └── Judge
   │
   ▼
Images / artefacts
   │
   ▼
Registry / artefact storage
   │
   ▼
Déploiement
   │
   ├── environnement de validation
   │
   └── production
```

La configuration NixOS doit elle-même être testée et versionnée dans le même cycle de développement.

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
│   ├── nixos/
│   │   ├── flake.nix
│   │   ├── hosts/
│   │   ├── modules/
│   │   └── services/
│   │
│   ├── terraform/
│   │
│   └── ansible/
│
├── deployment/
│
├── tests/
│
├── docs/
│
└── .github/
```

Le répertoire `infrastructure/nixos/` contient la configuration déclarative des machines administrées par le projet.

Le répertoire `terraform/` contient uniquement les ressources effectivement gérées par Terraform.

Le répertoire `ansible/` peut contenir les opérations d'orchestration qui ne sont pas naturellement exprimées comme configuration NixOS.

#decision[
  Le monorepo est privilégié afin de conserver une version cohérente de l'application, du moteur de jugement, du contenu pédagogique et de l'infrastructure.
]

Les frontières entre composants doivent néanmoins rester explicites.

Un monorepo ne signifie pas que tous les composants partagent le même code, le même langage ou le même cycle de déploiement.

= Sécurité

== Principe de défense en profondeur

La sécurité de l'exécution ne repose pas sur le système d'exploitation ou sur un seul mécanisme d'isolation.

Une exécution doit idéalement traverser plusieurs niveaux de protection :

```text
Student code
     │
     ▼
Application validation
     │
     ▼
Judge
     │
     ▼
Resource limits
     │
     ▼
Container / runtime
     │
     ▼
gVisor / microVM
     │
     ▼
NixOS / Linux host
     │
     ▼
VM de l'établissement
```

Chaque couche doit réduire les conséquences potentielles d'une défaillance d'une autre couche.

Le rôle de NixOS dans cette architecture est principalement de fournir un environnement système reproductible et administrable. Il ne constitue pas à lui seul la frontière d'isolation des programmes étudiants.

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
    subgraph VM[VM NixOS]
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
  L'organisation finale des composants entre une ou plusieurs VM devra être déterminée en fonction des ressources disponibles, du modèle de menace et des résultats des tests de charge.
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

```text
                Git repository
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
   Application source       Infrastructure
                                  │
                                  ▼
                              NixOS config
                                  │
                                  ▼
                                 VM
                                  │
                                  ▼
                         Services configurés
                                  │
                                  ▼
                           Application
```

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

[OS principal],
[NixOS si accepté par l'établissement],
[Compatibilité avec l'infrastructure et capacité d'administration],

[Provisionnement],
[Terraform si une API compatible est disponible],
[Capacités réelles de l'environnement ÉTS],

[Configuration],
[NixOS déclaratif],
[Reproductibilité et déploiement],

[Orchestration],
[Ansible lorsque nécessaire],
[Besoin réel après adoption de NixOS],

[Runtime],
[Docker ou Podman],
[Compatibilité avec le mécanisme d'isolation],

[Isolation],
[gVisor initialement envisagé],
[Benchmark et tests de sécurité],

[Alternative d'isolation],
[Firecracker],
[Benchmark comparatif],

[Topologie],
[Une ou plusieurs VM],
[Charge, sécurité et ressources disponibles],

[Reverse proxy],
[nginx, sans load balancer dédié],
[Prise en charge du TLS par l'établissement],

[File],
[PostgreSQL (`SKIP LOCKED`)],
[Tests de charge d'examen],

[Cache],
[Aucun service dédié ; cache côté juge],
[Profilage du coût d'une soumission],
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
10. Quelle quantité d'état doit être persistée dans PostgreSQL ?
11. Comment garantir la reprise après panne d'un worker ?
12. Quelle observabilité est nécessaire pour diagnostiquer un examen en cours ?
13. Comment intégrer proprement Moodle et Safe Exam Browser ?
14. Quelle partie de l'architecture doit être commune aux différents cours ?

= Méthodologie de validation

Les décisions importantes doivent être accompagnées d'une justification technique et, lorsque cela est possible, d'une validation expérimentale.

Le cycle de conception privilégié est :

```text
Problème
   ↓
Hypothèse
   ↓
Conception
   ↓
Implémentation
   ↓
Expérience
   ↓
Mesure
   ↓
Analyse
   ↓
Décision
```

Cette approche permet d'éviter de choisir une technologie uniquement sur la base de ses caractéristiques théoriques.

Elle permet également de transformer certaines parties du projet en contributions mesurables dans le cadre du projet de fin d'études.

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

#v(1cm)

#align(center)[
*Version 0 — Architecture initiale*
]

=== Ce que je changerais déjà par rapport à une simple documentation technique

Le point le plus important est que ce document **ne dit pas seulement “voici notre architecture”**. Il commence à constituer la trace du raisonnement du PFE :

```text
                  PROBLÈME
                     │
                     ▼
               CONTRAINTES
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
       sécurité   performance  pédagogie
          │          │          │
          └──────────┼──────────┘
                     ▼
                ARCHITECTURE
                     │
                     ▼
                 HYPOTHÈSES
                     │
                     ▼
                EXPÉRIMENTS
                     │
                     ▼
                  MESURES
                     │
                     ▼
                 DÉCISIONS
```
