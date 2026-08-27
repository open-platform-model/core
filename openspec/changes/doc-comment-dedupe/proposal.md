## Why

The doc-comment sweep (`2026-08-27-doc-comment-sweep`) moved rationale out of hover text but deferred two review findings. First, several `// WHY` blocks restate SPEC.md Rationale bullets near-verbatim (`fulfilment`, `resourceName`, `_matchLabelsAreDerived`, `_nameFits`), and the `#nameConstraint` block is repeated on all three primitives, with the trait and blueprint copies pointing at `§ 2.2 Rationale` / `§ 3.3 Rationale`, which do not contain the bullet. Two copies of one argument drift; the sweep itself had to fix one such drift. Second, `backup` is the running example in 60 places (schema comments, SPEC.md § 2.1/2.2/3.1, both pins files) and is described as something `catalog_opm` declares; no catalog ships it, and no real member has `fulfilment: "provider"` or trait-level `optional: true` to take its place.

## What Changes

- A rule: state a rationale once. A WHY paragraph that restates a SPEC.md Rationale bullet collapses to the bullet's title in the closing pointer; when several definitions share one rule, one carries the WHY block and the others a two-line pointer. Recorded in `CLAUDE.md` § Doc comments and `core-schema-edit` § Writing comments.
- Six WHY blocks collapsed under that rule (`trait.cue`, `blueprint.cue` `#nameConstraint`; `resource.cue` `fulfilment`; `component.cue` `resourceName`, `_matchLabelsAreDerived`, `_nameFits`). Measured evaluator behaviour stays in the block; every dropped sentence exists in the cited SPEC.md bullet. The false `§ 2.2` / `§ 3.3 Rationale` pointers are corrected.
- `backup` stated to be hypothetical at its introduction points: SPEC.md § 2.1 (first mention, in full), § 2.2 and § 3.1 (short form), `trait.cue`, `resource.cue`, `types.cue`, `platform_and_match_pins.cue`. Claims that `catalog_opm` declares it become "a catalog". Fixture values (`identity_pins.cue` FQNs) untouched.
- No schema change. Every `src/*.cue` file is code-identical to `main` with comments stripped.

## Capabilities

None. Documentation only; no delta specs (`skip_specs`).

## Impact

- Release: `docs:` and comment-only commits, hidden in this repo; no release.
- SPEC.md: four prose edits in Rationale/Constraints text, no construct inventory change (`task spec:check` unchanged).
- Downstream: none. Published module evaluates identically.
