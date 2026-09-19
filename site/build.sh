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

# A mistyped label in #adr/#arch/#plan compiles into a dead link: check that
# every link to a site page points to an existing anchor.
python3 - "$out" <<'PY'
import glob, os, re, sys
os.chdir(sys.argv[1])
ids = {f: set(re.findall(r'id="([^"]+)"', open(f, encoding="utf-8").read())) for f in glob.glob("*.html")}
dead = []
for f in ids:
    for h in re.findall(r'href="([^"]+)"', open(f, encoding="utf-8").read()):
        m = re.fullmatch(r'(?:https://vianpyro\.github\.io/LOG791/([\w-]+\.html))?#(.+)', h)
        if m and m.group(2) not in ids.get(m.group(1) or f, ()):
            dead.append(f + " -> " + h)
print("\n".join(dead) or "== links: all anchors resolve")
sys.exit(1 if dead else 0)
PY
