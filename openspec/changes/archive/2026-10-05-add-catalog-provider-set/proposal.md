## Why

The rule "which provider-fulfilled contracts does this catalog implement" exists twice, and neither copy is a catalog's own field. Core derives it only per platform (`_providerSet` inside `#Platform.#contracts`, `src/platform.cue`), and the library derives it per catalog in Go (`Catalog.Provides()`, `library/opm/catalog/provides.go`), which `opm-operator` uses to check a transformer registration's claimed `provides` list (0015:D11). Two implementations of one rule can drift, and the Go one is chosen by the kernel binary rather than by the core version the catalog pins.

The owner decided (beta.1 kernel plan walkthrough, task h2): "Core gains a per-catalog provider set (additive core release); Provides() decodes it and falls back to the deprecated Go fold for older catalogs; the fallback is removed before GA, after catalog_opm is republished." Library ADR-012 names this set as the next derived rule to move into core, one at a time, each move an additive core release with a parity check. This change is the core half only. The supervisor's wave-2 decision SD3 gives it its own core release, cut before the breaking `core-j3` change.

It implements no undelivered enhancement decision (0015 is archived and 0015:D11 is delivered; ADR-012 is a library ADR), so it carries no `enhancement.yaml`.

## What Changes

- **`#Catalog` gains a regular field `provides: [...#ContractFQNType]`**, derived and never authored: the ascending-sorted, deduplicated FQNs of every contract that one of the catalog's own `#transformers` names in `requiredResources` or `requiredTraits` with a requirement whose `fulfilment` is `"provider"`. Optional demands, required labels and catalog-fulfilled requirements do not count. Fulfilment is read from the demand entry's own value, never from the catalog's `#resources` / `#traits` maps: a provider catalog implements contracts another catalog defines, so its own maps do not list them. A catalog with no transformers, or none requiring a provider-fulfilled contract, derives `[]`. This is exactly the rule `_providerSet` folds per registry entry and `Catalog.Provides()` folds in Go.
- The field is regular (not hidden, not a definition), so the library reads it with a plain `LookupPath` from the catalog value, the operator sees it in an export, and its name matches the claim field it is compared against (`spec.transformerRegistration.provides`, 0015:D11). It does not clash with any `#ContractInventory` field name (`providedBy` is the platform-level map).
- **Parity pins** in `src/pins/platform_contracts_pins.cue`: per-catalog `provides` literals on the existing inventory fixtures (one entry through two adapters, an optional-only consumer, a base catalog that only defines `backup`, the bare definition) and on a new provider fixture that requires a provider-fulfilled resource under `requiredResources` beside the `backup` trait, so both demand arms are pinned. A hidden reference derivation in the pins re-derives the set with the per-transformer rule (walk `#transformers`, test `fulfilment == "provider"`) independently of `src/`, and must equal each fixture catalog's `provides` and, folded per registry key, `#contracts.providedBy` on one provider, two providers, a disabled provider entry, two majors of one provider and the new resource-provider platform. A commented must-fail pin in `src/pins/catalog_pins.cue` records the error an authored disagreeing `provides` gives.
- **`#Platform.#contracts._providerSet` reads each enabled entry's `#catalog.provides`** instead of re-walking the transformers, so platform and catalog share one rule. This lands only because the pins prove it identical: measured during planning, every existing `providedBy`, `overSubscribed`, `unfulfilled` and readout pin stays green with the refactor applied. No value changes.
- `SPEC.md` §3.6 `#Catalog` (Definition, Shape, Constraints, Rationale) and §3.4 (the `#contracts` Shape block and the `providedBy` derivation constraint) are updated in the same commits. `src/INDEX.md` is regenerated if the `#Catalog` doc comment changes.

Not in this change: the library decode and deprecated Go fallback (`lib-h2`), the catalog_opm republish (a core pin bump through its deps-cascade), the operator's old-catalog integration test, and moving catalog_opm's own `#PreBoundRegistration._providerSet` onto this field.

## Release class

MINOR per Principle I: an additive derived field on `#Catalog`; no constraint tightens, no default or required field changes. It does not rely on the `@v2` beta break licence and forces no `catalogs/opm` major. On the beta line the `feat:` advances `-beta.N`. A catalog that authored a top-level `provides` field of its own would now conflict with the derived value if they disagreed; none does (catalog_opm, the operator's provider and backup fixtures and the library testdata declare none at catalog root). `#Catalog`'s closedness is unchanged: it was closed before and stays closed, now admitting one more field.

## Downstream consumers

- `library` (`lib-h2`): after the core release, `Catalog.Provides()` decodes `provides` and falls back to the deprecated Go fold when the field is absent, which is the case for every catalog pinned to a core older than this release (a catalog is evaluated at its own core pin). The library bumps `schema.DefaultSchemaVersion` / `registrytest.DefaultCoreVersion` to test the decode path. Its existing `render_inventory_parity_test.go` is unaffected (no `providedBy` value changes). It owes the library ADR-012 parity test (the decoded `provides` against the Go fold on every provider fixture) until the fallback is removed; core's pins are not that test.
- `catalog_opm`: no source change. The deps-cascade core pin bump republishes `opm` with the field present; that republish is the gate for deleting the library fallback before GA.
- `opm-operator`: no change from this release. It keeps calling `Provides()`; an integration test for an old catalog rides the operator's later h2 change.
- `cli`, `modules`, `opm-modules`: nothing to do; picking up the release is an ordinary pin bump.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `catalog-contracts`: a catalog derives the provider-fulfilled contracts its own transformers require, as `provides`.
- `platform-contract-inventory`: `providedBy` is the fold of the enabled entries' `provides`, which pins check.

## Impact

- `src/catalog.cue` (`#Catalog`), `src/platform.cue` (`#Platform.#contracts._providerSet`), `src/pins/platform_contracts_pins.cue`, `src/pins/catalog_pins.cue` (one commented must-fail pin), `SPEC.md` §3.4 and §3.6, `src/INDEX.md` if regenerated output changes.
- No new construct, so nothing is added to `.tasks/spec-tracked.txt` and no `docs-kit.cue` placement is needed.
- Merge order: this change merges and is released before `core-j3` (both edit `src/catalog.cue` and `src/pins/`); `core-j3` rebases on it.
