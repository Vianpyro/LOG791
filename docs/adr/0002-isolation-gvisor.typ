#import "../template.typ": validation

== ADR-0002 — gVisor comme mécanisme d'isolation initial

*Statut :* accepté pour la première implémentation ; comparaison avec Firecracker prévue. \
*Voir aussi :* architecture, section « Isolation des soumissions ».

=== Contexte

Le code étudiant est non fiable. Un conteneur classique partage le noyau de l'hôte et n'est pas une frontière de sécurité suffisante à lui seul. La plateforme tourne elle-même dans une VM fournie par l'établissement, où la virtualisation imbriquée (KVM) n'est pas garantie.

=== Options considérées

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Avantages*], [*Inconvénients*],
  [gVisor (Systrap)], [Noyau applicatif en espace utilisateur ; fonctionne sans KVM ; s'intègre à Docker/Podman comme runtime OCI ; éprouvé dans CTester.], [Surcoût sur les appels système ; certaines limites cgroup ne comptent pas les processus internes.],
  [Firecracker], [Frontière forte (microVM sous KVM).], [Exige KVM, donc la virtualisation imbriquée ; cycle de vie des microVM à gérer.],
  [WebAssembly], [Sandbox forte par construction.], [Chaîne d'outils et bibliothèques par langage ; ne couvre pas un cours multi-langage général.],
  [Conteneur seul (runc)], [Le plus simple et le plus rapide.], [Frontière insuffisante contre du code hostile.],
)

=== Décision

gVisor en mode Systrap, piloté par un runtime de conteneur, est retenu pour la première implémentation.

=== Conséquences

- Le choix de Docker ou Podman devient secondaire : c'est le runtime OCI qui porte l'isolation.
- Les limites doivent être vérifiées par leur *résultat* (l'hôte ne bouge pas) plutôt que par leur mécanisme, puisque certains contrôles cgroup ne voient pas l'intérieur du sandbox.
- L'abstraction de sandbox du juge doit rester indépendante de gVisor pour permettre la comparaison.

#validation(id: "V-0002")[
  Comparer gVisor et Firecracker sur une charge identique : démarrage, latence, débit, CPU et mémoire, et comportement face aux soumissions hostiles. Vérifier la disponibilité de KVM sur la VM de l'établissement.
]
