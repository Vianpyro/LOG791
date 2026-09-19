#import "../template.typ": arch, ext, validation

== ADR-0002 — gVisor as the initial isolation mechanism <adr-0002>

*Status:* accepted for the first implementation; comparison with #ext("firecracker")[Firecracker] planned. \
*See also:* #arch("purpose-of-the-document")[architecture], section #arch("submission-isolation")[Submission isolation].

=== Context

Student code is untrusted. A classic container shares the host kernel and is not a sufficient security boundary on its own. The platform itself runs in a VM provided by the institution, where nested virtualization (KVM) is not guaranteed.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Pros*], [*Cons*],
  [#ext("gvisor")[gVisor] (#ext("systrap")[Systrap])],
  [User-space application kernel; works without KVM; plugs into #ext("docker")[Docker]/Podman as an OCI runtime; proven in #ext("ctester")[CTester].],
  [Overhead on system calls; some cgroup limits do not count internal processes.],

  [Firecracker],
  [Strong boundary (microVM under KVM).],
  [Requires KVM, hence nested virtualization; microVM lifecycle to manage.],

  [WebAssembly],
  [Strong sandbox by construction.],
  [Toolchain and libraries per language; does not cover a general multi-language course.],

  [Container only (runc)], [Simplest and fastest.], [Insufficient boundary against hostile code.],
)

=== Decision

gVisor in Systrap mode, driven by a container runtime, is chosen for the first implementation.

=== Consequences

- The choice between Docker and #ext("podman")[Podman] becomes secondary: the OCI runtime carries the isolation.
- Limits must be verified by their *outcome* (the host is unaffected) rather than by their mechanism, since some cgroup controls cannot see inside the sandbox.
- The judge's sandbox abstraction must remain independent of gVisor to allow the comparison.

#validation(id: "V-0002")[
  Compare gVisor and Firecracker under an identical load: startup, latency, throughput, CPU and memory, and behavior against hostile submissions. Check whether KVM is available on the institution's VM.
]
