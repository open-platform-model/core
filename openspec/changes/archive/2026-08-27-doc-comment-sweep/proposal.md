## Why

`doc-comment-gate` (archived 2026-08-27) recorded the three-tier comment convention and installed `task docs:check`, warn-only. On `main` the report lists 51 doc comments over 6 lines across 13 of the 17 schema files, about 830 lines of hover text: `#Catalog` 55, `#IdentityPackage.VersionMajor` 36, `#Resource.fulfilment` 35, `#Trait.optional` 29, `#IdentityPackage` 29, `#CatalogMemberFQNGate` 28. Until they are relocated the gate cannot be strict, and every consumer hovering a core field keeps reading rationale, measured cue behavior and enhancement history it did not ask for.

Now, because the gate and the rule text merged (core PR 53) and nothing else is in flight on `main`, so a comment-only sweep touches no file anyone is editing.

## What Changes

- Every one of the 51 reported doc comments is split: the contract (what the field is, what a consumer must satisfy, an optional `See SPEC.md § N.M` pointer) stays as the doc comment, at most 6 lines; everything else moves to a `// WHY ...` block directly above the doc comment, separated from it by one blank line, or shrinks to a pointer where `SPEC.md` Rationale already carries the same argument verbatim.
- No text is deleted, only moved or replaced by a pointer to where the same text already lives. `Was:` history, measured cue v0.17.1 behavior, refuted spellings and enhancement decision numbers all survive in the `// WHY` blocks.
- Code is byte-identical: every non-comment line in `src/*.cue` is unchanged. `SPEC.md` is not edited.
- `src/INDEX.md` is regenerated: the generator takes the first sentence of each definition's doc comment, and a rewritten first sentence changes the row.
- `task docs:check` flips to `--strict` in `Taskfile.yml`, and the "warn-only until the sweep lands" wording is removed from `CLAUDE.md` and `.claude/skills/core-schema-edit/SKILL.md`.
- The whole sweep is one change, deliberately, after the scope warning was raised and overruled: the work is uniform (the same operation 51 times) and mechanically verifiable, and a single strict flip at the end is cleaner than three warn-only intermediate states. The cost is review size, mitigated by one commit per file and a second full review pass (design D6).

## Classification

`docs:` per file, `chore:` for the strict flip. Not a release: the published CUE is byte-identical except for `src/INDEX.md` and comment text, which ship inside the module but change no evaluated value. `Spec-Impact: none` on every commit (`SPEC_IMPACT=none` locally, `Spec-Impact: none (comment relocation only)` trailer, and in the PR body).

## Downstream consumers

- **`library`, `cli`, `opm-operator`, `modules`**: nothing to do; no evaluated value changes. Anyone re-pinning picks up shorter hover text.
- **`catalog_opm`**: nothing to do here; its own sweep is a separate change in that repo.
- **`opmodel.dev`**: the generated schema reference picks up the shortened descriptions on its next `task generate`; that is the intended effect.

## Principle V

No schema surface changes.

## Capabilities

### New Capabilities

None. Comment relocation and a Taskfile flag; `.openspec.yaml` sets `skip_specs: true`.

### Modified Capabilities

None.

## Impact

- `src/*.cue`: 13 files (all but `identity_pins.cue`, `identity_package_pins.cue`, `platform_and_match_pins.cue`, `component_names_pins.cue`, which are exempt). Comment lines only.
- `src/INDEX.md`: regenerated.
- `Taskfile.yml`, `CLAUDE.md`, `.claude/skills/core-schema-edit/SKILL.md`: strict flip and wording.
- Untouched: `SPEC.md`, `.tasks/`, `cue.mod/`, CI.
