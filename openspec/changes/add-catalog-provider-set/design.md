## Context

At `origin/main` (ced0952, core v2.0.0-beta.2 plus ci), `#Catalog` (`src/catalog.cue`) carries `kind`, `metadata`, the contract maps `#resources`, `#traits`, `#blueprints` and `#transformers`, and derives nothing about provision. The rule lives in two other places:

- `src/platform.cue`, `#Platform.#contracts._providerSet`, per enabled registry entry:

  ```cue
  _providerSet: {
  	for rkey, entry in #registry if entry.enable
  	for _, tf in entry.#transformers {
  		if tf.requiredResources != _|_ {
  			for fqn, req in tf.requiredResources if req.fulfilment == "provider" {(fqn): (rkey): true}
  		}
  		if tf.requiredTraits != _|_ {
  			for fqn, req in tf.requiredTraits if req.fulfilment == "provider" {(fqn): (rkey): true}
  		}
  	}
  }
  providedBy: {for fqn, ps in _providerSet {(fqn): list.Sort([for k, _ in ps {k}], list.Ascending)}}
  ```

- `library/opm/catalog/provides.go`, `Catalog.Provides()`: the same walk over one catalog's `#transformers`, returning a sorted, deduplicated, non-nil slice.

Files this change touches: `src/catalog.cue`, `src/platform.cue`, `src/pins/platform_contracts_pins.cue`, `SPEC.md`, and `src/INDEX.md` (regenerated). Tracked constructs whose SPEC.md sections move: `#Catalog` (§3.6) and `#Platform` (§3.4). `#ContractInventory`'s shape does not change, so its §3.4 subsection only changes where the `providedBy` constraint says the set is drawn from. No construct is newly tracked: `provides` is a field of the tracked `#Catalog`.

## Goals / Non-Goals

**Goals:**

- One per-catalog provider set in core, readable by the library from the catalog value alone.
- Pins proving that the set, folded across a platform's enabled entries, equals `#contracts.providedBy`.
- `#Platform` reuses the set, so core states the rule once.

**Non-Goals:**

- The library decode, its Go fallback and its deprecation (`lib-h2`).
- Any change to `providedBy`, `overSubscribed`, `unfulfilled` or `routable` values.
- catalog_opm's `#PreBoundRegistration._providerSet` (a third copy of the rule, over a passed-in `#transformers` map); moving it onto this field is a catalog_opm follow-up.

## Decisions

### The field

```cue
#Catalog: {
	// ... kind, metadata, #resources, #traits, #blueprints unchanged ...

	// Every provider-fulfilled contract some transformer requires, deduplicated
	// through struct keys. Both demand maps are optional on #ComponentTransformer,
	// so each is presence-guarded before comprehending.
	let providerSet = {
		for _, tf in #transformers {
			if tf.requiredResources != _|_ {
				for fqn, req in tf.requiredResources if req.fulfilment == "provider" {(fqn): true}
			}
			if tf.requiredTraits != _|_ {
				for fqn, req in tf.requiredTraits if req.fulfilment == "provider" {(fqn): true}
			}
		}
	}

	// WHY provides: library ADR-012 moves one derived rule into core at a
	// time; this is the rule Catalog.Provides() folds in Go and the
	// 0015:D11 claim check compares against. SPEC.md § 3.6 Rationale,
	// "Why a catalog derives the contracts it provides".

	// provides: the provider-fulfilled contracts this catalog implements,
	// sorted and deduplicated: every requiredResources or requiredTraits
	// key of its #transformers whose requirement reads fulfilment
	// "provider". Derived, never authored. See SPEC.md § 3.6.
	provides: [...#ContractFQNType] & list.Sort([for fqn, _ in providerSet {fqn}], list.Ascending)

	#transformers: ... // unchanged
}
```

`src/catalog.cue` gains `import "list"`. The exact doc-comment wording may move during implementation, within six lines (`task docs:check`) and with the reference in the WHY block.

