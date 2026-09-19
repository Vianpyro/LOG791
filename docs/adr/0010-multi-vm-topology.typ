#import "../template.typ": validation

== ADR-0010 — Multiple replicable, fault-tolerant VMs

*Status:* proposed. Refines ADR-0001 and ADR-0006, which assumed a single VM. \
*See also:* architecture, sections "Entry layer" and "Infrastructure".

=== Context

The MVP targets about 50 students. The platform must then serve all instructors of the ÉTS LOG/TI department and their groups, as well as part of the DEG. At that scale, the institution is unlikely to provide a single large VM. Moreover, a single VM is a single point of failure: an outage during an exam hits every student at the worst possible moment.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Pros*], [*Cons*],
  [A single, larger VM],
  [No coordination between machines.],
  [Single point of failure; size bounded by what ÉTS provides.],

  [Several VMs configured by the same Ansible roles],
  [Capacity added one VM at a time; losing a VM does not stop the service.],
  [Database replication and HTTP load balancing to operate.],
)

=== Decision

Several identical Ubuntu VMs per role, described in an Ansible inventory by groups (`web`, `judge`, `db`). Adding or replacing a VM is done by adding it to the inventory and running a single playbook.

- *Judges*: stateless and interchangeable. They pull jobs from the PostgreSQL queue; a job abandoned by a failed judge is picked up by another one (ADR-0001). Losing a judge reduces capacity without losing any submission.
- *Database*: the only stateful component. A hot-standby PostgreSQL replica (streaming replication) can be promoted if the primary fails, with regular backups outside the VM.
- *Web API*: stateless. If several `web` VMs are needed, an nginx `upstream` block balances the load across them and removes a failed instance. This choice will be settled based on load tests.

=== Consequences

- A VM failure during an exam degrades the service without interrupting it or losing any submission, provided each role has at least two instances.
- The ADR-0006 playbooks become multi-host; reproducibility from the repository is also the mechanism for replacing a machine.
- The MVP (50 students) can stay on one or two VMs; the topology is the same, only the inventory changes.
- Database failover and HTTP load balancing must be tested before each exam period.

#validation(id: "V-0010")[
  Confirm with the ÉTS infrastructure team the number of available VMs, the possibility of a floating IP (or a load balancer provided by the institution) and where backups are stored; simulate the loss of a judge and of the PostgreSQL primary during a load test.
]
