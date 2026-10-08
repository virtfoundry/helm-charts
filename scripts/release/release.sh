#!/usr/bin/env bash
# Release automation for the VirtFoundry product line (docs/project/versioning.md).
#
#   scripts/release/release.sh bump 0.11.4 ["one line for core docs/PRODUCT.md"]
#       Opens one "chore(release): v0.11.4" PR per repository: core, operator, vks,
#       helm-charts and the org profile (.github). Merge them one at a time.
#   scripts/release/release.sh tag 0.11.4
#       After the PRs are merged: tags core, operator, vks and helm-charts (in that order,
#       the chart pins images that must exist) and waits for each tag's workflows to pass.
#
# The repositories are sibling clones under ROOT (default: the parent of helm-charts).
# DRY_RUN=1 prints what would change and leaves every clone untouched (VERBOSE=1 adds the diff).
# WAIT_SETTLED=1 also runs scripts/ops/wait-settled.sh between tags (needs kubectl).
# The Terraform provider keeps its own version line and is not touched.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${ROOT:-$(cd "$HERE/../../.." && pwd)}"
DRY_RUN="${DRY_RUN:-0}"
BUMP_REPOS=(core operator vks helm-charts .github)
TAG_REPOS=(core operator vks helm-charts)

die() { echo "error: $*" >&2; exit 1; }
cmd="${1:-}"; NEW="${2:-}"; SUMMARY="${3:-}"
[[ "$cmd" =~ ^(bump|tag)$ && "$NEW" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "usage: release.sh bump|tag X.Y.Z [summary]"
OLD="$(sed -n 's/^version: *//p' "$ROOT/helm-charts/charts/virtfoundry/Chart.yaml" | head -1)"
export OLD NEW SUMMARY

repo_version() { # the version a repository currently declares
  case "$1" in
    core) sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$ROOT/core/ui/package.json" | head -1 ;;
    vks|helm-charts) sed -n 's/^version: *//p' "$ROOT/$1"/charts/*/Chart.yaml | sort -u | head -1 ;;
    operator) sed -n 's/^## \[\([0-9][0-9.]*\)\].*/\1/p' "$ROOT/operator/CHANGELOG.md" | head -1 ;; # no chart there: it lives in helm-charts
  esac
}

undo_dry_run() { # a dry run never leaves a clone on the release branch, also when it fails half way
  local d="$ROOT/$1"
  [[ "$(git -C "$d" branch --show-current 2>/dev/null)" == "chore/release-$NEW" ]] || return 0
  git -C "$d" checkout -q -- . && git -C "$d" checkout -q main && git -C "$d" branch -q -D "chore/release-$NEW"
}

changelog() { # move the Unreleased notes under a dated heading; say so when there are none
  python3 - "$1" <<'PY'
import os, re, sys, datetime
p = sys.argv[1]; new = os.environ["NEW"]
s = open(p).read()
m = re.search(r"## \[Unreleased\]\n", s)
if not m or f"## [{new}]" in s:
    sys.exit(0)
nxt = re.search(r"\n## \[", s[m.end():])
body = s[m.end(): m.end() + nxt.start()] if nxt else s[m.end():]
if not body.strip():
    s = s[:m.end()] + f"\n## [{new}] - {datetime.date.today()}\n\n### Changed\n\n- Version aligned with the VirtFoundry {new} release.\n" + s[m.end():]
else:
    s = s[:m.end()] + f"\n## [{new}] - {datetime.date.today()}\n" + s[m.end():]
open(p, "w").write(s)
PY
}

# Only known pin shapes are rewritten: install flags, chart and image versions, tag commands and
# "current release" statements. Prose about a specific release ("0.11.3 and newer", "tested on
# 0.11.3") is left alone and listed for a human to check, because a blind replace makes it false.
PIN_RE='(--version[ =]|\bversion: |appVersion: "?|\btag: "?|\b(?:core|ui|operator|vks):|\bv|\*\*|\bpin |e\.g\. `)'
export PIN_RE

