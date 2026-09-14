#!/bin/sh
# Construit le site : un PDF et un HTML par document, dans _site/.
# Le même script tourne en CI et en local (depuis LOG795/) :   sh site/build.sh
#
# Ajouter un document = une ligne ici + une carte dans site/index.html.
# Le slug doit être celui passé à `document.with(slug: ...)`, qui s'en sert
# pour le lien « Version PDF ».
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
done <<EOF
plan-de-projet docs/pdf/plan-de-projet.typ
architecture   docs/pdf/architecture.typ
adr            docs/pdf/adr.typ
rapport        rapport/main.typ
EOF
