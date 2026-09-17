#import "../template.typ": validation

== ADR-0009 — Vérification de Safe Exam Browser par le serveur

*Statut :* proposé ; à valider sous SEB. \
*Voir aussi :* architecture, section « Safe Exam Browser » ; ADR-0008.

=== Contexte

En examen, la plateforme doit refuser un navigateur autre que Safe Exam Browser (SEB), ou un SEB lancé avec une autre configuration. L'examen peut démarrer dans Moodle, puis passer à la plateforme par LTI : la vérification faite par Moodle ne couvre alors pas les requêtes adressées à la plateforme.

=== Options considérées

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Avantages*], [*Inconvénients*],
  [User-Agent], [Trivial.], [Falsifiable ; ne prouve rien.],
  [Se fier à Moodle (`quizaccess_seb`)],
  [Rien à écrire.],
  [Ne protège pas les requêtes adressées directement à la plateforme.],

  [Vérifier la Config Key sur chaque requête d'examen],
  [Lie l'accès à un fichier `.seb` précis.],
  [Il faut reconstruire l'URL d'origine derrière nginx.],
)

=== Décision

Sur les routes d'examen, l'API vérifie l'en-tête `X-SafeExamBrowser-ConfigKeyHash`, égal au SHA-256 de l'URL complète concaténée à la Config Key. Derrière nginx, l'URL est reconstruite à partir de `X-Forwarded-Proto` et `X-Forwarded-Host`. Pour les appels `fetch` et le flux SSE, le client transmet aussi la valeur de l'API JavaScript `SafeExamBrowser.security.configKey`. Le User-Agent sert seulement d'indice.

La Config Key attendue est enregistrée avec l'examen dans PostgreSQL et fournie par l'enseignant. Le fichier `.seb` reste chez l'enseignant, qui le distribue par Moodle ou le chiffre par mot de passe. Le dépôt, qui peut être public, ne contient aucun `.seb` ni aucune Config Key : quiconque connaît la clé peut forger l'en-tête.

=== Conséquences

- À chaque modification du `.seb`, l'enseignant met à jour la Config Key de l'examen.
- La Config Key est traitée comme un secret.
- Le filtre d'URL de SEB permet la plateforme et `login.microsoftonline.com`, et aucun CDN.
- Une requête d'examen sans empreinte valide est refusée.

#validation(id: "V-0009")[
  Sous SEB Windows avec le `.seb` de l'examen : l'accès fonctionne. Hors SEB ou avec une autre configuration, il est refusé. Vérifier aussi que la connexion Entra, l'exécution Pyodide et le flux SSE fonctionnent.
]
