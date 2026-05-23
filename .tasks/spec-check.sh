#!/usr/bin/env bash
# spec-check.sh — verify SPEC.md inventory matches CUE construct definitions.
#
# Inventory check (three directions):
#   1. Every entry in the allowlist (.tasks/spec-tracked.txt) is referenced in SPEC.md.
#   2. Every entry in the allowlist exists as a top-level definition in core/*.cue
#      (catches stale allowlist after a rename or removal).
#   3. Every #Name referenced in SPEC.md is defined somewhere in core/*.cue
#      (catches stale references after a rename or removal).
#
# The allowlist is the explicit source of truth for which constructs require
# documentation. Adding a tracked construct = two coupled edits:
#   - add a #Name line to .tasks/spec-tracked.txt
#   - add a section to SPEC.md that references #Name
#
# Does NOT validate field-level details, rationale freshness, or section
# format — those are review-time concerns, not mechanical ones.
#
# Usage (run from repo root):
#   bash .tasks/spec-check.sh "$(pwd)"

set -euo pipefail

ROOT="${1:?Error: module_dir argument required. Usage: bash .tasks/spec-check.sh \"\$(pwd)\"}"
SPEC="${ROOT}/SPEC.md"
ALLOWLIST="${ROOT}/.tasks/spec-tracked.txt"

if [[ ! -f "$ALLOWLIST" ]]; then
  echo "ERROR: $ALLOWLIST not found — cannot determine tracked constructs." >&2
  exit 1
fi

if [[ ! -f "$SPEC" ]]; then
  echo "WARNING: $SPEC does not exist — spec:check is a no-op."
  echo "         Create SPEC.md to enable spec drift detection."
  exit 0
fi

# Tracked constructs from the allowlist. Strip blank lines and // comments.
tracked=$(
  awk '
    /^[[:space:]]*\/\// { next }
    /^[[:space:]]*$/    { next }
    { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print }
  ' "$ALLOWLIST" \
    | sort -u
)

# All top-level #Foo: definitions across core/*.cue (any name).
all_cue_names=$(
  grep -hE '^#[A-Z][a-zA-Z0-9]*:' "$ROOT"/*.cue 2>/dev/null \
    | grep -oE '^#[A-Z][a-zA-Z0-9]*' \
    | sort -u
)

# Names referenced anywhere in SPEC.md (headers, prose, code blocks).
spec_refs=$(grep -oE '#[A-Z][a-zA-Z0-9]+' "$SPEC" | sort -u)

# Direction 1: allowlist entries missing from SPEC.md.
missing_in_spec=$(
  comm -23 <(printf '%s\n' "$tracked") <(printf '%s\n' "$spec_refs") || true
)

# Direction 2: allowlist entries not defined anywhere in CUE.
stale_in_allowlist=$(
  comm -23 <(printf '%s\n' "$tracked") <(printf '%s\n' "$all_cue_names") || true
)

# Direction 3: SPEC.md references not defined anywhere in CUE.
stale_in_spec=$(
  comm -23 <(printf '%s\n' "$spec_refs") <(printf '%s\n' "$all_cue_names") || true
)

failed=0
if [[ -n "$missing_in_spec" ]]; then
  echo "FAIL: allowlist entries with no section/reference in SPEC.md:" >&2
  printf '%s\n' "$missing_in_spec" | sed 's/^/  /' >&2
  echo "  Fix: add a section to SPEC.md OR remove the entry from .tasks/spec-tracked.txt." >&2
  failed=1
fi
if [[ -n "$stale_in_allowlist" ]]; then
  echo "FAIL: allowlist entries not defined in any core/*.cue file (renamed or removed?):" >&2
  printf '%s\n' "$stale_in_allowlist" | sed 's/^/  /' >&2
  echo "  Fix: remove the entry from .tasks/spec-tracked.txt OR restore the CUE definition." >&2
  failed=1
fi
if [[ -n "$stale_in_spec" ]]; then
  echo "FAIL: SPEC.md references not defined in any core/*.cue file (renamed or removed?):" >&2
  printf '%s\n' "$stale_in_spec" | sed 's/^/  /' >&2
  echo "  Fix: update SPEC.md to use the current name OR restore the CUE definition." >&2
  failed=1
fi

if [[ "$failed" -eq 0 ]]; then
  echo "OK: SPEC.md inventory matches CUE definitions and allowlist."
fi

exit "$failed"
