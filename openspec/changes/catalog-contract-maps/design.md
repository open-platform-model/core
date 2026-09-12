# Design: catalog-contract-maps

## Context

See `proposal.md` § Why. The decision is `enhancements/0015` D1; the shape is pre-drafted in `enhancements/0015/schemas/target.cue` (`#CatalogContractMaps`) and `schemas/spec.md`, written standalone and before 0010 D49's version-segment filing. This document maps that delta onto `src/catalog.cue` and this repo's protocols and records the two places it deviates from the pre-draft.

Current state: `#Catalog` (`src/catalog.cue`) carries `metadata` and one member map, `#transformers: [#ImplFQNType]: #ComponentTransformer & {metadata: {modulePath: "\(M._ref.registryPath)/transformers", catalogVersion: M.version}}`. Its doc comment reserves the extension this change makes ("Adding sibling maps (#resources, #traits, #blueprints) is an additive extension if introspection demand surfaces later"). Contract members in catalog_opm author `modulePath: "\(id.kindPrefix.<kind>)/<apiVersion>"` and `catalogVersion: id.Version`, and `#CatalogMemberFQNGate` derives the same two values at publish.

## Goals / Non-Goals

**Goals**

- Land the three member maps with stamps that unify, with no authored change, against every member catalog_opm ships today.
- Keep the change additive: no existing `#Catalog` field moves, and an unlisted member is exactly as it was.
- Exercise the delta in-repo, since 0015 ships no `examples.cue`.

**Non-Goals**

- No inventory fold on `#Platform` (`#ContractInventory`, `#ContractRouting`): the second 0015 slice, gated on the readiness decision named in the proposal.
- No `#PublishedContract` projection type (see Research & Decisions).
- No completeness check ("every contract the catalog defines is listed"): `core` cannot see unlisted members; that is a publish gate in the 0011 family, owned by `cli`.
- No change to `#TraitOptionalGate`, `#CatalogMemberFQNGate` or the identity package.

## Decisions

### The schema delta

`src/catalog.cue`, inside `#Catalog` after `#transformers` (doc comments elided; the real file carries them under the 6-line rule):

```cue
	// Contract members. Each map stamps provenance the way #transformers
	// does; the modulePath stamp carries the member's own apiVersion as its
	// filing segment (0010 D49), read through a label alias because the
	// interpolation sits inside the same struct literal as the field.
	#resources: [#ContractFQNType]: #Resource & {
		metadata: {
			A=apiVersion:   #APIVersionType
			modulePath:     "\(M._ref.registryPath)/resources/\(A)"
			catalogVersion: M.version
		}
	}
	#traits: [#ContractFQNType]: #Trait & {
		metadata: {
			A=apiVersion:   #APIVersionType
			modulePath:     "\(M._ref.registryPath)/traits/\(A)"
			catalogVersion: M.version
		}
	}
	#blueprints: [#ContractFQNType]: #Blueprint & {
		metadata: {
			A=apiVersion:   #APIVersionType
			modulePath:     "\(M._ref.registryPath)/blueprints/\(A)"
			catalogVersion: M.version
		}
	}
```

`M` is the existing `M=metadata` field-label alias on `#Catalog.metadata` (0001 D25). `A=apiVersion` is a label alias on the member's own required field: a bare `apiVersion` inside the literal is `reference "apiVersion" not found`, because lexical resolution sees only the fields the literal itself declares, not the ones `#Trait` supplies by unification (measured, see Research & Decisions).

Authoring shape a catalog uses, mirroring `#transformers`:

```cue
#traits: {
	(t.#BackupTrait.metadata.fqn):  t.#BackupTrait
	(t.#ScalingTrait.metadata.fqn): t.#ScalingTrait
}
```

## Research & Decisions

### The member value is the primitive itself, not a projection

**Context**: `enhancements/0015/schemas/target.cue` states the member as `#PublishedContract`, a metadata projection (name, kind, modulePath, apiVersion, catalogVersion, fqn, fulfilment, description).
**Explored**: the projection as a new tracked construct; the primitive value with the same stamping pattern constraint `#transformers` uses.
**Decision**: the primitive value (`#Resource` / `#Trait` / `#Blueprint`).
**Rationale**: it is the idiom `#transformers` already establishes (`(fqn): value`), so a catalog author lists a contract the way they list an adapter, and the listed value is the same value the transformers' required maps already carry, not a second copy that can drift from it. `fulfilment` is readable directly off a resource or trait, which is what 0015 D11's `provides` fold reads; a blueprint has no `fulfilment` field (0010 D44), so a projection carrying one would state something a blueprint structurally refuses. One fewer published construct (Principle V), and nothing new to track.

