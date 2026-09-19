// Shared layout. Content documents only import the blocks
// (decision, hypothesis, validation, todo); only entry points apply
// `document` — otherwise an #include in the report would reapply the page
// setup and the title.
//
// Logo: curl -fsSL https://www.etsmtl.ca/assets/img/ets.svg -o docs/ets.svg
// (resolved relative to THIS file; `logo: none` to omit it).

#let _blue = rgb("#003087") // ÉTS navy blue
#let _red = rgb("#DA291C") // ÉTS red
#let _grey = luma(140)
#let _stripe = luma(248)

// Mermaid: merman draws through `layout`, which the HTML export ignores. In HTML
// the diagram therefore goes through html.frame (inline SVG). Import `mermaid`
// from here, never directly from merman.
#import "@preview/merman:0.3.0": mermaid as _mermaid
#let mermaid(..args) = context {
  // Inside html.frame, `width: 100%` has no reference width: the frame came
  // out as 0x0. Give it the width of an A4 page; the CSS rescales it.
  if target() == "html" { html.frame(block(width: 16cm, _mermaid(..args))) } else { _mermaid(..args) }
}

// ---------------------------------------------------------------------------
// Design blocks
// ---------------------------------------------------------------------------

#let _callout(label, fill, body, class: "") = context {
  if target() == "html" {
    html.elem("div", attrs: (class: "callout " + class))[*#label* #body]
  } else {
    block(fill: fill, inset: 10pt, radius: 3pt, width: 100%)[*#label* #body]
  }
}

// The identifier is optional: `#decision(id: "D-03")[...]`. It is used for
// traceability (requirement -> decision -> experiment -> result).
#let _heading(name, id) = if id == none { name + "." } else { name + " " + id + "." }

#let decision(id: none, body) = _callout(_heading("Current decision", id), luma(245), body, class: "decision")
#let hypothesis(id: none, body) = _callout(_heading("Hypothesis", id), luma(250), body, class: "hypothesis")
#let validation(id: none, body) = _callout(_heading("To validate", id), luma(250), body, class: "validation")

// Section still to be written: visible, so it cannot be handed in by mistake.
#let todo(body) = context {
  if target() == "html" {
    html.elem("div", attrs: (class: "callout todo"))[_To write:_ #body]
  } else {
    block(
      fill: rgb("#fff4e5"),
      stroke: (left: 2pt + rgb("#e8a33d")),
      inset: 8pt,
      width: 100%,
    )[_To write:_ #body]
  }
}

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------

#let document(
  title: "",
  subtitle: none,
  course: "LOG791",
  course-name: "Special Project in Software Engineering",
  students: ("Vianney Veremme",),
  term: "Fall 2026",
  group: none,
  supervisors: none,
  date: datetime.today().display("[year]-[month]-[day]"),
  logo: "ets.svg",
  slug: "document", // file name on the site (slug.html, slug.pdf)
  department: "Department of Software and IT Engineering",
  body,
) = {
  let running-header = course + " \u{2014} " + title

  set std.document(title: title, author: students)
  set text(font: "New Computer Modern", size: 10.5pt, lang: "en")
  set par(justify: true, leading: 0.65em, spacing: 1.2em)
  set heading(numbering: "1.1")
  show link: set text(fill: blue)

  show heading.where(level: 1): set text(size: 14pt, fill: _blue)
  show heading.where(level: 2): set text(size: 12pt, fill: _blue)
  show heading.where(level: 3): set text(fill: _blue)

  show raw.where(block: false): box.with(fill: luma(235), inset: (x: 3pt, y: 0pt), outset: (y: 3pt), radius: 2pt)
  show raw.where(block: true): block.with(fill: luma(240), inset: (x: 1em, y: 0.8em), radius: 4pt, width: 100%)

  let rows = (
    (if students.len() > 1 { "Students" } else { "Student" }, students.sorted().join(linebreak())),
    ("Course", course),
    ("Term", term),
  )
  if group != none { rows.push(("Group", group)) }
  if supervisors != none {
    rows.push((
      if supervisors.len() > 1 { "Supervisors" } else { "Supervisor" },
      supervisors.join(linebreak()),
    ))
  }
  rows.push(("Date", date))
  let info = table(
    columns: (auto, 1fr),
    stroke: 0.4pt + luma(200),
    inset: (x: 9pt, y: 6pt),
    fill: (_, row) => if calc.odd(row) { _stripe } else { white },
    ..rows.map(((k, v)) => (strong(k), v)).flatten(),
  )

  // ---- HTML (site): no page, no spacing; styling comes from site/style.css ----
  context if target() == "html" {
    html.elem("link", attrs: (rel: "stylesheet", href: "style.css"))
    html.elem("nav", html.elem("a", attrs: (href: "index.html"))[← Documentation])
    html.elem("header", attrs: (class: "title"))[
      #heading(level: 1, numbering: none, outlined: false, title)
      #if subtitle != none { html.elem("p", attrs: (class: "subtitle"), subtitle) }
      #html.elem("p", attrs: (class: "pdf"), html.elem("a", attrs: (href: slug + ".pdf"))[PDF version])
      #info
    ]
    outline(depth: 2)
    body
  } else {

  set page(
    paper: "a4",
    margin: (top: 2.5cm, bottom: 2.5cm, x: 2.4cm),
    header: context if counter(page).get().first() > 1 {
      set text(size: 9pt, fill: _grey)
      running-header
      v(-0.5em)
      line(length: 100%, stroke: 0.4pt + luma(210))
    },
  )

  // ---- Title page ----
  {
    set align(center)
    if logo != none {
      v(0.4cm)
      image(logo, height: 4.5cm)
      v(0.4cm)
    } else {
      v(1.6cm)
    }
    text(size: 14pt, weight: "bold", "École de technologie supérieure")
    linebreak()
    text(size: 10.5pt, fill: _grey, department)

    v(1.6em)
    line(length: 58%, stroke: 1.2pt + _red)
    v(1.6em)

    text(size: 22pt, weight: "bold", fill: _blue, title)
    if subtitle != none {
      v(0.4em)
      text(size: 14pt, fill: _blue, subtitle)
    }
    v(0.8em)
    text(size: 12pt, style: "italic")[#course \u{2014} #course-name]

    v(1.6em)
    line(length: 58%, stroke: 0.5pt + luma(190))
    v(1.6em)

    set align(left)
    info
  }

  pagebreak()
  set page(numbering: "1")
  counter(page).update(1)
  outline(depth: 2, indent: auto)
  pagebreak()
  body
}
}
