# Design: platform-contract-inventory

## Context

See `proposal.md` § Why. The decisions are `enhancements/0015` D1, D2 and D18; the pre-drafted shape is `enhancements/0015/schemas/target.cue` (`#ContractInventory`, `#ContractRouting`, as amended by D18 into `fulfilled`/`routable`). This document maps that delta onto `src/platform.cue` and records where it deviates.

Current state: `#Platform` (`src/platform.cue`) derives `#composedTransformers` by comprehension over enabled entries; `#CatalogEntry.#catalog` embeds the catalog whole, and since `alpha.8` that catalog carries `#resources`, `#traits`, `#blueprints` with stamped provenance. `#ComponentTransformer.requiredResources?` and `requiredTraits?` are optional maps.

## Goals / Non-Goals

**Goals**

- One derived value a platform carries that answers "what is defined, by whom, required by what, unfulfilled, over-subscribed", evaluable with no module in hand and on the definition alone.
- Reports, not assertions (D18).

**Non-Goals**

- No D5 comparable-predicate guard (OQ9 deferred).
- No refusal site in `core`: generation (operator, CLI) reads `routable`.
- No per-contract `#ContractRouting` construct (see Research & Decisions).
- No change to `#CatalogEntry`, `#composedTransformers` or the match glue's inputs.

## Decisions

### The schema delta

`src/platform.cue`, beside `#CatalogEntry` (doc comments elided; the real file carries them under the 6-line rule):

```cue
// #ContractInventory: the defined-versus-required cross a #Platform derives
// from its enabled entries (enhancement 0015 D1, D2, D18).
#ContractInventory: {
	defined:   [#ContractFQNType]: #Resource | #Trait | #Blueprint
	definedBy: [#ContractFQNType]: #ModulePathType
	requiredBy: [#ContractFQNType]: [...#ImplFQNType]
	unfulfilled:    [...#ContractFQNType]
	overSubscribed: [...#ContractFQNType]
	fulfilled: bool & (len(unfulfilled) == 0)
	routable:  bool & (len(overSubscribed) == 0)
}
```

Inside `#Platform`, after `#composedTransformers`:

```cue
	#contracts: #ContractInventory & {
		defined: {
			for _, entry in #registry if entry.enable {
				for fqn, r in entry.#catalog.#resources {(fqn): r}
				for fqn, t in entry.#catalog.#traits {(fqn): t}
				for fqn, b in entry.#catalog.#blueprints {(fqn): b}
			}
		}
		definedBy: {
			for path, entry in #registry if entry.enable {
				for fqn, _ in entry.#catalog.#resources {(fqn): path}
				for fqn, _ in entry.#catalog.#traits {(fqn): path}
				for fqn, _ in entry.#catalog.#blueprints {(fqn): path}
			}
		}
		requiredBy: {
			for fqn, _ in defined {
				(fqn): [
					for k, tf in #composedTransformers if tf.requiredResources != _|_ for req, _ in tf.requiredResources if req == fqn {k},
					for k, tf in #composedTransformers if tf.requiredTraits != _|_ for req, _ in tf.requiredTraits if req == fqn {k},
				]
			}
		}
		_providers: {
			for fqn, c in defined if c.kind != "Blueprint" if c.fulfilment == "provider" {
				(fqn): {for _, k in requiredBy[fqn] {(#composedTransformers[k].metadata.modulePath): true}}
			}
		}
		unfulfilled:    [for fqn, ps in _providers if len(ps) == 0 {fqn}]
		overSubscribed: [for fqn, ps in _providers if len(ps) > 1 {fqn}]
	}
```

Measured on a scratch copy of `src/` (cue v0.17.1, 2026-09-13) with three stand-in catalogs (a base catalog listing a resource, a catalog-fulfilled trait, a provider-fulfilled `backup` trait and a blueprint, plus one adapter; a k8up-shaped and a velero-shaped catalog each with one adapter requiring `backup`) and five platforms: empty registry (all empty, both booleans true); base only (`unfulfilled: [backup]`, `fulfilled: false`, `routable: true`); base plus k8up (both true); base plus k8up plus velero (`overSubscribed: [backup]`, `routable: false`); base plus a disabled k8up (as base only). `#Platform.#contracts` also evaluates on the bare definition.

## Research & Decisions

### Reports, not assertions

**Context**: 0015's pre-draft asserted `#ContractRouting` on the platform value; D18 split the answer into a report (`fulfilled`) and a gate (`routable`).
**Explored**: asserting `routable: true` inside `#Platform` (a bottom on over-subscription, so the value cannot say which contract; every diagnostic reads a failed value); deriving the lists and leaving refusal to the generation step, which already exists in the CLI's render validation (it counts providing catalogs and refuses naming them) and will exist in the operator's generation.
**Decision**: derive only. `routable: false` is a value the generation step refuses on; `fulfilled: false` is a value the operator surfaces as a condition.
**Rationale**: a refusal that names its parties needs the value to evaluate; and D18's whole point is that one of the two reports must not gate anything, which an in-schema assertion cannot express.

### No `#ContractRouting` construct

**Context**: `target.cue` and `spec.md` in 0015 name a per-contract arity relation.
**Explored**: landing it beside the inventory (a definition a caller unifies per contract with `implementations`); folding its content into the inventory's lists and booleans.
**Decision**: fold. The inventory's `overSubscribed`/`routable` state the arity rule for every contract at once; `requiredBy` is the per-contract implementation list the relation took as input.
**Rationale**: Principle V; the relation would be a second statement of the same two facts, and no consumer would unify it rather than read the lists. Recorded as a deviation from 0015's pre-draft; 0015 D1/D2 are unchanged by it.