### The stamp carries the member's apiVersion segment

**Context**: `target.cue` stamps `modulePath: "\(RP)/traits"`, the flat form. Since 0010 D49 a contract member files under `"<kindPrefix>/<apiVersion>"`; catalog_opm authors exactly that, and `#CatalogMemberFQNGate` derives it from the member's own `apiVersion`. A flat stamp would conflict with every member catalog_opm ships.
**Explored**: the flat stamp (refused by every real member); no `modulePath` stamp at all (drops the provenance D1 point 4 exists for); the versioned stamp through a label alias.
**Decision**: `"\(M._ref.registryPath)/<kind>/\(A)"` with `A=apiVersion`.
**Rationale**: it is the value the gate already derives, so a listed member's stamp and its publish-time check agree by construction. Measured on cue v0.17.1 against a scratch copy of `src/`: a member authoring only `name`, `apiVersion` and `fqn` receives both stamps; a member authoring `.../traits/v1beta1` with `apiVersion: "v1alpha1"` fails `conflicting values` on `metadata.modulePath` naming both paths; a member authoring `catalogVersion: "3.9.0"` under a `4.1.0` catalog fails on `metadata.catalogVersion`; a `#Resource` listed under `#traits` fails on `kind`; a build-form key fails `field not allowed`. The transformer stamp stays flat: a transformer carries no `apiVersion` (0010 D44), and this change does not touch it.

### `fqn` stays unstamped

**Context**: `target.cue` writes `fqn: FQN` from the map key; the pre-drafted `spec.md` says the stamp MUST NOT cover `fqn`; 0019 D5 binds `#registry`'s key into the embedded catalog's `modulePath`.
**Explored**: binding the key into `metadata.fqn` (drift becomes a build conflict); leaving it to the publish gate, as `#transformers` does.
**Decision**: no `fqn` stamp or key binding.
**Rationale**: symmetry within `#Catalog`: four member maps with one stamping rule, stated once in SPEC.md §3.6 ("Why the pattern stamps `modulePath` + `catalogVersion` but not `fqn`"), and 0010 D21's rule that an `fqn` is authored at the definition site. The agreement between key, `fqn` and identity package is `#CatalogMemberFQNGate`'s at publish, which already covers all four kinds. If a later change wants the key bound for the contract maps, it is additive.

### In-repo pins rather than an enhancement example

**Context**: `core-registry-import` shipped no core-side fixture because `enhancements/0019/schemas/examples.cue` exercised its delta. 0015 has `target.cue` and `spec.md` but no `examples.cue`.
**Explored**: adding `examples.cue` to 0015 (a different repo, and the file would restate core rather than import it); a pins file here.
**Decision**: `src/catalog_pins.cue`, hidden top-level fields in the convention `identity_pins.cue` and `platform_and_match_pins.cue` set: every pin forces evaluation (indexing or interpolation), must-fail cases are commented out with the exact error the tool printed at the commit that introduced them, and the filename does not start with an underscore.
**Rationale**: the delta's whole content is the stamps' behaviour on listed members, which `task vet` can pin directly. Positive pins: a lean member's two stamped values, a provider-fulfilled trait's `fulfilment` read through `#traits` under `#transformers: {}`, and an empty catalog's three empty maps. Must-fail comments: filing drift, stale `catalogVersion`, kind mismatch, build-form key. Pin values are copied in shape from catalog_opm, not imported: `core` has no dependencies.

### No reuse of `#ResourceMap` / `#TraitMap` / `#BlueprintMap`

**Context**: `core` already exports string-keyed maps of the three primitives, used by `#Component`.
**Explored**: `#traits: #TraitMap & {...}`.
**Decision**: fresh pattern constraints keyed `#ContractFQNType`.
**Rationale**: the existing maps are `[string]:` keyed, so reusing them would admit a build-form key the `primitive-keying` capability requires refusing; `#Catalog.#transformers` likewise does not reuse `#TransformerMap` for its stamped form.

## Files and tracked constructs

