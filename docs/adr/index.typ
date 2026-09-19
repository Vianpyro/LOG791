// Typst cannot list a directory: a new ADR must be added here.
// An ADR is never modified after acceptance; it is superseded by a new one
// that cites it ("supersedes ADR-000N").

= Architecture decision log

#table(
  columns: (2.2cm, 1fr, 3.5cm),
  stroke: 0.5pt,
  [*ADR*], [*Decision*], [*Status*],
  [0001], [Submission queue in PostgreSQL], [Accepted, to validate],
  [0002], [gVisor as initial isolation], [Accepted, to compare],
  [0003], [NixOS for the VM], [Superseded (#link(<adr-0006>)[0006])],
  [0004], [Monorepo], [Accepted],
  [0005], [Content publishing through immutable releases], [Accepted],
  [0006 <adr-0006>], [Ubuntu and Ansible for the VM], [Accepted, to validate],
  [0007], [Performance measurement by instruction counting], [Proposed],
  [0008], [Visible tests run in the browser], [Proposed],
  [0009], [Server-side verification of Safe Exam Browser], [Proposed],
  [0010], [Multiple replicable, fault-tolerant VMs], [Proposed],
  [0011], [User interface internationalization], [Proposed],
  [0012], [Courses, offerings and per-course roles], [Proposed],
  [0013], [Language packs and test runners], [Proposed],
  [0014], [Stable core and extension points], [Proposed],
)

#include "0001-postgresql-queue.typ"
#include "0002-gvisor-isolation.typ"
#include "0003-nixos.typ"
#include "0004-monorepo.typ"
#include "0005-content-publishing.typ"
#include "0006-ubuntu-ansible.typ"
#include "0007-performance-measurement.typ"
#include "0008-visible-tests-in-browser.typ"
#include "0009-seb-verification.typ"
#include "0010-multi-vm-topology.typ"
#include "0011-ui-internationalization.typ"
#include "0012-multi-course-roles.typ"
#include "0013-language-packs.typ"
#include "0014-extension-points.typ"