- **Regular field, not hidden or a definition.** A hidden field is package-scoped to `core`, so the library could not read it from a catalog value; a definition would work through `cue.Def` but would not appear in `cue export`, which is how a human or the operator compares a catalog against its claim. A regular field also matches `kind` and `metadata`, the other regular fields of `#Catalog`. The plan entry asks for exactly this.
- **Name `provides`.** It matches `Catalog.Provides()`, 0015:D11's claim field `provides`, and catalog_opm's `#PreBoundRegistration` output. It clashes with no `#ContractInventory` field (`defined`, `definedBy`, `requiredBy`, `providedBy`, `unfulfilled`, `overSubscribed`, `collisions`, `collidingEntries`, `comparable`, `fulfilled`, `routable`, `discriminated`) and with no other `#Catalog` field.
- **`let`, not a hidden helper field.** The intermediate set has no reader outside the field, so a `let` adds no surface. Measured during planning: it evaluates on cue v0.17.1 inside `#Catalog` and on every inventory fixture.
- **Derived from the demand entries, not the contract maps.** A provider catalog implements contracts another catalog defines, so reading its own `#traits` would give the empty set for exactly the catalogs this field exists for. This is the plan entry's note and the Go fold's documented reason.
- **Concreteness.** `fulfilment` defaults to `"catalog"` on `#Resource` and `#Trait`, so every demand entry's comparison is concrete and `provides` is concrete on any catalog whose transformers evaluate. On the bare definition, `#transformers` is a pattern with no entries, so `core.#Catalog.provides` is `[]`.
- **Closedness, defaults, required fields.** `#Catalog` stays closed; it admits one more regular field. No default and no required field changes. An authored `provides` that agrees unifies; one that disagrees is a `conflicting values` error, which is the intent for a derived field.
- **Error handling vs the Go fold.** The Go fold errors when a `fulfilment` is present but not a concrete string. In CUE, the same input makes `provides` incomplete or a conflict, which the library sees as an error on decode. The library change states how it maps that (out of scope here).

### The platform reuses the field

```cue
_providerSet: {
	for rkey, entry in #registry if entry.enable
	for _, fqn in entry.#catalog.provides {(fqn): (rkey): true}
}
```

`providedBy`, `unfulfilled` and `overSubscribed` are unchanged. `entry.#transformers` is `#TransformerMap & #catalog.#transformers`, so the transformers the old fold walked are the ones `#catalog.provides` is derived from. Registry-key counting is unchanged: two adapters in one entry still contribute one key, two majors still two.

In one platform build, CUE resolves one core version (MVS), and `#CatalogEntry.#catalog: #Catalog` unifies every embedded catalog with that core's `#Catalog`. So an embedded catalog whose own `cue.mod` pins an older core still gets `provides` derived inside the platform build. The "old catalog" case only arises when a catalog is evaluated standalone at its own pin, which is the library's acquire path and is handled by the library fallback.

### Commit types

Section 1 is `feat(catalog):`, a new field on the published surface. Section 2 changes the bytes of `src/platform.cue` but no derived value, which the existing literal pins prove, so it is `refactor(platform):` and cuts no release on its own.

## Research & Decisions

### Does the field evaluate, and does the platform fold agree?

**Context**: The plan entry says platform.cue reuses the field "only if the pins prove the result is identical", and Principle VI asks for a spike when design.md carries an unverified assumption.

**Explored**: On 2026-10-04, in this worktree, the field above was added to `src/catalog.cue` with a scratch pin file. Per-catalog values: the k8up fixture (two adapters requiring `backup`) gave `["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]`; the base catalog (defines `backup`, requires only catalog contracts) gave `[]`; the restic fixture (optional `backup` only) gave `[]`. A CUE fold of the enabled entries' `provides` keyed by registry key unified with `#contracts.providedBy` on `_pinInventoryTwoProviders`, `_pinInventoryDisabledProvider` and `_pinInventoryTwoMajors`; a deliberately mismatched pair (two-providers fold against one-provider `providedBy`) failed with `incompatible list lengths (1 and 2)`, so the comparison has teeth. Then `_providerSet` in `src/platform.cue` was rewritten as above and `task vet` passed with every existing pin unchanged. All edits were reverted before planning was committed.

**Decision**: No spike section. Section 1 adds the field and pins; section 2 applies the platform refactor.

**Rationale**: The one unverified assumption (the `let` form evaluates and the refactor is value-identical on the pin set) was measured. If implementation finds otherwise, section 2's fallback task drops the refactor and records the finding here.

### Where the parity pins live

**Context**: `_providerSet` is a hidden field of package `core`, so package `pins` cannot read it.

**Decision**: The parity pins compare against the regular `#contracts.providedBy`, which is `_providerSet` sorted per key. They live in `src/pins/platform_contracts_pins.cue` beside the fixtures they reuse. A small hidden definition in that file folds the enabled entries' `provides` the way `_providerSet` does.

**Rationale**: It reuses existing fixtures and needs no core-side hidden field access.
