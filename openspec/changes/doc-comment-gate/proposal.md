## Why

Every comment block that sits directly above a field or definition in `src/*.cue` is a CUE doc comment: the parser marks it `Doc` when its last line is immediately followed by the declaration, and every downstream surface replays it verbatim. `cue lsp` hover (the VS Code extension), `Value.Doc()` (the `opmodel.dev` docgen), `cue def`, and this repo's own `.tasks/generate-index.sh` all read exactly that block. Measured on `main` at cue v0.17.1: 232 fields carry 1359 doc-comment lines (~80 KB of hover text); 38 exceed 10 lines and 13 exceed 20 (`#Catalog` 55, `#IdentityPackage.VersionMajor` 36, `#Resource.fulfilment` 35). Most of that length is rationale, measured evaluator behavior, refuted spellings and "Was:" history, which belongs next to the code but is noise for a consumer hovering a field, and which in several cases duplicates the `SPEC.md` Rationale the `core-schema-edit` protocol already forces us to write. Nothing in the repo states where each kind of comment belongs, and nothing checks it, so the next agent edit adds another twenty-line doc comment.

Now, because both `main` lines are quiet after `core-name-types-and-constraint` landed, and the sweep that relocates the existing comments (a follow-up change) needs the rule and the gate in place first so it does not regress while it is in flight.

## What Changes

- A documented three-tier comment convention for `src/*.cue`: the doc comment (at most 6 lines, contract only, optionally pointing at the `SPEC.md` section), a detached `// WHY` note below the field after one blank line for implementation rationale that must stay next to the code, and `SPEC.md` Rationale for the full argument. Recorded in `CLAUDE.md` (CUE Style Guidelines) and in `.claude/skills/core-schema-edit/SKILL.md`, which is the file subagents actually load.
- A new mechanical gate, `.tasks/doc-check.sh`, with a `task docs:check` task wired into `task check` and a matching `ci.yml` step. It reports every doc comment over 6 lines in `src/*.cue`, excluding `*_pins.cue` fixture files. **Warn-only in this change**: it prints violations and exits 0, so the 46 existing sites do not block anything. The follow-up sweep change flips it to fail once the count is zero.
- No `src/*.cue` edits. No `SPEC.md` edits beyond none. No published surface changes: the CUE module is byte-identical before and after.

## Classification

Not a release. `chore:` for the gate and Taskfile, `docs:` for `CLAUDE.md` and the skill. `Spec-Impact: none` (no `*.cue` file is touched, so the pre-commit and CI co-update gates do not fire). Does not rely on `@v2` prerelease status.

## Downstream consumers

- **`library`, `cli`, `opm-operator`, `modules`**: nothing to do; the published module does not change.
- **`catalog_opm`**: a sibling change in that repo records the same convention and installs the same script; the two are intentionally identical so the rule reads the same across the v2 line. Neither depends on the other.
- **`opmodel.dev`**: the docgen will benefit once the sweep lands (shorter, contract-only field descriptions); nothing changes for it here.

## Principle V

No schema surface is added. The gate is a bash script in the same style as `generate-index.sh` and `spec-check.sh`, no new toolchain.

## Capabilities

### New Capabilities

None. This change is tooling and repository rules; `.openspec.yaml` sets `skip_specs: true`.

### Modified Capabilities

None.

## Impact

- New: `.tasks/doc-check.sh`.
- Edited: `Taskfile.yml` (new `docs:check`, added to `check`), `.github/workflows/ci.yml` (new step after `spec:check`), `CLAUDE.md` (CUE Style Guidelines and the Build And Dev Commands table), `.claude/skills/core-schema-edit/SKILL.md` (new "Writing comments" section).
- Untouched: `src/`, `SPEC.md`, `src/INDEX.md`.
