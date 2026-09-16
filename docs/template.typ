// Mise en forme commune. Les documents de contenu n'importent que les blocs
// (decision, hypothesis, validation, todo) ; seuls les points d'entrée
// appliquent `document` — sinon un #include dans le rapport réappliquerait
// la page et le titre.
//
// Logo : curl -fsSL https://www.etsmtl.ca/assets/img/ets.svg -o docs/ets.svg
// (résolu depuis CE fichier ; `logo: none` pour l'omettre).

#let _bleu = rgb("#003087") // bleu marine ÉTS
#let _rouge = rgb("#DA291C") // rouge ÉTS
#let _gris = luma(140)
#let _rayure = luma(248)

// Mermaid : merman dessine par `layout`, que l'export HTML ignore. En HTML le
// diagramme passe donc par html.frame (SVG en ligne). Importer `mermaid` d'ici,
// jamais directement de merman.
#import "@preview/merman:0.3.0": mermaid as _mermaid
#let mermaid(..args) = context {
  // Dans html.frame, `width: 100%` n'a aucune largeur de référence : le cadre
  // sortait en 0x0. On lui donne celle d'une page A4 ; le CSS le remet à l'échelle.
  if target() == "html" { html.frame(block(width: 16cm, _mermaid(..args))) } else { _mermaid(..args) }
}

// ---------------------------------------------------------------------------
// Blocs de conception
// ---------------------------------------------------------------------------

#let _encadre(label, fond, body, classe: "") = context {
  if target() == "html" {
    html.elem("div", attrs: (class: "encadre " + classe))[*#label* #body]
  } else {
    block(fill: fond, inset: 10pt, radius: 3pt, width: 100%)[*#label* #body]
  }
}

// L'identifiant est facultatif : `#decision(id: "D-03")[...]`. Il sert à la
// traçabilité (exigence -> décision -> expérience -> résultat).
#let _titre(nom, id) = if id == none { nom + "." } else { nom + " " + id + "." }

#let decision(id: none, body) = _encadre(_titre("Décision actuelle", id), luma(245), body, classe: "decision")
#let hypothesis(id: none, body) = _encadre(_titre("Hypothèse", id), luma(250), body, classe: "hypothese")
#let validation(id: none, body) = _encadre(_titre("À valider", id), luma(250), body, classe: "validation")

// Section à rédiger : visible, donc impossible à remettre par oubli.
#let todo(body) = context {
  if target() == "html" {
    html.elem("div", attrs: (class: "encadre todo"))[_À rédiger :_ #body]
  } else {
    block(
      fill: rgb("#fff4e5"),
      stroke: (left: 2pt + rgb("#e8a33d")),
      inset: 8pt,
      width: 100%,
    )[_À rédiger :_ #body]
  }
}

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------

#let document(
  titre: "",
  sous-titre: none,
  cours: "LOG795",
  nom-cours: "Projet de fin d'études en génie logiciel",
  etudiants: ("Vianney Veremme",),
  session: "Automne 2026",
  groupe: "01",
  superviseurs: none,
  date: datetime.today().display("[day]/[month]/[year]"),
  logo: "ets.svg",
  slug: "document", // nom de fichier sur le site (slug.html, slug.pdf)
  departement: "Département de génie logiciel et des TI",
  body,
) = {
  let entete = cours + " \u{2014} " + titre

  set std.document(title: titre, author: etudiants)
  set text(font: "New Computer Modern", size: 10.5pt, lang: "fr")
  set par(justify: true, leading: 0.65em, spacing: 1.2em)
  set heading(numbering: "1.1")
  show link: set text(fill: blue)

  show heading.where(level: 1): set text(size: 14pt, fill: _bleu)
  show heading.where(level: 2): set text(size: 12pt, fill: _bleu)
  show heading.where(level: 3): set text(fill: _bleu)

  show raw.where(block: false): box.with(fill: luma(235), inset: (x: 3pt, y: 0pt), outset: (y: 3pt), radius: 2pt)
  show raw.where(block: true): block.with(fill: luma(240), inset: (x: 1em, y: 0.8em), radius: 4pt, width: 100%)

  let lignes = (
    (if etudiants.len() > 1 { "Étudiants" } else { "Étudiant" }, etudiants.sorted().join(linebreak())),
    ("Cours", cours),
    ("Session", session),
    ("Groupe", groupe),
  )
  if superviseurs != none { lignes.push(("Professeurs attitrés", superviseurs)) }
  lignes.push(("Date", date))
  let infos = table(
    columns: (auto, 1fr),
    stroke: 0.4pt + luma(200),
    inset: (x: 9pt, y: 6pt),
    fill: (_, row) => if calc.odd(row) { _rayure } else { white },
    ..lignes.map(((k, v)) => (strong(k), v)).flatten(),
  )

  // ---- HTML (site) : ni page, ni espacement ; le style vient de site/style.css ----
  context if target() == "html" {
    html.elem("link", attrs: (rel: "stylesheet", href: "style.css"))
    html.elem("nav", html.elem("a", attrs: (href: "index.html"))[← Documentation])
    html.elem("header", attrs: (class: "titre"))[
      #heading(level: 1, numbering: none, outlined: false, titre)
      #if sous-titre != none { html.elem("p", attrs: (class: "sous-titre"), sous-titre) }
      #html.elem("p", attrs: (class: "pdf"), html.elem("a", attrs: (href: slug + ".pdf"))[Version PDF])
      #infos
    ]
    outline(depth: 2)
    body
  } else {

  set page(
    paper: "a4",
    margin: (top: 2.5cm, bottom: 2.5cm, x: 2.4cm),
    header: context if counter(page).get().first() > 1 {
      set text(size: 9pt, fill: _gris)
      entete
      v(-0.5em)
      line(length: 100%, stroke: 0.4pt + luma(210))
    },
  )

  // ---- Page de titre ----
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
    text(size: 10.5pt, fill: _gris, departement)

    v(1.6em)
    line(length: 58%, stroke: 1.2pt + _rouge)
    v(1.6em)

    text(size: 22pt, weight: "bold", fill: _bleu, titre)
    if sous-titre != none {
      v(0.4em)
      text(size: 14pt, fill: _bleu, sous-titre)
    }
    v(0.8em)
    text(size: 12pt, style: "italic")[#cours \u{2014} #nom-cours]

    v(1.6em)
    line(length: 58%, stroke: 0.5pt + luma(190))
    v(1.6em)

    set align(left)
    infos
  }

  pagebreak()
  set page(numbering: "1")
  counter(page).update(1)
  outline(depth: 2, indent: auto)
  pagebreak()
  body
}
}
