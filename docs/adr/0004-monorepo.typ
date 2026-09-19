#import "../template.typ": arch, ext

== ADR-0004 — Monorepo for code, infrastructure and documentation <adr-0004>

*Status:* accepted. \
*See also:* #arch("purpose-of-the-document")[architecture], section #arch("code-organization")[Code organization].

=== Context

The platform comprises a web interface, an API, a judge engine, an infrastructure configuration and design documentation. In #ext("ctester")[CTester], the application and its deployment live in two repositories, and database privileges had to be moved back into the application repository after three desynchronization failures.

=== Options considered

- *Monorepo*: one consistent version of all components, a single CI, atomic cross-cutting changes.
- *One repository per component*: independent release cycles, but compatibility has to be coordinated by hand.

=== Decision

A monorepo is chosen for the application, the judge, the infrastructure and the documentation.

*Pedagogical content* stays in a separate repository: it contains private assessment data, it is edited by the teaching team and it is published without redeployment (see #arch("content-lifecycle")[Content lifecycle]).

=== Consequences

- Boundaries between components must remain explicit: a monorepo implies neither a common language nor a common deployment cycle.
- CI must build and test the modified components selectively.