### Over-subscription counts catalogs

**Context**: 0010 D37 says "exactly one transformer requiring the contract"; experiment 02's earlier cut found the CLI's rule counts catalogs ("supplied by transformers from 2 catalogs"), so one provider catalog may carry two adapters over one contract (k8up's Schedule and PreBackupPod).
**Explored**: counting transformers (refuses k8up's own shape); counting the stamped `metadata.modulePath` of each requiring transformer, distinct per catalog.
**Decision**: catalogs, via the stamp; `_providers` keys a struct by `modulePath`, which deduplicates.
**Rationale**: matches the shipped refusal's rule and the provider design; the stamp is unforgeable (0010 D25), so a catalog cannot pose as two.

### Presence guards on optional demand maps

**Context**: `requiredResources?` and `requiredTraits?` are optional on `#ComponentTransformer`.
**Explored**: an unguarded `for req, _ in tf.requiredTraits` failed the probe on a transformer declaring only `requiredResources`; `if tf.requiredTraits != _|_` skips it (the map, when present, is a concrete struct, so the guard is sound here, unlike the non-concrete-value case `#nameConstraint` records).
**Decision**: guard both comprehensions.
**Rationale**: catalog_opm's transformers declare both maps, but the schema does not require it, and the inventory must not fail a platform over a transformer's omitted empty map.

### `definedBy` added to the pre-draft's shape

**Context**: D18's diagnostic names the defining catalog; the pre-draft's `defined` carried only the member (its stamped `modulePath` is a package path, not the registry key).
**Explored**: parsing the catalog back out of the stamped `modulePath` (the prefix derivation 0010 D17 records as unreliable); recording the registry key in the same fold.
**Decision**: `definedBy: [#ContractFQNType]: #ModulePathType`, the entry's key.
**Rationale**: free in the fold, and it is the value every diagnostic wants to print.

### `defined` typed as the primitive disjunction

**Context**: The pre-draft typed members as a `#PublishedContract` projection; `catalog-contract-maps` landed the member as the primitive itself.
**Explored**: `#Resource | #Trait | #Blueprint` as the value type (resolves per member on `kind`, measured on the probe); an open struct.
**Decision**: the disjunction.
**Rationale**: a consumer reading `defined[fqn].fulfilment` gets the primitive's own field; the disjunction refuses a non-member value in the map.

### Closedness measurement, recorded for the modified `platform-registry` requirement

**Context**: The existing "no reverse index" scenario said a declared `#matchers` MUST be rejected as a field not allowed.
**Explored**: `#Platform & {#undeclaredMap: {a: 1}}` evaluated and read back `1`: closedness does not refuse an undeclared definition field.
**Decision**: restate the scenario as "inert, unread"; add the `requiredBy` carve-out.
**Rationale**: a spec scenario that a test would fail is worse than none; this change touches that requirement anyway.

## Files and tracked constructs

- `src/platform.cue`: `#ContractInventory` added beside `#CatalogEntry`; `#Platform.#contracts` added after `#composedTransformers`; a WHY block on report-versus-gate (D18) and on counting catalogs, each pointing at SPEC.md §3.4.
- `SPEC.md` §3.4 (same commit): a `#ContractInventory` subsection (Definition, Shape, Constraints, Rationale) beside `#CatalogEntry`; `#Platform`'s Shape gains `#contracts`, Constraints gain the derived-never-authored and reports-never-refuse rules, Rationale gains "Why the inventory reports and does not refuse" (D18), "Why over-subscription counts catalogs" and "Why no per-contract routing relation".
- `.tasks/spec-tracked.txt`: add `#ContractInventory`.
- `src/platform_contracts_pins.cue` (new): the three stand-in catalogs and five platforms from the probe as hidden fields, each report pinned by interpolation or `len`, plus the definition-level evaluation pin. Pins convention per `platform_and_match_pins.cue`'s header; must-fail cases: none (nothing refuses).
- `src/INDEX.md`: `task generate:index`, one row added.
- `openspec/specs/platform-registry/spec.md` (via the delta): the reverse-index requirement restated.

**Closedness / defaults / required-set callouts:**

- `#ContractInventory` is a closed definition with no defaults and no required fields; every field is derived where it is used.
- `#Platform` gains one hidden derived field; nothing existing moves. A platform author writing `#contracts` by hand conflicts with the derivation on the first key, which is the intended refusal.
- The `_providers` hidden field lives inside the derived value and is not part of the published shape.

## Risks / Trade-offs

- [Evaluation cost in every platform build] -> `defined × transformers × demands` string comparisons, about ten thousand for catalog_opm's 72 members and 45 transformers; two comprehensions per contract, no nested unification. If a fleet measures it, `requiredBy` can be inverted (one pass over transformers) without changing the shape.
- [A catalog that lists nothing yields `fulfilled: true` vacuously] -> named in 0015 `06-operational.md`; closed by `catalog-contract-listing` and its listing gate, not here.
- [Optional demands are invisible to the inventory] -> by design (0010 D32); a contract only optionally consumed is "unfulfilled" and reported as such, which is the correct reading of tolerance.
- [Two builds of one catalog cannot be told apart by `modulePath`] -> one entry per path (0019 D5) already makes that state inexpressible.

## Migration Plan

One commit: `src/platform.cue` + `src/platform_contracts_pins.cue` + `.tasks/spec-tracked.txt` + `SPEC.md` + regenerated `src/INDEX.md`, subject `feat(platform): derive the contract inventory from the registry`. release-please cuts `alpha.9`; CI publishes on the release merge. Rollback before release is a revert; after, a later release, safe while no consumer reads `#contracts` (the CLI pre-flight is the first, in its own change).
