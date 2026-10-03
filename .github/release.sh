#!/usr/bin/env bash
# Bumps the workspace version when the commits since the last tag call for it, then releases
# the version of Cargo.toml if it has no tag yet and builds its images. Run by release.yml from
# the repository root, with full history and tags. DRY_RUN=1 prints the commands instead.
#
# Bump rule: Conventional Commits mapped to SemVer; before 1.0.0, Cargo's rule, where the minor
# is the incompatible component. 1.0.0 is set by hand. A version raised by hand is kept.
set -euo pipefail

run() { if [ -n "${DRY_RUN:-}" ]; then echo "+ $*"; else "$@"; fi; }

version=$(sed -n 's/^version = "\(.*\)"$/\1/p' Cargo.toml)
last=$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)

if [ -n "$last" ]; then
  log=$(git log --format=%B "$last..HEAD")
  IFS=. read -r major minor patch <<< "${last#v}"
  scope='(\([^()]+\))?'
  if grep -qE "^[a-z]+$scope!:|^BREAKING CHANGE:" <<< "$log"; then
    if [ "$major" = 0 ]; then next=0.$((minor + 1)).0; else next=$((major + 1)).0.0; fi
  elif grep -qE "^feat$scope:" <<< "$log" && [ "$major" != 0 ]; then
    next=$major.$((minor + 1)).0
  elif grep -qE "^(feat|fix|perf)$scope:" <<< "$log"; then
    next=$major.$minor.$((patch + 1))
  else
    next=${last#v}
  fi

  if [ "$(printf '%s\n' "$version" "$next" | sort -V | tail -n 1)" != "$version" ]; then
    run sed -i "s/^version = \"$version\"$/version = \"$next\"/" Cargo.toml
    run cargo update --workspace
    run git -c user.name='github-actions[bot]' \
      -c user.email='41898282+github-actions[bot]@users.noreply.github.com' \
      commit -am "chore(release): v$next"
    run git push origin HEAD:main
    version=$next
  fi
fi

if git rev-parse -q --verify "refs/tags/v$version" > /dev/null; then
  echo "v$version is already released"
  exit 0
fi
run gh release create "v$version" --target "$(git rev-parse HEAD)" --generate-notes
# A tag pushed with GITHUB_TOKEN triggers no workflow, but a dispatch does.
run gh workflow run images.yml --ref "v$version"
