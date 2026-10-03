#!/usr/bin/env bash
# Component boundaries (ADR-0014), read from the crate graph rather than from imports:
# a crate can only use what its Cargo.toml declares.
# A crate is an app or a package by its directory, so a new crate is covered without listing it.
# Run from the repository root: bash tests/architecture/boundaries.sh
set -euo pipefail

# Every "kind crate -> kind dependency" edge between workspace crates, one per line.
edges=$(cargo metadata --format-version 1 --no-deps --offline |
  jq -r '(.packages | map({key: .name, value: (.manifest_path | if test("[/\\\\]packages[/\\\\]") then "package" else "app" end)})
          | from_entries) as $kind
         | .packages[] | .name as $n | .dependencies[] | select($kind[.name])
         | "\($kind[$n]) \($n) -> \($kind[.name]) \(.name)"')

failed=0
fail() { echo "FAIL  $1"; failed=1; }

while read -r from_kind from _ to_kind to; do
  [ "$from_kind" = package ] && [ "$to_kind" = app ] && fail "$from -> $to (a shared package depends on no app)"
  case "$from -> $to" in
    "api -> judge" | "judge -> api") fail "$from -> $to (the API and the judge never depend on each other)" ;;
  esac
done <<<"$edges"

[ "$failed" -eq 0 ] && echo "ok    component boundaries"
exit "$failed"
