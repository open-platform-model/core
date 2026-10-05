#!/usr/bin/env bash
# spec-check.sh — verify SPEC.md inventory matches CUE construct definitions.
#
# Inventory check (three directions):
#   1. Every entry in the allowlist (.tasks/spec-tracked.txt) is referenced in SPEC.md.
#   2. Every entry in the allowlist exists as a top-level definition in src/*.cue
#      (catches stale allowlist after a rename or removal).
#   3. Every #Name referenced in SPEC.md is defined somewhere in src/*.cue
#      (catches stale references after a rename or removal).
#
# The allowlist is the explicit source of truth for which constructs require
# documentation. Adding a tracked construct = two coupled edits:
#   - add a #Name line to .tasks/spec-tracked.txt
#   - add a section to SPEC.md that references #Name
#
# Gate pin check: an applied (uncommented) publish-gate pin in src/pins/ is a
# regular field, never hidden, so cue vet checks its completeness.
#
# Pin placement check: package core (src/*.cue) declares no top-level hidden
# field. Schema pins live in package pins in src/pins/, which nothing imports;
# a pin in package core would be evaluated by every main-instance build of it.
#
# Does NOT validate field-level details, rationale freshness, or section
# format — those are review-time concerns, not mechanical ones.
#
# Usage (run from repo root):
#   bash .tasks/spec-check.sh "$(pwd)"

set -euo pipefail

# See generate-index.sh for the rationale — pin to C so set ordering is
# byte-stable across locales (CI runs with C.UTF-8, contributors often run
# with en_*.UTF-8).
export LC_ALL=C

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

# All top-level #Foo: definitions across src/*.cue (any name).
all_cue_names=$(
  grep -hE '^#[A-Z][a-zA-Z0-9]*:' "$ROOT"/src/*.cue 2>/dev/null \
    | grep -oE '^#[A-Z][a-zA-Z0-9]*' \
    | sort -u
)

# Names referenced anywhere in SPEC.md (headers, prose, code blocks).
#
# Old-name breadcrumb lines (0002:D12 — "Renamed from `#Old`
# (enhancement NNNN).") intentionally name a now-removed identifier to leave a
# migration trail in the construct's Definition prose. These are deliberate
# historical references, not stale ones, so drop breadcrumb lines before
# extracting refs — otherwise Direction 3 would flag every retired name.
spec_refs=$(grep -v 'Renamed from' "$SPEC" | grep -oE '#[A-Z][a-zA-Z0-9]+' | sort -u)

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
  echo "FAIL: allowlist entries not defined in any src/*.cue file (renamed or removed?):" >&2
  printf '%s\n' "$stale_in_allowlist" | sed 's/^/  /' >&2
  echo "  Fix: remove the entry from .tasks/spec-tracked.txt OR restore the CUE definition." >&2
  failed=1
fi
if [[ -n "$stale_in_spec" ]]; then
  echo "FAIL: SPEC.md references not defined in any src/*.cue file (renamed or removed?):" >&2
  printf '%s\n' "$stale_in_spec" | sed 's/^/  /' >&2
  echo "  Fix: update SPEC.md to use the current name OR restore the CUE definition." >&2
  failed=1
fi

# Pin placement: no top-level hidden field in package core.
hidden_in_core=$(grep -nE '^_' "$ROOT"/src/*.cue 2>/dev/null || true)
if [[ -n "$hidden_in_core" ]]; then
  echo "FAIL: top-level hidden fields in package core (src/*.cue):" >&2
  printf '%s\n' "$hidden_in_core" | sed "s|^$ROOT/||; s/^/  /" >&2
  echo "  Fix: pins belong in package pins in src/pins/, which nothing imports." >&2
  failed=1
fi

# Gate pins: an applied (uncommented) pin that applies a publish gate is a
# regular field. cue vet checks only regular fields for completeness, so a
# hidden gate pin with an unstated posture vets clean and checks nothing.
# Commented must-fail cases keep the hidden shape and are not matched here.
hidden_gate_pins=$(
  grep -nE '^[[:space:]]*_[A-Za-z0-9_]+:[[:space:]]*core\.#(TraitOptionalGate|CatalogMemberFQNGate)\b' \
    "$ROOT"/src/pins/*.cue 2>/dev/null || true
)
if [[ -n "$hidden_gate_pins" ]]; then
  echo "FAIL: hidden publish-gate pins in src/pins/ (requirement \"Publish-gate pins are applied non-hidden\"):" >&2
  printf '%s\n' "$hidden_gate_pins" | sed "s|^$ROOT/||; s/^/  /" >&2
  echo "  Fix: drop the leading underscore so cue vet checks the gate (SPEC.md § 5.1)." >&2
  failed=1
fi

if [[ "$failed" -eq 0 ]]; then
  echo "OK: SPEC.md inventory matches CUE definitions and allowlist; package core declares no pin; gate pins are non-hidden."
fi

exit "$failed"
