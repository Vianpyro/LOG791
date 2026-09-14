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
  [0003], [NixOS pour la VM], [Proposé],
  [0004], [Monorepo], [Accepté],
  [0005], [Publication du contenu par releases immuables], [Accepté],
)

#include "0001-file-postgresql.typ"
#include "0002-isolation-gvisor.typ"
#include "0003-nixos.typ"
#include "0004-monorepo.typ"
#include "0005-publication-contenu.typ"
