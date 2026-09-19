#import "../template.typ": validation

== ADR-0011 — User interface internationalization

*Status:* proposed. \
*See also:* architecture, section "Internationalization".

=== Context

The project is open source: code, comments and documentation are written in English so that anyone can contribute. The platform's first users, however, are French-speaking ÉTS students and instructors, and other institutions may adopt it in their own language. The project team can only maintain French and English itself.

=== Options considered

- *English-only interface*: nothing to maintain, but unsuitable for the first users.
- *Interface duplicated per language*: every change must be made in each copy; the copies drift apart.
- *Message keys and one translation file per language*: a single interface, translated text kept outside the code, and a language added by contributing one file.

=== Decision

Every user-facing string goes through a message key; no text is hard-coded in the interface. Each language has one translation file (`locales/<lang>.json` in the web application), using a format that supports placeholders and plurals (ICU MessageFormat). The library is chosen with the web stack.

- *English* is the source language: a new key is always added to `en` first.
- *English and French* are maintained by the project and must always be complete. CI fails if `fr` and `en` do not have exactly the same keys.
- *Other languages* are external contributions and may be incomplete. A missing key falls back to its English text, key by key, so a partial translation is still usable.
- The language is chosen from the user's preference, then from the browser's `Accept-Language`, then defaults to English.
- The API and the judge return *codes* with parameters (verdict, error, reason), never sentences to display. The interface turns them into text. The server therefore stays language-neutral.

Out of scope: the pedagogical content (statements, test messages written by the instructor), which stays in its author's language, and the project documentation, which is in English only.

=== Consequences

- Adding a language requires only one file and no code change.
- An incomplete contributed language shows English text where a translation is missing, rather than a raw key.
- Error and verdict codes become a public contract between the API and the interface, and must be versioned as such.
- Safe Exam Browser does not change the language: the preference must be settable in the platform itself.

#validation(id: "V-0011")[
  Once the web application exists: a key missing from `fr` fails CI; a key missing from a contributed language falls back to English; the language chosen in the platform persists under SEB.
]
