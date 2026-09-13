## Why

`catalog-contract-maps` (core `alpha.8`) made contracts catalog members. Nothing reads them yet: a platform still cannot say which contracts its subscribed catalogs define, which of those nothing implements, and which have two providers, until somebody deploys a module that trips over one. Enhancement 0015 D1 makes that answer a pure CUE fold over the platform's embedded catalogs (0019 D5), D2 keeps 0010 D37's exactly-one-provider rule and names the refusal, and D18 (2026-09-13) settles what the answer does: an unfulfilled contract is reported, never refused; only over-subscription refuses platform-package generation.

This change is `platform-contract-inventory`, the second and last core slice of 0015 D1, implementing D1's fold, D2's arity reports and D18's report-versus-gate split. It lands `#ContractInventory` and `#Platform.#contracts` in `src/platform.cue` and `SPEC.md` §3.4.

## What Changes

- `#ContractInventory` is added, a tracked construct: `defined` (every contract every enabled entry's catalog lists, keyed by contract FQN, the member value itself), `definedBy` (contract FQN to the registry path of the catalog listing it), `requiredBy` (contract FQN to the implementation FQNs of every enabled transformer requiring it), `unfulfilled` (provider-fulfilled contracts required by nothing), `overSubscribed` (provider-fulfilled contracts required by transformers from more than one catalog), and two derived booleans: `fulfilled` (no `unfulfilled`) and `routable` (no `overSubscribed`).
- `#Platform.#contracts` is added: the derived fold producing that inventory from `#registry` and `#composedTransformers`. Never authored, never runtime-filled, empty on an empty registry.
- The inventory reports; it does not assert. An over-subscribed platform value still evaluates and names the contract; withholding the generated platform package on `routable: false` is the generation step's act (0019 D6, operator and CLI), and surfacing `unfulfilled` as a non-gating condition is the operator's (D18). No `#ContractRouting` construct: the per-contract relation 0015's pre-draft named adds nothing the inventory's two lists and two booleans do not already state.
- `SPEC.md` §3.4 co-update under `core-schema-edit`: `#ContractInventory` documented beside `#CatalogEntry`, `#Platform`'s Shape, Constraints and Rationale extended.
- `src/platform_contracts_pins.cue` (new): hidden-field pins over three stand-in catalogs and five platforms (empty, one catalog, one provider, two providers, disabled provider), every value forced by indexing or interpolation.

## Classification

**MINOR, additive** (Principle I): `#Platform` gains one derived hidden field; no existing field changes shape, default, closedness or required-set; a platform whose catalogs list nothing gets an empty inventory with both booleans true. It does not rely on the v2 line still being pre-release, but it is the half of 0015 D1 that reads the maps `alpha.8` added, so the pair belongs on one side of a stable `2.0.0` cut.

## Downstream consumers

- **`library`**: nothing to do now. The fold evaluates inside every platform build the kernel already runs; its cost is one pass over `defined × transformers × demands` (about ten thousand string comparisons for catalog_opm's shape), measured on the scratch probe as unnoticeable at that size. The kernel reads nothing new until a caller asks.
- **`cli`**: the next change reads `#contracts` for `opm platform check` (unfulfilled, over-subscribed, defining catalogs) and can replace its own over-subscription count in render validation (which already counts catalogs, the same rule) with `#contracts.overSubscribed`. The "defined but unimplemented" arm of the unresolved-demand verdict (0010 OQ3) reads `definedBy`.
- **`opm-operator`**: the 0015 operator slice surfaces `fulfilled` as the non-gating `ContractsFulfilled` condition and refuses generation on `routable: false`, naming `overSubscribed` and `definedBy`. Nothing until that slice.
- **`catalog_opm`**: its listing change (`catalog-contract-listing`) is what makes `defined` non-empty; without it the inventory is vacuously fulfilled, which 0015 `06-operational.md` names as the failure to guard against.
- **`modules`**: nothing to do.
- **`opmodel.dev`**: the generated schema reference picks the construct up on its next `task generate`.

## Principle V

Each field has a reader named above: `defined` and `definedBy` by the verdict arm and the CLI pre-flight, `requiredBy` by the derivation of both reports and by `opm platform check`, `unfulfilled` and `fulfilled` by the operator condition, `overSubscribed` and `routable` by the generation refusal. What is left out is a per-contract `#ContractRouting` relation and a projection type for `defined`, both of which would restate the inventory.

## Capabilities

### New Capabilities

- `platform-contract-inventory`: what a `#Platform` derives about the contracts its enabled catalogs define and its enabled transformers require: the two maps, the two reports, the two booleans, the rule that the inventory reports and never refuses, and the empty-registry case.

### Modified Capabilities

- `platform-registry`: the "A platform carries no reverse index" requirement keeps `#matchers` gone and adds that `#contracts.requiredBy` is a derived readiness index the match glue never reads, not a matcher bucket; its scenario is restated against measured closedness (an undeclared definition field is inert, not refused).

## Impact

- `src/platform.cue`: `#ContractInventory` added; `#Platform.#contracts` added; the file's WHY blocks gain the report-versus-gate paragraph.
- `SPEC.md` §3.4 (same commit, `core-schema-edit` protocol).
- `.tasks/spec-tracked.txt`: `#ContractInventory` added (top-level published construct, not a helper).
- `src/platform_contracts_pins.cue` (new).
- `src/INDEX.md`: regenerate; one definition added.