bump_repo() {
  local r="$1" d="$ROOT/$1" skip='(^|/)(CHANGELOG\.md|changelog\.md|package-lock\.json|PRODUCT\.md)$'
  [[ -d "$d/.git" ]] || die "$d is not a git clone"
  git -C "$d" diff --quiet && git -C "$d" diff --cached --quiet || die "$r has uncommitted changes"
  git -C "$d" checkout -q main && git -C "$d" pull -q --ff-only
  git -C "$d" checkout -q -b "chore/release-$NEW"
  ( cd "$d"
    git grep -lF "$OLD" | grep -Ev "$skip" | while read -r f; do
      perl -pi -e 's/$ENV{PIN_RE}\Q$ENV{OLD}\E(?![\d.])/$1$ENV{NEW}/g' "$f"
    done || true
    for f in CHANGELOG.md docs/project/changelog.md; do if [[ -f $f ]]; then changelog "$f"; fi; done
    if [[ $r == core ]]; then
      (cd ui && npm version "$NEW" --no-git-tag-version --allow-same-version >/dev/null)
      perl -0pi -e 's/^(- \*\*\Q$ENV{OLD}\E\*\*)/- **$ENV{NEW}** — $ENV{SUMMARY}\n$1/m' docs/PRODUCT.md
    fi
    if [[ $r == helm-charts ]]; then # new first row in the compatibility table, copied from the last release
      perl -pi -e 'if (!$d && /^\| \Q$ENV{OLD}\E \|/) { ($n=$_) =~ s/\Q$ENV{OLD}\E/$ENV{NEW}/g; print $n; $d=1 }' docs/project/versioning.md
    fi
    left="$(git grep -nF "$OLD" -- . ':!*CHANGELOG.md' ':!*changelog.md' ':!*package-lock.json' ':!*PRODUCT.md' | cut -c1-160 || true)"
    if [[ -n "$left" ]]; then printf 'kept in %s (mentions of %s that are not pins, check by hand):\n%s\n' "$r" "$OLD" "$left"; fi )
  if [[ "$DRY_RUN" == 1 ]]; then
    echo "== $r (dry run)"; git -C "$d" diff --stat | tail -n 25
    if [[ "${VERBOSE:-0}" == 1 ]]; then git -C "$d" --no-pager diff -U0; fi
    undo_dry_run "$r"; return
  fi
  git -C "$d" commit -qam "chore(release): v$NEW"
  git -C "$d" push -q -u origin HEAD
  (cd "$d" && gh pr create --title "chore(release): v$NEW" --body "## Summary
- Version pins and changelog for $NEW (generated by scripts/release/release.sh).

## Test plan
- CI green; tag v$NEW after merge, in the order core, operator, vks, helm-charts.")
}

wait_runs() { # every workflow run on the tag finished and none failed
  local r="$1" end=$((SECONDS + 1800)) runs bad
  while (( SECONDS < end )); do
    runs="$(gh run list -R "virtfoundry/$r" --branch "v$NEW" --json status,conclusion,name)"
    bad="$(jq -r '.[] | select(.status!="completed" or .conclusion!="success") | .name+" "+.status+" "+.conclusion' <<<"$runs")"
    # No runs yet is not success: the tag was pushed seconds ago and nothing has started.
    if [[ "$(jq length <<<"$runs")" -gt 0 && -z "$bad" ]]; then echo "ok $r v$NEW"; return; fi
    if [[ "$bad" == *failure* ]]; then die "$r v$NEW: $bad"; fi
    sleep 20
  done
  die "$r v$NEW did not finish in 30 minutes"
}

tag_repo() {
  local r="$1" d="$ROOT/$1"
  git -C "$d" diff --quiet && git -C "$d" diff --cached --quiet || die "$r has uncommitted changes"
  git -C "$d" checkout -q main && git -C "$d" pull -q --ff-only
  [[ "$(repo_version "$r")" == "$NEW" ]] || die "$r main declares $(repo_version "$r"), not $NEW: merge the release PR first"
  if [[ "$DRY_RUN" == 1 ]]; then echo "would tag $r v$NEW"; return; fi
  git -C "$d" rev-parse -q --verify "refs/tags/v$NEW" >/dev/null && { echo "skip $r: v$NEW exists"; return; }
  git -C "$d" tag "v$NEW" && git -C "$d" push -q origin "v$NEW"
  wait_runs "$r"
  if [[ "${WAIT_SETTLED:-0}" == 1 ]]; then "$HERE/../ops/wait-settled.sh"; fi
}

if [[ "$cmd" == bump ]]; then
  [[ "$NEW" != "$OLD" ]] || die "$NEW is already the current version"
  [[ -n "$SUMMARY" ]] || SUMMARY="release $NEW"
  if [[ "$DRY_RUN" == 1 ]]; then trap 'for r in "${BUMP_REPOS[@]}"; do undo_dry_run "$r"; done' EXIT; fi
  for r in "${BUMP_REPOS[@]}"; do bump_repo "$r"; done
else
  for r in "${TAG_REPOS[@]}"; do tag_repo "$r"; done
fi
