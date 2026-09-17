#import "../template.typ": validation

== ADR-0008 — Exécution des tests visibles dans le navigateur

*Statut :* proposé ; le gain est à chiffrer par test de charge. \
*Voir aussi :* architecture, sections « WebAssembly », « Charge et performance » et « Mode d'examen » ; ADR-0001, ADR-0007.

=== Contexte

En examen, le temps qu'un élève passe à attendre la file est perdu sur son temps d'examen. Le rendre n'est pas visé, car Moodle et Enaquiz ne le permettent vraisemblablement pas. Le projet cherche plutôt à réduire l'attente causée par la plateforme elle-même.

Chaque exercice est remis automatiquement à la fin de l'examen. Pendant l'examen, le serveur ne reçoit donc que des *exécutions de test*, lancées quand l'élève clique sur « tester ». La remise finale n'attend aucune réponse immédiate : sa correction et sa mesure (ADR-0007) passent en différé.

Chaque exercice comporte une dizaine de tests visibles et des tests cachés. Pour chaque test visible, l'élève voit la sortie attendue et la sortie obtenue. Pour les tests cachés, il voit seulement si au moins un échoue.

Le serveur est situé à l'ÉTS, sur le même réseau que les salles d'examen.

=== Options considérées

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Avantages*], [*Inconvénients*],
  [Tout exécuter sur le serveur],
  [Un seul chemin d'exécution, fidèle au juge.],
  [Chaque clic occupe la file, même pour un test visible qui échoue.],

  [Tests visibles dans le navigateur pour tous les langages],
  [Charge serveur minimale.],
  [Irréaliste pour Java, Rust ou Go.],

  [Tests visibles dans le navigateur pour les langages où c'est facile],
  [Chaque langage déchargé raccourcit la file de tous ; les tests visibles sont publics, donc rien ne fuit.],
  [Deux chemins d'exécution ; risque d'écart avec le juge.],
)

=== Décision

Les tests visibles s'exécutent dans le navigateur pour *chaque langage supporté pour lequel c'est facile*. Un langage est jugé facile s'il remplit trois critères :

- un runtime maintenu, préchargé en une seule fois et pesant au plus quelques dizaines de Mo ;
- une version qui peut être alignée sur celle du juge ;
- aucune licence restrictive.

Les autres langages restent exécutés sur le serveur.

#table(
  columns: (2.6cm, 1fr, 3.2cm),
  stroke: 0.5pt,
  [*Langage*], [*Runtime navigateur*], [*Verdict*],
  [Python], [Pyodide], [Retenu],
  [JavaScript], [Natif (Web Worker)], [Retenu],
  [TypeScript], [Natif, après transpilation par esbuild-wasm], [Retenu],
  [Lua], [wasmoon], [Retenu],
  [Ruby, PHP], [ruby.wasm, php-wasm], [À vérifier],
  [C, C++], [clang compilé en WASM (30 à 100 Mo)], [À évaluer],
  [C\#], [Roslyn et .NET en WASM], [De côté],
  [Java], [CheerpJ (licence) ou javac et TeaVM], [De côté],
  [Rust, Go], [Aucun compilateur pratique], [De côté],
)

Seuls les langages effectivement supportés par un cours sont concernés.

Déroulement d'une exécution de test pour un langage retenu :

+ Les tests visibles s'exécutent dans un Web Worker, et les résultats s'affichent au fur et à mesure.
+ Le code n'est envoyé au serveur *que si tous les tests visibles passent*. La plupart des essais échouent sur un test visible et ne sollicitent donc jamais le serveur.
+ Le serveur exécute les tests cachés, et aussi les tests visibles. Le coût principal est le démarrage du sandbox et la compilation. Les tests visibles coûtent donc peu de plus, et ils permettent de détecter un écart entre le navigateur et le juge, signalé à l'élève.

Pour les autres langages, le code est envoyé directement au serveur.

Les résultats du serveur arrivent par *Server-Sent Events*, dans un flux unique par élève. Le juge prévient l'API au moyen de `LISTEN`/`NOTIFY` de PostgreSQL. Aucun nouveau composant n'est ajouté.

Côté serveur, les exécutions de test partagent un même sandbox et une seule compilation. Les élèves sont servis à tour de rôle, avec au plus une exécution en cours par élève. Une nouvelle demande remplace la précédente si celle-ci n'a pas encore démarré. Les tests cachés s'arrêtent au premier échec.

=== Conséquences

- Pour chaque langage retenu, le runtime du juge a la même version que celui du navigateur ; par exemple, la version de Pyodide fixe celle de CPython. Les paquets permis sont les mêmes des deux côtés.
- Le serveur reste la référence : le résultat du navigateur est présenté comme indicatif.
- Les runtimes sont préchargés au début de l'examen par un service worker. Une boucle infinie est interrompue par `terminate()` sur le Web Worker.
- Le flux SSE exige de désactiver la mise en tampon dans nginx. Après une coupure, il reprend grâce à `Last-Event-ID` ; si le flux ne fonctionne pas, le client interroge le serveur périodiquement.
- La compatibilité avec Safe Exam Browser (WebAssembly, Web Workers, service workers) doit être vérifiée.

#validation(id: "V-0008")[
  Test de charge d'examen (environ 400 élèves) : comparer le 95#super[e] centile du délai entre le clic sur « tester » et la réponse du serveur, avec et sans exécution dans le navigateur. Mesurer, pour chaque langage retenu, le taux d'écart entre le navigateur et le juge. Vérifier le fonctionnement sous Safe Exam Browser.
]
