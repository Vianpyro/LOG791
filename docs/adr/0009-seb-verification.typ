#import "../template.typ": adr, arch, ext, mermaid, validation

== ADR-0009 — Server-side verification of Safe Exam Browser <adr-0009>

*Status:* proposed; deferred after the MVP. \
*See also:* #arch("purpose-of-the-document")[architecture], section #arch("safe-exam-browser")[Safe Exam Browser]; #adr("0008").

=== Context

During an exam, the platform must reject any browser other than #ext("seb")[Safe Exam Browser] (SEB), or a SEB launched with a different configuration. The exam may start in #ext("moodle")[Moodle] and then move to the platform through #ext("lti")[LTI]: the check performed by Moodle then does not cover requests sent to the platform.

For the MVP, the instructor may simply add the platform to the URL filter of the `.seb` file already used for exams, as is done today for the Java documentation. The platform then needs no SEB integration, and this verification becomes defense in depth: SEB also sends the header to an allowed site, so it can be added later without changing anything else.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Pros*], [*Cons*],
  [User-Agent], [Trivial.], [Spoofable; proves nothing.],
  [Rely on Moodle (`quizaccess_seb`)],
  [Nothing to write.],
  [Does not protect requests sent directly to the platform.],

  [Verify the #ext("seb-config-key")[Config Key] on every exam request],
  [Ties access to a specific `.seb` file.],
  [The original URL must be rebuilt behind #ext("nginx")[nginx].],
)

=== Decision

On exam routes, the API checks the `X-SafeExamBrowser-ConfigKeyHash` header, equal to the SHA-256 of the full URL concatenated with the Config Key. Behind nginx, the URL is rebuilt from `X-Forwarded-Proto` and `X-Forwarded-Host`. For `fetch` calls and the SSE stream, the client also sends the value of the `SafeExamBrowser.security.configKey` JavaScript API. The User-Agent is only used as a hint.

#mermaid(
  "
  sequenceDiagram
    participant S as SEB
    participant N as nginx
    participant A as API
    participant D as PostgreSQL
    S->>N: exam request with X-SafeExamBrowser-ConfigKeyHash
    N->>A: adds X-Forwarded-Proto and X-Forwarded-Host
    A->>A: rebuild the full URL
    A->>D: expected Config Key of the exam
    D-->>A: Config Key
    A->>A: SHA-256 of URL and Config Key equals the header?
    alt equal
      A-->>S: served
    else missing or different
      A-->>S: rejected
    end
    Note over S,A: fetch calls and the SSE stream also send the value of SafeExamBrowser.security.configKey
  ",
  document-context: true,
  width: 100%,
)

The expected Config Key is stored with the exam in #ext("postgresql")[PostgreSQL] and provided by the instructor. The `.seb` file stays with the instructor, who distributes it through Moodle or encrypts it with a password. The repository, which may be public, contains no `.seb` file and no Config Key: anyone who knows the key can forge the header.

=== Consequences

- Whenever the `.seb` file changes, the instructor updates the exam's Config Key.
- The Config Key is treated as a secret.
- SEB's URL filter allows the platform only, with no CDN and no external identity domain (#adr("0017")).
- An exam request without a valid hash is rejected.

#validation(id: "V-0009")[
  Under SEB for Windows with the exam's `.seb` file: access works. Outside SEB or with a different configuration, it is refused. Also verify that sign-in, #ext("pyodide")[Pyodide] execution and the SSE stream work.
]
