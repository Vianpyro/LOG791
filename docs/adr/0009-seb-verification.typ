#import "../template.typ": adr, arch, ext, validation

== ADR-0009 — Server-side verification of Safe Exam Browser <adr-0009>

*Status:* proposed; to be validated under SEB. \
*See also:* #arch("purpose-of-the-document")[architecture], section #arch("safe-exam-browser")[Safe Exam Browser]; #adr("0008").

=== Context

During an exam, the platform must reject any browser other than #ext("seb")[Safe Exam Browser] (SEB), or a SEB launched with a different configuration. The exam may start in #ext("moodle")[Moodle] and then move to the platform through #ext("lti")[LTI]: the check performed by Moodle then does not cover requests sent to the platform.

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

The expected Config Key is stored with the exam in #ext("postgresql")[PostgreSQL] and provided by the instructor. The `.seb` file stays with the instructor, who distributes it through Moodle or encrypts it with a password. The repository, which may be public, contains no `.seb` file and no Config Key: anyone who knows the key can forge the header.

=== Consequences

- Whenever the `.seb` file changes, the instructor updates the exam's Config Key.
- The Config Key is treated as a secret.
- SEB's URL filter allows the platform and `login.microsoftonline.com`, and no CDN.
- An exam request without a valid hash is rejected.

#validation(id: "V-0009")[
  Under SEB for Windows with the exam's `.seb` file: access works. Outside SEB or with a different configuration, it is refused. Also verify that Entra sign-in, #ext("pyodide")[Pyodide] execution and the SSE stream work.
]
