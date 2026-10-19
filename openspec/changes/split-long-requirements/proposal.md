## Why

OpenSpec 1.14.1 raises "Requirement text is very long (>500 characters)" from INFO to WARNING. `openspec validate --strict` fails on any warning, and no config key or flag turns it off: the limit is a constant in the validator. The warning is right on the merits. A long requirement usually holds several behaviors, and one behavior per requirement makes each one testable by its own scenarios.

Core has 34 requirements over 500 characters in 14 main specs. `openspec validate --all --strict` reports 35 warnings on `main`: the 34 long requirements and the placeholder Purpose of `cite-lint` (the sentence `openspec archive` writes for a new capability). The repo cannot turn `--strict` back on until both are gone. Once they are gone, nothing stops a new long requirement from landing, because no gate in `Taskfile.yml` or CI runs OpenSpec validation.

This change rewrites the long requirements with no rule lost or changed, writes the missing Purpose, and adds the gate that keeps `--strict` green.

## What Changes

- Rewrite the 34 long requirements of 14 specs as splits or moves into scenarios, by the approved guide (form a, b, c2 or d per requirement). The two batches core-B1 (28) and core-B2 (6) run as one batch of 34 over 14 whole specs, because the second is too small to stand alone. The delta specs are written in later apply units, one spec at a time, and are not part of this proposal step.
  - core-B1 specs: `platform-contract-inventory` (7), `schema-release` (5), `contract-fulfilment` (4), `catalog-contracts` (3), `primitive-keying` (3), `release-cascade` (3), `schema-pins` (2), `artifact-identity` (1).
  - core-B2 specs: `definitions-reference`, `docs-bundle`, `instance-identity`, `name-constraints`, `platform-registry`, `transformer-context` (1 each).
- Write real Purpose text for `cite-lint`, edited in the main spec directly (a Purpose in a delta is read only when a capability is created).
- Add a pinned OpenSpec 1.14.1 install and an `openspec validate --all --strict` gate: a Taskfile task wired into `task check`, and a step in the CI job `Validate schema`.

No requirement changes meaning. No scenario is dropped or reworded. No `*.cue` file, no `SPEC.md` section and no published schema changes.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
The delta of each capability restates its long requirements in shorter form. Behavior stays the same.
- `artifact-identity`
- `catalog-contracts`
- `contract-fulfilment`
- `definitions-reference`
- `docs-bundle`
- `instance-identity`
- `name-constraints`
- `platform-contract-inventory`
- `platform-registry`
- `primitive-keying`
- `release-cascade`
- `schema-pins`
- `schema-release`
- `transformer-context`

`cite-lint` gets its Purpose by a direct edit of the main spec and has no delta.

## Impact

- Release class: none. The published CUE schema is byte-identical before and after, so the commits are `docs`, `ci` or `chore`, never `feat` or `fix`. No break, so the beta break licence is not used, and no `catalogs/opm` major is forced.
- Downstream consumers (`library`, `cli`, `opm-operator`, the catalogs, `modules`): none is reached. They consume the published schema, which does not change. Nothing for them to do.
- Files: `openspec/specs/*/spec.md` (through the archive), `openspec/specs/cite-lint/spec.md`, `Taskfile.yml`, `.github/workflows/ci.yml`. The CI job `Validate schema` is the required check, so the new step is covered by `.tasks/cascade/wiring-check.sh` (see design).
- Open changes of other authors: none in `openspec/changes/` on the base `a015044e`, so no collision.
- Delivery: one PR per change.
- The `docs/site` page `platforms-and-catalogs.md` and `SPEC.md` mention phrases that also appear as requirement names. The apply units grep for every old header before a rename or split.

## Enhancement

None.
