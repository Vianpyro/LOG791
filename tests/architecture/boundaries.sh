#!/usr/bin/env bash
# Component boundaries (ADR-0014), read from the crate graph rather than from imports:
# a crate can only use what its Cargo.toml declares.
# Run from the repository root: bash tests/architecture/boundaries.sh
set -euo pipefail

# Every "crate -> workspace dependency" edge, one per line.
edges=$(cargo metadata --format-version 1 --no-deps --offline |
  jq -r '.packages as $p | ($p | map(.name)) as $ws
         | $p[] | .name as $n | .dependencies[] | select(.name | IN($ws[])) | "\($n) -> \(.name)"')

forbidden=(
  "api -> judge"     # the API and the judge never depend on each other
  "judge -> api"
  "content -> admin" # shared packages depend on no application
  "content -> api"
  "content -> judge"
  "content -> publisher"
  "contracts -> admin"
  "contracts -> api"
  "contracts -> judge"
  "contracts -> publisher"
)

failed=0
for edge in "${forbidden[@]}"; do
  if grep -qxF "$edge" <<<"$edges"; then
    echo "FAIL  $edge"
    failed=1
  fi
done

[ "$failed" -eq 0 ] && echo "ok    component boundaries"
exit "$failed"
