#import "../template.typ": adr, arch, course, ext, validation

== ADR-0029 — Importing existing course material <adr-0029>

*Status:* proposed. Feeds #adr("0015"); extends #adr("0005"); applies #adr("0023"). \
*See also:* #arch("purpose-of-the-document")[architecture], sections #arch("validation")[Validation] and #arch("open-questions")[open question 19]; #adr("0028").

=== Context

The platform is meant for the instructors of every LOG/GTI course (#adr("0012")), not only for its author. Their material already exists: question banks in #ext("moodle")[Moodle], exported as #ext("moodle-xml")[Moodle XML] or #ext("gift")[GIFT], and statements in Word documents. Rewriting it by hand is the first obstacle to adoption.

Accepting these files as statement formats would put them on the publication path. Each format accepted at publication is another renderer to operate in the sandbox, another attack surface for untrusted content (#adr("0023")) and more validation rules to maintain, for a project carried out by one person (project plan, risk R4). Word files are binary as well: a Git diff cannot show what changed, and a validation error cannot name a line.

=== Options considered

#table(
  columns: (3cm, 1fr, 1fr),
  stroke: 0.5pt,
  [*Option*], [*Pros*], [*Cons*],
  [Word and Moodle formats accepted at publication],
  [The instructor keeps their files.],
  [Two more renderers and parsers on the publication path; binary content in Git; errors without a line.],

  [One-time import into the existing formats],
  [Publication does not change; the result is text, reviewed in a diff; the converter needs no trust.],
  [A converter to maintain; what it cannot express has to be finished by hand.],

  [No import],
  [Nothing to build.],
  [Every bank and statement rewritten by hand; instructors stay on Moodle.],
)

PDF, raw HTML and Jupyter notebooks are not imported. A PDF does not convert reliably to accessible HTML, and Safe Exam Browser allows no download (#arch("safe-exam-browser")[Safe Exam Browser]); a PDF handed to students goes in `public/`, served apart (#adr("0023")). Raw HTML is what #adr("0023") refuses. The text cells of a notebook are already Markdown; notebooks are reconsidered if a course asks for them.

=== Decision

*A conversion, not a format.* An importer converts Moodle XML, GIFT and Word (`.docx`) files once into files of the content repository: `exercises/<id>/statement.md` and `bank/<id>.json`. The author reviews them and commits them. The publisher never reads a Word or Moodle file: publication is unchanged (#adr("0005")).

*No trust gained.* Imported files are ordinary content, validated and published like any other, and still untrusted (#adr("0023")). The importer has no privilege, no network and no access to the platform.

*Where it runs.* The importer is its own application, `apps/importer`, shipped as a container image with #ext("pandoc")[pandoc], built like every other application. An instructor runs it on their workstation or in their content repository's CI, without network (`--network none`) and with its input mounted read-only.

*Moodle banks to items.* Moodle XML is read by a parser that refuses any `DOCTYPE`, so no external entity is resolved and no entity expansion can explode. GIFT is read by its own grammar. Moodle question types map to the grader families of #adr("0015"): multiple choice, true/false, short answer, numerical, matching, essay and description to Q1; calculated, drag and drop into text, select missing words and embedded answers (cloze) once their family exists. Moodle categories become pool tags. Question text, which Moodle stores as HTML, is converted to Markdown by pandoc: no raw HTML survives.

*Word to Markdown.* pandoc, with `--sandbox`, converts a `.docx` file to `statement.md`; Word equations become `$…$` formulas, rendered as #ext("mathml")[MathML]. Before pandoc runs, the archive's uncompressed size and entry count are capped, and macro-enabled documents (`.docm`) and embedded OLE objects are refused.

*Nothing is lost silently.* The output is checked against the platform's Markdown grammar (#arch("markdown")[Markdown]).

- A question that cannot be expressed in full is not written, since a question without its key would be graded wrongly; it is listed in the report with its name and category.
- A statement that loses something (an image, a layout) is written with an `import-report.md` next to it, listing each loss and where it was. Publication refuses an exercise that contains this file: the exercise cannot reach students until its author has dealt with the losses and deleted the report.

=== Consequences

- No new format on the publication path; LaTeX remains the only third format (#adr("0028")).
- One more application and image to maintain; pandoc is in two images, the rendering one and the importer.
- Validation gains one rule: an exercise containing `import-report.md` is refused.
- Images from Word documents are not imported, since Markdown has none: a statement that needs them is finished in Typst.
- Import quality follows pandoc's and Moodle's export: an imported bank is a starting point to review, not a migration that can be trusted blindly.

#validation(id: "V-0029")[
  A Moodle XML file whose `DOCTYPE` declares an external entity is refused without reading the entity, and so is a "billion laughs" file. A ZIP bomb renamed `.docx` is refused before the cap is exceeded, and a `.docm` file is refused. A real #course("LOG200") bank is imported with each Q1 question either converted or listed in the report. For the same answers, an imported multiple-choice question gives the same score as in Moodle. A `.docx` file with an image produces an `import-report.md`, and the exercise is refused at publication until the report is deleted. A Word equation is displayed as MathML.
]
