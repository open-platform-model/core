#!/usr/bin/env bash
set -euo pipefail

# See generate-index.sh for the rationale — pin to C so file ordering is
# byte-stable across locales.
export LC_ALL=C

# doc-check.sh — report doc comments longer than the limit.
#
# A CUE doc comment is the contiguous run of `//` lines that ends on the line
# directly above a field or definition. The parser flags exactly that run as
# the declaration's documentation, and every consumer replays it verbatim:
# `cue lsp` hover, `Value.Doc()`, `cue def`, and the INDEX.md generator. One
# blank line ends the run: a block separated from the field by a blank line
# is NOT a doc comment, and `cue fmt` preserves that blank line.
#
# The convention this enforces (CLAUDE.md, CUE Style Guidelines):
#   - doc comment: the contract, at most MAX lines
#   - `// WHY ...` block ABOVE the doc comment, separated by one blank line:
#     rationale that must stay next to the code but is not hover text
#   - the normative document (SPEC.md here, docs/ in the catalogs): the full
#     argument
#
# Exempt:
#   - files matching *_pins.cue (hidden-field fixture matrices)
#   - hidden fields whose label starts with _test (inline fixtures)
#   - package clauses, imports, let and comprehension clauses: not field
#     hover targets
#
# Known limit: only plain labels are matched (#Def, _hidden, ident, "quoted",
# each optionally followed by ! or ?). An interpolated or pattern label is
# never reported. That is a false negative, never a spurious failure.
#
# Usage (run from the repo root):
#   bash .tasks/doc-check.sh <cue-dir> [--strict]
#
# Exits 0 after printing the report. With --strict (or DOC_CHECK_STRICT=1) a
# non-empty report exits 1.

MAX=6

DIR="${1:?Error: cue_dir argument required. Usage: bash .tasks/doc-check.sh <cue-dir> [--strict]}"
STRICT="${DOC_CHECK_STRICT:-0}"
[[ "${2:-}" == "--strict" ]] && STRICT=1

[[ -d "$DIR" ]] || { echo "Error: not a directory: $DIR" >&2; exit 1; }

fails=0
while IFS= read -r file; do
    while IFS=$'\t' read -r line n label; do
        printf '%s:%s: doc comment on `%s` is %s lines (max %s)\n' \
            "$file" "$line" "$label" "$n" "$MAX"
        fails=$((fails + 1))
    done < <(awk -v max="$MAX" '
        # A comment line extends the current run; remember where it started.
        /^[[:space:]]*\/\// { if (run == 0) start = NR; run++; next }

        # A field label directly after a run closes it as a doc comment.
        /^[[:space:]]*(#?[A-Za-z_][A-Za-z0-9_]*|"[^"]*")[!?]?:/ {
            if (run > max) {
                label = $1
                sub(/[!?]?:.*$/, "", label)
                if (label !~ /^_test/) print start "\t" run "\t" label
            }
            run = 0; next
        }

        # Anything else (blank line, code, package, let, comprehension)
        # ends the run without a report.
        { run = 0 }
    ' "$file")
done < <(find "$DIR" -name '*.cue' -not -path '*/cue.mod/*' -not -name '*_pins.cue' | sort)

if [[ "$fails" -gt 0 ]]; then
    echo ""
    echo "$fails doc comment(s) over $MAX lines under $DIR."
    echo "Keep the contract in the doc comment; move the rest into a // WHY block above it, separated by a blank line."
    if [[ "$STRICT" == "1" ]]; then
        echo "FAIL: strict mode."
        exit 1
    fi
    exit 0
fi
echo "OK: no doc comment over $MAX lines under $DIR."
