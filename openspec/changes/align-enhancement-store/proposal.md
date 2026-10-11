## Why

The enhancements now live in an OpenSpec store (`opm-enhancements`) with their own ids and requirements. The old way of citing them in core, a decision number such as `NNNN:Dn`, no longer names anything a reader can open, and a lone id says nothing. Core must cite an enhancement only as its id beside a reason in words. The rules that steer agents must move from patches in OpenSpec skill files into `openspec/config.yaml`, which `openspec update` does not overwrite.

## What Changes

- `openspec/config.yaml` and `AGENTS.md`: add `references:` to the store, the `Delivers` line rule and the comment rule ("an enhancement id only beside a reason in words, never alone, never a decision number"). Remove every rule about `enhancement.yaml` and `task enhancements:delivery:*`.
- Every citation in tracked files (code comments, `SPEC.md`, `docs/`, live specs, archived changes) becomes an id beside a reason in words. The `enh cite-rewrite` tool does the mechanical part. The sites it only lists (lone `// WHY name:` labels, ids inside a sentence, question ids, paths into an entry) are rewritten by hand.
- The nine archived `enhancement.yaml` files are deleted. Their proposals already name the entry.
- `src/INDEX.md` is regenerated after the comment edits.
- `.tasks/spec-check.sh` stays unchanged. The `SPEC.md` breadcrumbs keep the phrase "Renamed from" and lose only the decision number.
- `CHANGELOG.md` and `.claude/**` are not edited.

No schema, constraint or behaviour changes. Only comments, rule text, archived text and generated descriptions change. The published CUE is the same except for comment text. Under Principle I this is neither MAJOR, MINOR nor PATCH. It does not rely on the `@v2` beta break licence. Every commit is a hidden type (`docs`, `chore`, `test`), so the change cuts no release.

## Enhancement

None.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. The live spec files under `openspec/specs/` change in wording only: a citation becomes an id beside a reason. No requirement is added, changed or removed, so the change has no spec delta and `.openspec.yaml` declares `skip_specs: true`.

## Impact

- **library**, **cli**, **opm-operator**, **catalog_opm**, **modules**: no action. The published schema is the same. They see different comment text in the next core release.
- **Doc comments**: the docs bundle and `src/INDEX.md` quote doc comments. Both are regenerated; no definition changes.
- **Owner**: the skill files `openspec-new-change` and `openspec-propose` under `.claude/skills/` carry `REPO-LOCAL PATCH` blocks, and `core-schema-edit` shows example citations. Agents do not write under `.claude/`. The owner runs `openspec update` and edits those lines; the report lists them.
- **Not checked here**: the `cite-lint` task and its CI call come later (a separate task pins merged commits).
