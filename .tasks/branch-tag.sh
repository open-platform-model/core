#!/usr/bin/env bash
set -euo pipefail

# branch-tag.sh — print the branch-publish tag for HEAD.
#
# Output format:
#   v<MAJOR>.<NEXT_MINOR>.0-dev.<commit_ct>.g<short_sha>
#
# Inputs (all derived from the commit object and the repo state — no clocks,
# no environment, no network):
#   MAJOR        from src/cue.mod/module.cue ("opmodel.dev/core@vN")
#   NEXT_MINOR   bump-minor of highest stable tag matching vMAJOR.*.* in git;
#                falls back to 0 if no stable tag exists for the current major
#                (e.g. immediately after a major bump, before the first release)
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

# ── Compute NEXT_MINOR from highest stable tag for this major ─────────────────

latest_stable=$(git tag -l "v${major}.*" --sort=-v:refname \
  | grep -E "^v${major}\.[0-9]+\.[0-9]+$" \
  | head -1 || true)

if [[ -z "$latest_stable" ]]; then
  # No stable release yet for this major (e.g. just after vN→vN+1 bump,
  # before the first release in the new major series).
  next_minor=0
else
  current_minor=$(printf '%s' "$latest_stable" | sed -E "s/^v${major}\.([0-9]+)\..*/\1/")
  next_minor=$((current_minor + 1))
fi

# ── Read commit identity ──────────────────────────────────────────────────────

sha_full=$(git rev-parse HEAD)
sha_short=$(git rev-parse --short=7 "$sha_full")
ct=$(git show -s --format=%ct "$sha_full")

# ── Emit ──────────────────────────────────────────────────────────────────────

printf 'v%s.%d.0-dev.%s.g%s\n' "$major" "$next_minor" "$ct" "$sha_short"
