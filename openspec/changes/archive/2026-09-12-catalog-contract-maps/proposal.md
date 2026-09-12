## Why

A `#Catalog` publishes only its `#transformers`; its resources, traits and blueprints reach a build solely by being demanded by an adapter. A contract whose declaring catalog deliberately ships no adapter, which is exactly what `fulfilment: "provider"` (0010 D37) creates, is therefore invisible: measured 2026-09-11 in `enhancements/0015/experiments/01-provider-trait-across-catalogs`, a subscribed catalog publishing a provider-fulfilled `backup` trait with an empty `#transformers` produces a no-provider refusal that cannot say the contract is defined at all. Enhancement 0015 D1 makes contracts catalog members so that "this catalog defines X" is a stated fact of the artifact, separate from "this catalog implements X".

This change is `catalog-contract-maps`, the first of two core slices of `enhancements/0015` D1. It lands the member maps on `#Catalog`. The second slice, the `#Platform` inventory fold over those maps, waits on 0015's pending readiness decision (a platform subscribing a catalog that lists a provider-fulfilled contract must not lose its generated module for lack of a provider) and is not part of this change.

## What Changes

- `#Catalog` gains three pattern-constrained member maps beside `#transformers`: `#resources: [#ContractFQNType]: #Resource`, `#traits: [#ContractFQNType]: #Trait`, `#blueprints: [#ContractFQNType]: #Blueprint`. The value is the primitive itself, the same idiom `#transformers` uses, so a listed member is `(t.#BackupTrait.metadata.fqn): t.#BackupTrait`.
- Each map stamps provenance onto its members exactly as `#transformers` does: `metadata.catalogVersion` to the catalog's `version`, and `metadata.modulePath` to `"<registryPath>/<kind>/<member apiVersion>"`, the version-segment filing 0010 D49 already requires of a contract member and `#CatalogMemberFQNGate` already derives. An authored value that disagrees is a `conflicting values` failure at a path naming the member. `fqn` stays unstamped, as for transformers.
- A catalog that lists nothing stays valid: the maps are pattern constraints with no required entries, so every existing `#Catalog` value keeps its meaning.
- `SPEC.md` §3.6 co-update (Definition, Shape, Constraints, Rationale) under `core-schema-edit`: the "catalogs don't enumerate Resources / Traits / Blueprints" constraint and its rationale bullet are replaced, not amended, since the reserved extension they described is what this change cashes in.
- A hidden-field pins file exercises the delta in-repo (`enhancements/0015/schemas/` carries no `examples.cue`), with the must-fail cases recorded as comments in the repo's pins convention.

## Classification

**MINOR, additive** (Principle I): no existing field changes shape, default, closedness or required-set; a catalog publishing no contracts validates unchanged. This slice does not rely on the v2 line still being pre-release. The pair of slices does: the inventory fold in the second slice reads these maps, and a kernel expecting them against a catalog published without them computes a vacuous readiness answer (0015 `06-operational.md`, "Semver Impact"), so both slices land before a stable `2.0.0` cut, and catalog_opm republishes with its maps populated before any consumer reads the inventory.

## Downstream consumers

- **`library`**: nothing to do now. No kernel path reads the new maps until the second slice; hidden definition fields do not reach the Go side or exported JSON, and the parity and kernel fixtures validate unchanged against a catalog that lists nothing.
- **`cli`**: nothing to do now. `opm catalog publish` enumerates members by walking packages, not by reading `#Catalog` maps. A later gate in the 0011 family, "every provider-fulfilled contract the catalog defines is listed", is what would close the completeness hole `core` cannot check; it is a follow-up, not part of this change.
- **`opm-operator`**: nothing to do.
- **`catalog_opm`**: its own change, mechanical: list every resource, trait and blueprint in the new maps in `opm/catalog.cue` (the values already exist and are imported by the transformers that demand them) and rewrite that file's "not enumerated here" comment. Members already author `catalogVersion: id.Version` and `modulePath: "\(id.kindPrefix.<kind>)/<apiVersion>"`, which is what the stamps unify with, so listing is agreement, not migration. The `backup` trait lands there beside the listing.
- **`modules`**: nothing to do; modules import primitives, never `#Catalog`.
- **`opmodel.dev`**: the generated schema reference picks up the new maps on its next `task generate`.

## Principle V

Three maps, each with a named consumer: the 0015 D1 inventory fold (second slice) reads them to compute `defined`; catalog_opm lists into them; 0015 D11's `provides` derivation folds a provider catalog's `fulfilment` values off them; and `opm platform check` reads the inventory they feed. No projection type is added: the member value is the primitive, so nothing exists that a consumer does not already unify against.

## Capabilities

### New Capabilities

- `catalog-contracts`: what a `#Catalog` publishes about the contracts it defines: the three member maps, their key type, the provenance stamps, the unstamped `fqn`, and the rule that publishing a contract requires no adapter.

### Modified Capabilities

- `primitive-keying`: the "FQN map keys are typed by the role they hold" requirement gains `#Catalog.#resources`, `#traits` and `#blueprints` in its list of contract-keyed maps, with a refusal scenario for a build-shaped key in one of them.

## Impact

- `src/catalog.cue`: the three maps added inside `#Catalog`; the doc comment and the WHY block's "surfaced transitively" sentences rewritten.
- `SPEC.md` §3.6 (same commit, `core-schema-edit` protocol).
- `src/catalog_pins.cue` (new): hidden-field pins for the stamps, the empty-catalog case and a provider-fulfilled member with no adapter; must-fail cases as comments with the recorded error text.
- `src/types.cue`: the comment table of FQN-typed map keys gains a row for the three maps (comment-only).
- `src/INDEX.md`: unchanged. No definition is added or removed, and the generator extracts only the first sentence of the `#Catalog` doc comment, which is kept.
- `.tasks/spec-tracked.txt`: unchanged. No new top-level construct; `#Catalog` is already tracked.
