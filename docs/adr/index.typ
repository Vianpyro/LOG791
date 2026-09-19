#import "../template.typ": adr

// Typst cannot list a directory: a new ADR must be added here.
// An ADR is never modified after acceptance; it is superseded by a new one
// that cites it ("supersedes ADR-000N").

= Architecture decision log <adr-log>

#table(
  columns: (2.2cm, 1fr, 3.5cm),
  stroke: 0.5pt,
  [*ADR*], [*Decision*], [*Status*],
  [#adr("0001", body: "0001")], [Submission queue in PostgreSQL], [Accepted, to validate],
  [#adr("0002", body: "0002")], [gVisor as initial isolation], [Accepted, to compare],
  [#adr("0003", body: "0003")], [NixOS for the VM], [Superseded (#adr("0006", body: "0006"))],
  [#adr("0004", body: "0004")], [Monorepo], [Accepted],
  [#adr("0005", body: "0005")], [Content publishing through immutable releases], [Accepted],
  [#adr("0006", body: "0006")], [Ubuntu and Ansible for the VM], [Accepted, to validate],
  [#adr("0007", body: "0007")], [Performance measurement by instruction counting], [Proposed],
  [#adr("0008", body: "0008")], [Visible tests run in the browser], [Proposed],
  [#adr("0009", body: "0009")], [Server-side verification of Safe Exam Browser], [Proposed],
  [#adr("0010", body: "0010")], [Multiple replicable, fault-tolerant VMs], [Proposed],
  [#adr("0011", body: "0011")], [User interface internationalization], [Proposed],
  [#adr("0012", body: "0012")], [Courses, offerings and per-course roles], [Proposed],
  [#adr("0013", body: "0013")], [Language packs and test runners], [Proposed],
  [#adr("0014", body: "0014")], [Stable core and extension points], [Proposed],
  [#adr("0015", body: "0015")], [Question types and mixed assessments], [Proposed],
  [#adr("0016", body: "0016")], [Mermaid diagrams in statements], [Proposed],
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
#include "0015-question-types.typ"
#include "0016-mermaid-statements.typ"
