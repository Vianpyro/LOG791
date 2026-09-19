#import "../template.typ": adr, arch, ext, validation

== ADR-0003 — NixOS for VM configuration <adr-0003>

*Status:* superseded by #adr("0006") (the institution provides an Ubuntu VM). \
*See also:* #arch("purpose-of-the-document")[architecture], section #arch("infrastructure")[Infrastructure].

=== Context

The infrastructure must be rebuildable from the repository. In #ext("ctester")[CTester], the configuration lives in a separate #ext("ansible")[Ansible] role (`VHome`), and several failures only surfaced in production because a configuration fact lived in one repository and its dependency in another.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Pros*], [*Cons*],
  [#ext("nixos")[NixOS]],
  [Declarative, versioned configuration; generations and rollback of the whole system.],
  [Learning curve; may not be supported by the infrastructure team.],

  [Classic distribution + Ansible],
  [Well known, supported; already used for CTester.],
  [Imperative convergence: the actual state can drift from what the repository describes.],

  [Classic distribution + container images],
  [Reproducible application.],
  [The host (runtime, #ext("gvisor")[gVisor], firewall) is still configured by hand.],
)

=== Decision

NixOS is the preferred system for the main VM if the institution allows it. Ansible is only kept for orchestration that is not part of a machine's permanent state.

=== Consequences

- A single source of truth for a machine's state.
- Rolling back a system update means switching to a previous generation, which reduces risk ahead of an exam.
- If NixOS is refused, this decision is superseded by a new ADR; the others do not depend on it.

#validation(id: "V-0003")[
  Obtain the position of the ÉTS infrastructure team and check gVisor compatibility with the chosen NixOS version.
]
