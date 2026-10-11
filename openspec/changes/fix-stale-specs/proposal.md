## Why

Two live specs in `core` no longer say what the code does. Seeding the enhancement store with `specs/` found both. A reader who trusts the spec gets the wrong rule, so the specs follow the code. The code does not change.

- `catalog-member-gate`: the spec says a member's declared path equals its kind prefix. The code requires the prefix plus the member's own API version for resources, traits and blueprints. Only a transformer files at the bare prefix. The spec's example of a conformant resource is refused by the gate. Enhancement 0010 chose this filing rule (contract kinds file under their API version) after the spec was written.
- `component-matching`: the spec says a component that declares a matching key MUST fail. The code refuses only a key that adds to what the attached primitives already give. A component that restates a derived key with the same value passes.

## What Changes

- `specs/catalog-member-gate`: MODIFY two requirements. The path requirement states the derived path. The gate-shape requirement lists the API version field and shows a conformant resource at the versioned path. Every scenario name stays. Three scenarios are added for the filing rule.
- `specs/component-matching`: MODIFY the last requirement so that it states the real test (a key count) and the two cases the code allows and refuses. Every scenario name stays. Two scenarios are added.

No schema, constraint or behaviour changes, and no `.cue` file changes. Under Principle I this is neither MAJOR, MINOR nor PATCH. It does not rely on the `@v2` beta break licence. Every commit is a `docs` type, so the change cuts no release.

## Enhancement

None.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `catalog-member-gate`: the declared path of a contract member includes its API version; a transformer files at the prefix.
- `component-matching`: a component may not add a matching key; restating a derived key is not adding.

## Impact

- **library**, **cli**, **opm-operator**, **catalog_opm**, **modules**: no action. The published schema is the same.
- **Left for the owner**: `SPEC.md` line 346 says "declaring one MUST fail" in the same words as the old spec. It is outside this change (scope is `openspec/`). The owner decides whether to reword it in a `docs:` commit with `SPEC_IMPACT=none`.
