#!/usr/bin/env bash
# Checks the commit-msg hook and the version bump of .github/release.sh, the latter in dry run
# on a throwaway repository.
set -euo pipefail

root=$(pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

hook() { printf '%s\n' "$1" > "$tmp/message"; sh "$root/.githooks/commit-msg" "$tmp/message" 2> /dev/null; }
accepts() { hook "$1" || { echo "hook refused: $1" >&2; exit 1; }; }
refuses() { if hook "$1"; then echo "hook accepted: $1" >&2; exit 1; fi; }

accepts 'feat(api): add health route'
accepts 'fix!: drop legacy route'
accepts "Merge branch 'main' of github.com:Vianpyro/LOG791"
refuses 'Updated README'
refuses 'feat: add route.'
refuses 'feat: Add route'
refuses 'feature: add route'

# Repository at tag $1 (version of Cargo.toml: $2), plus one commit per message; prints the release.
releases() {
  local tag=$1 version=$2
  shift 2
  rm -rf "$tmp/repo"
  git init -q "$tmp/repo"
  cd "$tmp/repo"
  git config user.name test
  git config user.email test@example.com
  git config core.autocrlf false
  echo "version = \"${tag#v}\"" > Cargo.toml
  git add Cargo.toml
  git commit -qm 'feat: init'
  git tag "$tag"
  echo "version = \"$version\"" > Cargo.toml
  for message in "$@"; do git commit -qam "$message" --allow-empty; done
  DRY_RUN=1 bash "$root/.github/release.sh" | sed -n 's/^+ gh release create \(v[^ ]*\).*/\1/p; s/ is already released$//p'
  cd "$root"
}

expect() {
  local want=$1
  shift
  local got
  got=$(releases "$@")
  [ "$got" = "$want" ] || { echo "release of $*: got '$got', want '$want'" >&2; exit 1; }
}

expect v0.1.0 v0.1.0 0.1.0 'docs: explain'
expect v0.1.1 v0.1.0 0.1.0 'fix: repair'
expect v0.1.1 v0.1.0 0.1.0 'feat: add' 'fix: repair'
expect v0.2.0 v0.1.0 0.1.0 'feat(api)!: remove'
expect v0.5.0 v0.1.0 0.5.0 'feat: add'
expect v1.3.0 v1.2.3 1.2.3 'feat: add' 'fix: repair'
expect v2.0.0 v1.2.3 1.2.3 $'fix: repair\n\nBREAKING CHANGE: new format'

echo "release: ok"
