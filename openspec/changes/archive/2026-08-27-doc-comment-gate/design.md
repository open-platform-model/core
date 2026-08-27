## Context

See proposal.md for motivation. The mechanism this design leans on is a parser fact, verified against cue v0.17.1 (`cue/parser/parser.go`, `next()`): a comment group is flagged `Doc` only when `endline+1 == line(next token)`. A `//` line with no text keeps a group together (multi-paragraph docs are one doc); one genuinely blank line ends the group and the block is no longer a doc comment. `cue fmt` preserves that blank line and collapses two or more to one, so a detached block stays detached through formatting. The LSP hover (`internal/lsp/eval/eval.go`, `docComments`) filters on `group.Doc`; `Value.Doc()` and `cue def` do the same; `.tasks/generate-index.sh` resets its accumulator on any non-comment line, so it agrees with all of them.

Two constraints shape the gate. It MUST run in this repo's toolchain, which is bash, awk and `cue`; there is no Go here. It MUST NOT fail on `main` today: 51 sites in schema files exceed 6 lines, and relocating them is a separate change.

## Goals / Non-Goals

**Goals:**

- One place that states where each kind of comment belongs, loaded by the agents that edit `src/*.cue`.
- A mechanical report of every doc comment over the limit, in the same style and location as the existing gates.
- Zero behavior change to the published module.

**Non-Goals:**

- Relocating existing comments. That is the follow-up sweep change, one commit per file, `docs:` type.
- Failing the build. The gate is warn-only until the sweep empties the report.
- Checking comment *content* (whether the doc says the right thing). Review-time concern, same stance as `spec-check.sh`.
- Any change to `generate-index.sh` or `INDEX.md`.

## Decisions

### D1. Detached notes go BELOW the field, after one blank line, prefixed `// WHY`

**Context**: A note above the field separated by a blank line reads, to a human, as belonging to the previous field, and if someone deletes the blank line it silently reattaches to the wrong declaration.
**Explored**: Both placements in a scratch package; hover output and `cue fmt` stability for each.
**Decision**: Below the field. The blank line above the note is load-bearing; the `// WHY` prefix marks it so a later tidy-up does not close the gap.
**Rationale**: A note under the field cannot be mistaken for the next field's doc, and a deleted blank line above it reattaches it to nothing (a trailing comment group is never `Doc`). Placement above would need the same marker and still be one keystroke from reattaching to the wrong field.

### D2. Limit is 6 lines, counted as `//` lines

**Explored**: 4, 6, 8, 12 against `main`: 84, 59, 46, 31 violations respectively (exempting nothing).
**Decision**: 6. Chosen by the user. Room for a two-sentence contract and a `See SPEC.md § N.M` pointer; a second paragraph forces the split.

### D3. Scope: every field and definition in `src/*.cue` except `*_pins.cue`

**Decision**: Fixture files (`identity_pins.cue`, `identity_package_pins.cue`, `platform_and_match_pins.cue`, `component_names_pins.cue`) are exempt by filename. Hidden `_` fields in schema files are in scope.
**Rationale**: Pins are hidden-field test matrices whose long comments record measured errors; they are not a consumer hover surface and the length is the point. Hidden fields in schema files are hovered by every contributor to this repo, so they stay in scope. The exemption is a filename glob, not a per-field marker, so it cannot spread.

### D4. The gate skips `package`, `import`, `let` and comprehension clauses

**Context**: The prototype flagged the file-level `package` doc and `let` clauses.
**Decision**: Count only comment runs that end directly above a field label (`name:`, `name!:`, `name?:`, `#Name:`, `_name:`, `"quoted":`). Package docs are file-level documentation, and `let`/`for`/`if` lines are not hover targets.

### D5. Warn-only, no baseline file

**Context**: Three rollouts were considered: a baseline file listing today's offenders (fails only on new or grown sites), warn-only, and fail-immediately (which merges the sweep into this change).
**Decision**: Warn-only, chosen by the user. The script takes a `--strict` flag (or `DOC_CHECK_STRICT=1`) that turns the report into a failure; the sweep change flips the Taskfile to strict as its last task. No baseline file to maintain.
**Trade-off**: Until the sweep lands, a new over-limit doc comment is reported but not blocked. The `core-schema-edit` skill text is the guard in that window.

### D6. Where the rule text lives

**Decision**: Two places, both required. `CLAUDE.md` § CUE Style Guidelines gets a "Doc comments" subsection (the rule and the one-line reason: everything above a field with no blank line is hover text). `.claude/skills/core-schema-edit/SKILL.md` gets a "Writing comments" section with the three tiers and a before/after example, because subagents load the skill and not `CLAUDE.md`.

## The gate

`.tasks/doc-check.sh`, invoked as `bash .tasks/doc-check.sh "$(pwd)" [--strict]`, `LC_ALL=C`, same header style as `spec-check.sh`. Per `*.cue` file under `src/` (excluding `cue.mod/` and `*_pins.cue`), an awk pass tracks the current run of `//` lines; on a field-label line with a non-zero run it emits `file:line: doc comment on <label> is N lines (max 6)` when `N > 6`, and resets the run on any other line. Exit 0 with a summary count, or exit 1 under `--strict` when the count is non-zero.

Taskfile:

```yaml
  docs:check:
    desc: Report doc comments over 6 lines in src/*.cue (warn-only until the sweep lands)
    cmds:
      - bash .tasks/doc-check.sh "$(pwd)"
```

added to `check` after `spec:check`, and a matching `ci.yml` step "Report over-long doc comments" after the SPEC inventory step.

## Risks / Trade-offs

- [Someone removes the blank line above a `// WHY` block, re-attaching it as doc text] → the gate reports it the next time `task check` runs; under strict mode it fails.
- [The awk label regex misses an exotic label form (string-interpolated labels, pattern constraints)] → those are not hover targets a consumer sees; a miss is a false negative, never a false failure. Recorded as a known limit in the script header.
- [Warn-only output is ignored] → accepted for the window until the sweep; the skill text carries the rule in the meantime.

## Migration Plan

None for consumers. The follow-up sweep change (one commit per `src/*.cue` file, `docs:` type, `SPEC_IMPACT=none`) relocates the 51 sites and flips `docs:check` to `--strict` in its final task.