- `src/catalog.cue`: the three maps inside `#Catalog`. The WHY block's "Resources / Traits / Blueprints are surfaced transitively ... additive extension if introspection demand surfaces later" paragraph is rewritten to state the contract maps and their stamp (pointing at SPEC.md §3.6 for the argument); the `#Catalog` doc comment's last sentence ("Resources, traits and blueprints surface transitively through each transformer's required/optional maps") is replaced within the 6-line rule. Each map gets a doc comment at most 6 lines with a `SPEC.md § 3.6` pointer.
- `SPEC.md` §3.6 (same commit): Definition gains the contract-member sentence; Shape adds the three maps; Constraints replace the "Resources, Traits, and Blueprints are NOT enumerated" bullet with the key-type, stamp, unstamped-`fqn`, no-adapter-required and empty-is-valid rules; Rationale replaces "Why catalogs don't enumerate Resources / Traits / Blueprints" with "Why a catalog publishes its contracts as members" (0015 D1), and adds "Why the contract stamp carries the member's apiVersion segment while the transformer stamp does not" (0010 D44/D49) and "Why the member is the primitive itself rather than a projection". "See also" gains `#Resource`, `#Trait`, `#Blueprint` under Publishes.
- `src/catalog_pins.cue` (new): the pins above. Hidden fields only, so `src/INDEX.md` gains no row.
- `src/types.cue`: the "WHY unused inside `core`, per role" comment table gains the row `#Catalog.#resources/#traits/#blueprints  map keys  #ContractFQNType`. Comment-only.
- `src/INDEX.md`: `task generate:index`; unchanged. The generator extracts only the first sentence of the `#Catalog` doc comment, which this change keeps, so no row moves and `task generate:index:check` passes without a regeneration diff.
- `.tasks/spec-tracked.txt`: unchanged. No new top-level construct is introduced; `#Catalog` is tracked and its §3.6 section moves with the CUE.
- `docs/` and `README.md`: no hit for catalog member prose (grepped 2026-09-12); nothing to rewrite.

**Closedness / defaults / required-set callouts** (per this repo's design rules):

- `#Catalog` stays a closed definition. Three hidden fields become declarable on it that were `field not allowed` before; that is the whole of the accepting change.
- No default and no required field is added. Each map is a pattern constraint; absent means empty.
- A listed member's `metadata.modulePath` and `metadata.catalogVersion` become stamped: an authored value that disagrees is now a conflict where before, unlisted, it was unchecked by `core`. Unlisted members are untouched.
- The `A=apiVersion` alias declares `apiVersion` in the stamp literal as `#APIVersionType`, the same type `#Resource`/`#Trait`/`#Blueprint` already require; it adds no constraint.

## Risks / Trade-offs

- [Partial listing: a catalog may define a contract and not list it, and `core` cannot tell] → accepted here. The inventory the second slice computes is only as complete as the listing; catalog_opm lists everything in its own change, and a publish gate in the 0011 family ("every provider-fulfilled contract is listed") is the structural close, owned by `cli`. Named in the proposal as a follow-up.
- [The stamp refuses a member whose authored `modulePath` predates 0010 D49's version segment] → no shipped catalog on the v2 line authors the flat form (catalog_opm is at v4 with version-segment filing; the v1 branch pins core v1 and never sees this change). The old-shape values in `platform_and_match_pins.cue` are unaffected because they are never listed in a catalog.
- [Two slices for one decision] → the maps are pure data and safe to publish alone; the fold is where the readiness semantics bite, and 0015 owes a decision there before it lands. Both slices declare D1 in `enhancement.yaml`; the delivery log records which half each landed.
- [`target.cue` in 0015 is now stale on two points (flat stamp, `#PublishedContract`)] → a doc-only follow-up in `enhancements/0015` (an amending decision or a schema note); not this change's scope.

## Migration Plan

One commit: `src/catalog.cue` + `src/catalog_pins.cue` + `src/types.cue` + `SPEC.md` (`src/INDEX.md` unchanged), subject `feat(catalog): publish resources, traits and blueprints as catalog members`. release-please cuts a release on the v2 alpha line; CI publishes on the release merge. Rollback before release is a revert; after release, a revert in a later release, safe as long as no published catalog has listed members yet (catalog_opm's listing waits for this release).

Downstream: nothing re-pins for this change alone. catalog_opm bumps core to the release that carries it in its listing change (`task deps:update`), and that is the first consumer.
