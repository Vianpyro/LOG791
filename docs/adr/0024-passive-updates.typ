#import "../template.typ": adr, arch, ext, mermaid, validation

== ADR-0024 — Passive updates <adr-0024>

*Status:* proposed. Refines #adr("0010") and #adr("0021"). \
*See also:* #arch("purpose-of-the-document")[architecture], sections #arch("updates-without-interruption")[Updates without interruption] and #arch("maintenance-notice")[Maintenance notice].

=== Context

A deployment currently stops everything at once: the maintenance notice goes up in every tab, the queue is drained, every judge is restarted, then the notice comes down. #ext("ctester")[CTester] does the same: its deployment script raises a flag, restarts the judges and the API, waits for the API to answer, then removes the flag. Most components do not need this. Load comes in bursts (#adr("0021")), so judges are often idle; the API runs several processes behind #ext("nginx")[nginx] (#adr("0010")); the web interface is static and versioned by hash.

An admin who runs a deployment most likely runs it to fix a problem, so the fix should take effect within minutes, without cutting a run short or interrupting a student when it can be avoided. An exam is still the worst moment for a surprise: a deployment is refused during an exam, but an admin deploying a fix for that very exam must be able to override the refusal deliberately, as with `git push --force`.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Pros*], [*Cons*],
  [Restart everything under the notice (current, CTester)],
  [Simple; one version at a time.],
  [Every release interrupts every student; judges wait for the queue to drain.],

  [Rolling update by an orchestrator],
  [Standard mechanism.],
  [No orchestrator is planned, and adding one for this alone is not justified (#adr("0021")).],

  [Publish, then each component switches at its own idle moment],
  [No notice for a routine release; no run cut short.],
  [Two versions run side by side for a few minutes; migrations and contracts must allow it.],
)

=== Decision

+ *A deployment publishes; it does not restart.* #ext("ansible")[Ansible] pulls the attested images and writes the *desired version* (image digest) of each component into a file on each VM. It restarts no passive component. A rollback writes the previous digest, through the same path.
+ *Refused during an exam, unless forced.* A deployment refuses to start while an exam session in the schedule (#adr("0020")) is in progress or starts within 30 minutes; the refusal names the sessions and how to force. `-e force=true` on the command line skips this check and nothing else: it is never set in the inventory, so every forced run is a deliberate choice. A forced deployment writes the event `deploy.forced` with the identifiers of the sessions it overlaps, and the dashboard (#adr("0019")) shows that the release was forced during an exam.
+ *Judges switch when idle.* Between two jobs, a judge compares its digest with the desired one. An outdated judge leaves when it has no job, has claimed none for 10 s (a setting), and no other judge of its VM is leaving: one at a time per VM, so capacity drops by one judge at most. Since an update is usually a fix, the wait is short: a judge that is not idle within 2 minutes leaves at the end of its current job. A run is never cut short. systemd restarts a permanent judge on the desired digest; an on-demand judge just leaves, and the scaler starts the next ones on the desired digest. The scaler is therefore no longer paused during a deployment. Pre-started sandboxes of an outdated language pack image (#adr("0013")) are replaced the same way, when idle. This also applies during an exam, which a deployment only reaches when forced: each job records the versions of the judge and of the pack that produced its verdict.
+ *The API changes hands without a gap.* During a handover, each `web` VM runs two API instances behind the nginx #ext("nginx-upstream")[`upstream`]. The new one starts and answers `/healthz`; nginx reloads gracefully; the old one stops accepting connections, finishes its requests within a bounded delay and closes its #ext("sse")[SSE] streams with a short `retry`. Browsers reconnect to the new instance with `Last-Event-ID`, so no verdict event is lost.
+ *The web interface changes on reload.* `index.html` is served with `no-cache`; other files are named by hash and immutable. The files of the previous release stay served, so a tab that is already open keeps working. The new interface appears on the next reload; nothing is forced.
+ *Other components are passive too.* An nginx configuration change is a `reload`. The dashboard (#adr("0019")) and the scaler hold no job and are restarted directly; their clients reconnect. The publisher uses the new image for the next publication, and a publication under way finishes on the old one.
+ *Two versions side by side are the normal state.* Database migrations are expand/contract: a release only adds (tables, nullable columns or columns with a default); removals come in a later release, once nothing older runs. Each job carries the version of its contract, and a judge never claims a job whose contract it does not know: it is outdated, so it leaves, and a judge on the new version claims the job. The API of release N accepts the web interface of release N−1.
+ *Only disruptive steps show the notice.* Each Ansible role declares its steps `passive` or `disruptive`. Disruptive steps are those that cannot avoid an interruption: a PostgreSQL restart (minor upgrade, a setting that needs a restart, switchover to the standby), a migration that takes a heavy lock, and a reboot or a runtime upgrade (Docker, #ext("gvisor")[gVisor]) on a role that has a single instance. Only these raise the maintenance flag, CTester-style, in an Ansible `block` with its removal in `always` (#arch("maintenance-notice")[Maintenance notice]). A judge VM among several is not disruptive: a cordon file pauses its scaler, its judges stop claiming and leave by rule 3, then the VM is upgraded or rebooted.

A judge, extending the life cycle of #adr("0021"):

#mermaid(
  "
  stateDiagram-v2
    direction LR
    [*] --> idle: desired digest
    idle --> running: claims a job
    running --> idle: verdict written
    idle --> outdated: new digest
    running --> outdated: new digest, job done
    outdated --> running: claims a job, under 2 min
    outdated --> [*]: 10 s idle, alone, or 2 min
  ",
  document-context: true,
  width: 100%,
)

An API handover on one `web` VM; the browser's SSE stream moves to the new instance without losing an event:

#mermaid(
  "
  sequenceDiagram
    participant B as Browser
    participant N as nginx
    participant O as API (old)
    participant W as API (new)
    B->>N: SSE stream
    N->>O: relayed
    W->>W: starts on the desired digest
    N->>W: /healthz answers
    N->>N: graceful reload, upstream points to the new instance
    O->>O: stops accepting, finishes its requests
    O-->>B: stream closed with a short retry
    B->>N: reconnect with Last-Event-ID
    N->>W: relayed
    W-->>B: events missed since Last-Event-ID
  ",
  document-context: true,
  width: 100%,
)

Removing a column across releases, so that two consecutive releases can always run side by side:

#mermaid(
  "
  flowchart LR
    N[Release N<br/>expand: new column added,<br/>written alongside the old one] --> N1[Release N+1<br/>code reads and writes<br/>only the new column]
    N1 --> N2[Release N+2<br/>contract: old column dropped,<br/>nothing older runs]
  ",
  document-context: true,
  width: 100%,
)

A deployment:

#mermaid(
  "
  flowchart TD
    S[Admin runs Ansible] --> E{Exam in progress<br/>or within 30 min?}
    E -->|yes, not forced| XR[Refused]
    E -->|no, or forced| P[Images pulled,<br/>desired versions written]
    P --> D{Disruptive step?}
    D -->|no| C[Passive components switch<br/>at their own idle moment]
    D -->|yes| F[Flag raised<br/>block]
    F --> X[Disruptive step]
    X --> R[Flag removed once<br/>the API answers, always]
    R --> C
    C --> V[Ansible reports convergence,<br/>with a timeout]
  ",
  document-context: true,
  width: 100%,
)

=== Consequences

- A routine release shows no notice and cuts no run short. The notice now means that the service really is interrupted.
- A release is deployed once its components have converged, not when the Ansible run ends. The dashboard (#adr("0019")) shows the version of each judge and API instance and the convergence ("4/6 judges on the desired version").
- Two versions of the judge can judge the same exam for a few minutes, but only after a forced deployment. Each verdict says which one produced it, and the verdict cache key already covers the judge version (#arch("cache")[Cache]).
- Every migration follows expand/contract; a column is only dropped one release after the code stops using it.
- A handover holds one more API instance in memory for its duration.
- Stable log events: `component.outdated`, `judge.recycled`, `deploy.converged`, `deploy.forced`.

#validation(id: "V-0024")[
  During a load test, publish a new judge digest: no run is cut short, at most one judge per VM leaves at a time, every judge is on the new digest 10 s after the queue empties and within 2 minutes under constant load. A rollback converges the same way. Switching the API while an SSE stream is open loses no verdict event, and a tab opened before the release keeps working. A release without a disruptive step never shows the notice; a deployment during a scheduled exam is refused, then runs with `force=true`, leaving a `deploy.forced` event and a mark on the dashboard.
]
