#import "../template.typ": adr, arch, ext, mermaid, validation

== ADR-0021 — Bounded on-demand judges <adr-0021>

*Status:* proposed. Refines #adr("0010"); gives #adr("0012") and #adr("0020") their judge reservation. \
*See also:* #arch("purpose-of-the-document")[architecture], sections #arch("sizing")[Sizing] and #arch("reserved-resources")[Reserved resources].

=== Context

Judging capacity is currently a fixed number of judges per VM, changed by hand or through the #ext("ansible")[Ansible] inventory (#adr("0010")). Load is not flat: an exam start or an assignment deadline brings a burst, then the queue is empty for hours. The VMs are small and shared, and an idle judge still holds memory for its pre-started sandboxes (#adr("0013")). #ext("ctester")[CTester] runs a few permanent judges and starts more, up to a cap, while jobs wait.

=== Options considered

- *Fixed number of judges* (current): sized for the peak, idle the rest of the time.
- *External autoscaler* (an orchestrator such as Kubernetes): no orchestrator is planned, and adding one for this alone is not justified.
- *Floor and cap per VM, driven by the queue*: a small local process starts judges while jobs wait.

=== Decision

- *Floor*: each judge VM keeps a number of permanent judges.
- *Cap*: each judge VM has a maximum number of judges, set from the maximum number of concurrent sandboxes measured for that VM (#adr("0013")). It is read again on every pass, so changing it needs no restart.
- *Scaler*: one systemd service per judge VM. Every 2 s, it counts the jobs waiting in the #ext("postgresql")[PostgreSQL] queue for more than 2 s (#adr("0001")). If any are waiting and the cap is not reached, it starts one more `judge@N` instance, then gives it time to claim a job before counting again. It is paused during a deployment.
- *Never stopped from outside*: an on-demand judge leaves by itself after 5 minutes without a job, and its unit only restarts on failure. No run is cut short.
- *Exams*: before each exam or contest session in the schedule (#adr("0020")), the floor is raised to the reserved number of judges, so the start of the exam does not wait for cold starts. It drops back to normal after the session.
- No coordination between VMs: judges pull from the same queue, which stays the only dispatcher.

The scaler on one judge VM, and the life of a judge:

#mermaid(
  "
  flowchart LR
    T[Every 2 s] --> W{Jobs waiting<br/>more than 2 s?}
    W -->|no| T
    W -->|yes| C{Below the cap?<br/>cap read again}
    C -->|no| T
    C -->|yes| S[Start one more<br/>judge@N]
    S --> G[Give it time<br/>to claim a job]
    G --> T
  ",
  document-context: true,
  width: 100%,
)

#mermaid(
  "
  stateDiagram-v2
    direction LR
    [*] --> idle: started by the floor or the scaler
    idle --> running: claims a job
    running --> idle: verdict written
    idle --> [*]: on-demand judge, 5 min without a job
  ",
  document-context: true,
  width: 75%,
)

=== Consequences

- Off-peak, judge VMs keep only the floor running; capacity grows with the queue, up to the cap.
- The cap per VM is the measured answer to #arch("open-questions")[open question 3]: the number of judge VMs for the target load (#arch("target-load")[Target load]) follows from the cap of each one.
- The dashboard (#adr("0019")) shows on-demand judges appearing and leaving; a judge that left after being idle is not a dead judge.
- Ramp-up is reactive: outside scheduled sessions, a burst waits a few seconds per additional judge.

#validation(id: "V-0021")[
  During a load test, the number of judges on a VM rises to the cap while the queue is full, then falls back to the floor after the idle delay, with no run cut short. Lowering the cap applies without a restart. The reserved judges are running before a scheduled exam starts.
]
