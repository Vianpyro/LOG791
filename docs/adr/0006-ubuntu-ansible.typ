#import "../template.typ": validation

== ADR-0006 — Ubuntu and Ansible for VM configuration

*Status:* accepted. Supersedes ADR-0003. \
*See also:* architecture, section "Infrastructure".

=== Context

The institution provides a VM running Ubuntu LTS; NixOS (ADR-0003) is not retained. The infrastructure must nevertheless be rebuildable from the repository, and the CTester failures caused by configuration spread across several repositories must not happen again.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Pros*], [*Cons*],
  [Ubuntu + Ansible in the monorepo],
  [Well known, supported by the institution; already used for CTester; versioned with the application.],
  [Imperative convergence: the actual state can drift; no native system rollback.],

  [Ubuntu + container images only],
  [Reproducible application.],
  [The host (runtime, gVisor, firewall) is still configured by hand.],
)

=== Decision

Ubuntu LTS, configured by idempotent Ansible playbooks versioned in the monorepo. Ansible holds all of the host's permanent state: packages, container runtime, gVisor (`runsc` from the official apt repository), firewall, nginx and certbot, users, logging.

=== Consequences

- A single source of truth for a machine's state: the repository's playbooks. Any manual change is carried back into them.
- Drift is detected by regularly running the playbooks in `--check --diff` mode.
- Without system generations, rollback relies on a VM snapshot before each update and on pinned package versions.
- `unattended-upgrades` is limited to security fixes and suspended ahead of an exam.

#validation(id: "V-0006")[
  Confirm with the ÉTS infrastructure team that VM snapshots and `sudo` access for Ansible are available; check that gVisor works on the provided Ubuntu kernel.
]
