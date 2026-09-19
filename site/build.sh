#!/bin/sh
# Builds the site: one PDF and one HTML per document, into _site/.
# The same script runs in CI and locally (from LOG791/):   sh site/build.sh
#
# Adding a document = one line here + one card in site/index.html.
# The slug must match the one passed to `document.with(slug: ...)`, which uses
# it for the "PDF version" link.
set -eu

out=_site
rm -rf "$out"
mkdir -p "$out"
cp site/index.html site/style.css "$out/"

while read -r slug src; do
  [ -z "$slug" ] && continue
  echo "== $slug ($src)"
  typst compile --root . "$src" "$out/$slug.pdf"
  typst compile --root . --features html --format html "$src" "$out/$slug.html"
done <<LIST
project-plan   docs/pdf/project-plan.typ
architecture   docs/pdf/architecture.typ
adr            docs/pdf/adr.typ
report         report/main.typ
LIST
