// Typst ne sait pas lister un répertoire : une ADR ajoutée doit l'être ici.
// Une ADR n'est jamais modifiée après acceptation ; elle est remplacée par une
// nouvelle qui la cite (« remplace ADR-000N »).

= Registre des décisions d'architecture

#table(
  columns: (2.2cm, 1fr, 3.5cm),
  stroke: 0.5pt,
  [*ADR*], [*Décision*], [*Statut*],
  [0001], [File de soumissions dans PostgreSQL], [Accepté, à valider],
  [0002], [gVisor comme isolation initiale], [Accepté, à comparer],
  [0003], [NixOS pour la VM], [Remplacé (#link(<adr-0006>)[0006])],
  [0004], [Monorepo], [Accepté],
  [0005], [Publication du contenu par releases immuables], [Accepté],
  [0006 <adr-0006>], [Ubuntu et Ansible pour la VM], [Accepté, à valider],
  [0007], [Mesure de performance par comptage d'instructions], [Proposé],
  [0008], [Tests visibles exécutés dans le navigateur], [Proposé],
  [0009], [Vérification de Safe Exam Browser par le serveur], [Proposé],
  [0010], [Plusieurs VM répliquables et tolérantes aux pannes], [Proposé],
)

#include "0001-file-postgresql.typ"
#include "0002-isolation-gvisor.typ"
#include "0003-nixos.typ"
#include "0004-monorepo.typ"
#include "0005-publication-contenu.typ"
#include "0006-ubuntu-ansible.typ"
#include "0007-mesure-performance.typ"
#include "0008-tests-visibles-navigateur.typ"
#include "0009-verification-seb.typ"
#include "0010-topologie-multi-vm.typ"
