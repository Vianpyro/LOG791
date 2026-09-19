#import "../template.typ": validation

== ADR-0007 — Mesure déterministe et équitable de la performance

*Statut :* proposé ; prototype à réaliser, modèle de notation à trancher avec l'enseignant. \
*Voir aussi :* architecture, sections « Gestion des ressources » et « Charge et performance » ; ADR-0001, ADR-0002.

=== Contexte

Un exercice peut évaluer la performance d'une solution, et non seulement sa correction. On cherche à évaluer l'algorithme, pas le langage ni la machine. Deux obstacles s'y opposent :

- *Le bruit.* Le temps réel et le temps CPU varient avec la charge de la VM, le temps volé par l'hyperviseur, le cache et la fréquence du processeur. Sur une VM partagée, l'écart atteint 5 à 30 %, ce qui ne permet pas de départager des solutions.
- *Le langage.* Un même algorithme est 10 à 100 fois plus lent en Python qu'en Rust, et ce facteur varie selon les opérations. Un multiplicateur fixe par langage reste donc approximatif.

La plateforme tourne sous gVisor (ADR-0002), dans une VM où KVM n'est pas garanti. `perf_event_open` n'y est pas disponible dans le sandbox.

=== Options considérées

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Avantages*], [*Inconvénients*],
  [Temps réel ou temps CPU], [Aucun surcoût ; simple.], [Bruit de 5 à 30 % ; dépend du langage.],
  [Compteurs matériels (`perf`)],
  [Précis, sans ralentissement.],
  [Rarement exposés dans une VM ; indisponibles sous gVisor.],

  [Valgrind (`callgrind`)],
  [Compte d'instructions déterministe.],
  [Ralentissement de 20 à 100$times$ ; fragile avec le JIT de la JVM.],

  [QEMU en mode utilisateur avec un plugin de comptage d'instructions],
  [Compte déterministe ; ni KVM ni compteurs matériels requis ; ralentissement de 5 à 10$times$.],
  [Compatibilité avec gVisor Systrap à confirmer.],
)

=== Décision

*Mesure.* La performance est mesurée en *instructions exécutées*, sous QEMU en mode utilisateur (`qemu-x86_64 -plugin libinsn.so`), et non en temps. Pour que chaque runtime se comporte de façon déterministe :

- les processus sont limités à un seul thread ;
- les entrées et la graine d'aléa sont fixes ;
- Python utilise `PYTHONHASHSEED=0` ;
- la JVM utilise `-Xbatch` et un tas de taille fixe.

Le comptage n'est actif que pendant l'appel de la fonction de l'élève, grâce à un marqueur émis par le harnais. La lecture des entrées, dont le coût dépend fortement du langage, est donc exclue.

*Neutralisation du langage.* L'élève n'est comparé qu'à une solution de référence *du même langage*. Le critère principal est la *complexité* : on mesure plusieurs tailles d'entrée, puis on calcule la pente log-log des écarts d'instructions entre tailles, ce qui retire le coût de démarrage. Cette pente ne dépend pas du langage. Deux modèles de notation restent à trancher avec l'enseignant :

- *Verdict de complexité* : on vérifie que la pente ne dépasse pas celle de la référence, à une tolérance près. Une seule référence par exercice suffit.
- *Classement complet* : on classe d'abord par complexité, puis par le rapport au nombre d'instructions de la référence du même langage. Il faut une référence par langage et par exercice.

La mémoire suit la même logique : on compare le pic de mémoire, moins la ligne de base du runtime, à celui de la référence.

*Deux passes.* La mesure ralentit l'exécution. Elle n'est donc jamais faite pendant que l'élève attend une réponse :

- *Passe de correction* : exécution native, avec des limites de temps généreuses. C'est la seule qui répond pendant l'examen.
- *Passe de mesure* : elle se fait après l'examen et ne porte que sur la *dernière* soumission de chaque élève pour chaque exercice (une clé unique par couple élève–exercice). La file est vidée quand le serveur est peu chargé. La précision n'en dépend pas ; il s'agit de laisser le CPU au jugement en direct.

La file de mesure est une file de priorité inférieure dans PostgreSQL (ADR-0001). Aucun nouveau composant n'est ajouté.

=== Conséquences

- La limite d'exécution de la passe de mesure est un *budget d'instructions*. Un timeout en temps réel large reste en place comme filet de sécurité.
- Comme le résultat est déterministe, la passe de mesure peut surcharger une machine, ou tourner sur une autre machine, sans fausser les mesures.
- *Données de mesure.* Elles sont distinctes des tests. De grandes entrées sont produites par un générateur de l'enseignant, avec une graine choisie au moment de la mesure, et les sorties sont revérifiées.
- *Versions figées.* Les versions des runtimes sont figées pour une session. Les références sont remesurées avec les mêmes images à chaque release du contenu.
- *Contestations.* Pour pouvoir refaire une mesure identique, on conserve le code source, l'image, la release du contenu, la graine et le nombre d'instructions.
- *Délai.* Il faut prévoir le temps de calcul avant la remise des notes : élèves $times$ exercices $times$ tailles $times$ durée d'une mesure sous QEMU.
- *Bibliothèques.* L'enseignant précise pour chaque exercice les bibliothèques permises, par exemple `sorted()` ou `heapq`.
- *Questions à trancher avec l'enseignant :*
  - le choix du modèle de notation ;
  - la mesure, ou non, d'un code qui ne passe pas tous les tests ;
  - la soumission à mesurer si la dernière échoue alors qu'une précédente passait ;
  - la présentation du résultat à l'élève (par exemple « O(n log n), 1,8$times$ la référence »).

#validation(id: "V-0007")[
  Mesurer un tri en O(n²) et un tri en O(n log n) en Python, Java et Rust, sous QEMU et à l'intérieur de gVisor. Répéter chaque mesure 30 fois, avec et sans `stress-ng` sur la VM. Critères :
  - un coefficient de variation inférieur à 0,1 % ;
  - une pente qui sépare les deux tris dans les trois langages ;
  - des rapports à la référence du même ordre d'un langage à l'autre.
]
