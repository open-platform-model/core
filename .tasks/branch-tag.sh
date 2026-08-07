#!/usr/bin/env bash
set -euo pipefail

# branch-tag.sh — print the branch-publish tag for HEAD.
#
# Output format:
#   v<MAJOR>.<MINOR>.<PATCH>-0.dev.<commit_ct>.g<short_sha>
#
# The leading `0.` is what keeps a branch build below every release on the same
# base — see "Choose the channel base" below.
#
# Inputs (all derived from the commit object and the repo state — no clocks,
# no environment, no network):
#   MAJOR        from src/cue.mod/module.cue ("opmodel.dev/core@vN")
#   base         base version of the highest release for this major, stable or
#                prerelease, so the branch build shares the release channel's
#                base and can be ranked below it. Falls back to MAJOR.0.0 when
#                the major carries no release of any kind yet (e.g. immediately
#                after a major bump).
#   commit_ct    `git show -s --format=%ct HEAD` — committer Unix seconds,
#                baked into the SHA hash so it is identical wherever this
#                runs for a given commit
#   short_sha    seven hex characters of HEAD, prefixed with 'g'
#
# Refuses to run on the main branch, and refuses to run with a dirty worktree
# (a dirty tree would lie about the SHA the consumer ends up with).
#
# Usage (from the repo root):
#   bash .tasks/branch-tag.sh "$(pwd)"

REPO_RELDIR="${1:?Error: repo_dir argument required. Usage: bash .tasks/branch-tag.sh \"\$(pwd)\"}"
REPO_DIR="${REPO_RELDIR%/}"

# ── Fail fast: validate required paths exist ──────────────────────────────────

[[ -d "$REPO_DIR" ]] \
    || { echo "Error: not a directory: $REPO_DIR" >&2; exit 1; }
[[ -f "$REPO_DIR/src/cue.mod/module.cue" ]] \
    || { echo "Error: missing $REPO_DIR/src/cue.mod/module.cue" >&2; exit 1; }

cd "$REPO_DIR"

# ── Guardrails ────────────────────────────────────────────────────────────────

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" == "main" ]]; then
  echo "Error: refuse to compute a branch tag on main — use the release-please flow." >&2
  exit 2
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: worktree is dirty — commit or stash before computing a branch tag." >&2
  echo "       (a dirty tree would publish a tag that does not match any SHA)" >&2
  exit 3
fi

# ── Parse MAJOR from cue.mod/module.cue ───────────────────────────────────────

module_line=$(grep -E '^module:' src/cue.mod/module.cue | head -1)
major=$(printf '%s' "$module_line" | grep -oE '@v[0-9]+' | tr -d '@v' || true)

if [[ -z "${major:-}" ]]; then
  echo "Error: could not parse major version from src/cue.mod/module.cue" >&2
  echo "       expected a line like: module: \"opmodel.dev/core@vN\"" >&2
  exit 4
fi

# ── Choose the channel base ───────────────────────────────────────────────────
#
# The invariant: a branch build must never outrank a release, under ANY query
# — `@vN`, `@vN.M`, or an explicit range that admits prereleases. Anything less
# silently hands consumers an unreleased branch commit.
#
# Protecting only `@vN` is not enough. Go/CUE resolution drops prereleases from
# `@vN` when a stable version exists, which tempts the "put dev on the NEXT
# minor" design. Two things defeat it:
#
#   1. With no stable release for the major (a long `-alpha.N` line, which is
#      where this module lives), `@vN` has nothing to prefer and must pick the
#      highest prerelease. `1.1.0-dev.*` beats `1.0.0-alpha.3` on the base
#      version alone, before prerelease identifiers are even consulted — so
#      moving to the next minor makes it strictly worse, not better.
#   2. Explicit range subscriptions (the opm-operator's platform registry
#      filters) admit prereleases deliberately. They are unaffected by the
#      `@vN` stable-preference rule, so a next-minor dev build wins them
#      whenever that minor has no release of its own yet.
#
# So the branch build shares the base of the highest existing release and is
# ranked below it there. SemVer 2.0 §11.4.3 is the lever: a numeric identifier
# always ranks below an alphanumeric one at the same position. Leading the
# prerelease with `0` puts every branch build under every named channel:
#
#   v1.0.0-0.dev.<ct>.g<sha>  <  v1.0.0-alpha.1  <  v1.0.0
#
# One rule, every phase, every query kind. Branch builds stay reachable by
# exact pin. (`0` is a valid numeric identifier — SemVer prohibits LEADING
# zeroes, e.g. `01`, which the registry rejects outright.)

# Highest release base for this major — stable or prerelease, whichever ranks
# higher. Bases are extracted BEFORE sorting so prerelease identifiers cannot
# perturb the ordering (and so `sort -V`, which is not SemVer-aware about
# prerelease precedence, only ever sees plain X.Y.Z).
base=$(git tag -l "v${major}.*" \
  | grep -E "^v${major}\.[0-9]+\.[0-9]+(-|$)" \
  | sed -E 's/^v([0-9]+\.[0-9]+\.[0-9]+).*/\1/' \
  | sort -V | tail -1 || true)

# No release of any kind yet for this major (e.g. just after a vN→vN+1 bump).
[[ -n "$base" ]] || base="${major}.0.0"

# ── Read commit identity ──────────────────────────────────────────────────────

sha_full=$(git rev-parse HEAD)
sha_short=$(git rev-parse --short=7 "$sha_full")
ct=$(git show -s --format=%ct "$sha_full")

# ── Emit ──────────────────────────────────────────────────────────────────────

printf 'v%s-0.dev.%s.g%s\n' "$base" "$ct" "$sha_short"
