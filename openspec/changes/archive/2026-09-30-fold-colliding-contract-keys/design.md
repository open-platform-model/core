## Context

See `proposal.md` (Why). The state this design starts from, in `src/platform.cue` at `origin/main` `cbe93e0` (core `v2.0.0-alpha.12` plus a docs and a ci commit), is the fold that experiment 06 copied:

```cue
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
				...
			}
		}
```

Two enabled entries listing one contract FQN write two values to one key. The members carry different `metadata.catalogVersion` stamps (`#Catalog` stamps them, `src/catalog.cue`), and `definedBy` gets two different registry keys, so both maps conflict and the platform value is bottom. Measured on 2026-09-30 against this worktree's `src/` with the fixtures in § Pins: `cue vet` reports `#contracts.defined."…/container@v1beta1".metadata.catalogVersion: conflicting values "2.0.0" and "1.0.0"` and `#contracts.definedBy."…/container@v1beta1": conflicting values "opmodel.dev/catalogs/opm@v2" and "opmodel.dev/catalogs/opm@v1"` for every shared key.

Files touched: `src/platform.cue`, `src/platform_contracts_pins.cue`, `src/INDEX.md` (regenerated only if a first doc line moves), `SPEC.md`, `docs/site/concepts/platforms-and-catalogs.md`, and the Purpose line of `openspec/specs/platform-contract-inventory/spec.md`. Constructs in `.tasks/spec-tracked.txt` whose `SPEC.md` sections move: `#Platform` and `#ContractInventory` (§3.4). `#Resource` (§2.1) moves only in the prose bullet that names what `routable` carries; its CUE is unchanged. No construct is newly tracked: `collisions` and `collidingEntries` are fields of the tracked `#ContractInventory`, and `_definers` is a hidden helper inside `#Platform.#contracts`.

## Goals / Non-Goals

**Goals:**

- A platform whose enabled entries list the same contract key evaluates, names the key and its definers, and reads `routable: false`.
- Every platform that evaluates today reads the same value in every field.
- A pin that is red on today's core, on existing fields only, and green after the fold.

**Non-Goals:**

- Side-by-side majors. 0026 D9 (per-resolution builds) makes two majors legitimate later; this is the interim net.
- Keying `requiredBy`, `unfulfilled` or `comparable` over colliding keys (the limitation; see § Research & Decisions).
- The render refusal, the operator reason and the cli report. They are changes B, C and D in `orchestration.md`.
- The operator's build-compatibility index. That is change E, independent.

## Decisions

### The fold

This is experiment 06's `core.patch` (enhancements `0026/experiments/06-collision-tolerant-fold/core.patch`, on enhancements `origin/main` `6b94e1c`), without its `FOLD PROBE` markers. It applies cleanly to `cbe93e0`, and all seven `*_pins.cue` files pass unchanged against it (measured again for this design on cue v0.17.1).

Inside `#Platform.#contracts`, replacing `defined` and `definedBy`:

```cue
		// Per contract key, the set of enabled registry keys whose catalog
		// lists it. A key with one definer folds into defined and definedBy;
		// a key with more is a collision, reported and never folded.
		_definers: {
			for path, entry in #registry if entry.enable {
				for fqn, _ in entry.#catalog.#resources {(fqn): (path): true}
				for fqn, _ in entry.#catalog.#traits {(fqn): (path): true}
				for fqn, _ in entry.#catalog.#blueprints {(fqn): (path): true}
			}
		}
		defined: {
			for _, entry in #registry if entry.enable {
				for fqn, r in entry.#catalog.#resources if len(_definers[fqn]) == 1 {(fqn): r}
				for fqn, t in entry.#catalog.#traits if len(_definers[fqn]) == 1 {(fqn): t}
				for fqn, b in entry.#catalog.#blueprints if len(_definers[fqn]) == 1 {(fqn): b}
			}
		}
		definedBy: {
			for path, entry in #registry if entry.enable {
				for fqn, _ in entry.#catalog.#resources if len(_definers[fqn]) == 1 {(fqn): path}
				for fqn, _ in entry.#catalog.#traits if len(_definers[fqn]) == 1 {(fqn): path}
				for fqn, _ in entry.#catalog.#blueprints if len(_definers[fqn]) == 1 {(fqn): path}
			}
		}
		collisions: list.Sort([for fqn, ds in _definers if len(ds) > 1 {fqn}], list.Ascending)
		collidingEntries: {for fqn, ds in _definers if len(ds) > 1 {(fqn): list.Sort([for p, _ in ds {p}], list.Ascending)}}
```

`requiredBy`, `_providerSet`, `providedBy`, `unfulfilled`, `overSubscribed`, `_predicates` and `_comparablePairs` MUST stay textually unchanged. A disabled entry never reaches `_definers`. `list` is already imported. The worker diffs the result against experiment 06's `probe/platform.cue`; the only differences MUST be comments.

### Shape

`#ContractInventory` gains two fields and a rewritten `routable`; the `defined` and `definedBy` doc comments are scoped to single-definer keys. Every doc comment stays at six lines or fewer (`task docs:check`), and no doc comment cites an enhancement.

```cue
	// Every contract exactly one enabled entry's catalog lists, keyed by
	// contract FQN and carrying the member value as the catalog lists it
	// (the primitive itself, provenance stamped). A key two enabled
	// entries list is in collisions instead.
	defined: [#ContractFQNType]: #Resource | #Trait | #Blueprint

	// Contract FQN to the registry key (module path) of the one catalog
	// listing it: the value every diagnostic prints beside the contract.
	// Colliding keys are absent.
	definedBy: [#ContractFQNType]: #ModulePathType

	// ...requiredBy, unfulfilled, providedBy, overSubscribed unchanged...

	// Contract keys more than one enabled entry's catalog lists, sorted.
	// Such a key is in none of defined, definedBy, requiredBy, unfulfilled
	// or comparable, so fulfilled and discriminated can read true while it
	// is listed; routable reads false. See SPEC.md § 3.4.
	collisions: [...#ContractFQNType]

	// Each collisions key to the sorted registry keys (path@vN) of the
	// enabled entries listing it. Holds colliding keys only.
	collidingEntries: [#ContractFQNType]: [...#ModulePathType]

	// ...comparable, fulfilled unchanged...

	// True exactly when nothing is over-subscribed and no contract key
	// collides. The gate the generation step (operator, CLI) reads; `core`
	// itself refuses nothing on it.
	routable: bool & (len(overSubscribed) == 0 && len(collisions) == 0)
```

The two new fields sit directly after `overSubscribed`. `#ContractInventory` stays closed, gains no default and no required field; both fields are derived where used, like every other inventory field, so an authored `#contracts` still conflicts at the first key. The `#ContractInventory` type doc comment adds "the keys more than one catalog lists" to its list of contents without moving its first line.

### Comments moving with the code

- The `#Platform` WHY block above `#contracts` (lines ~181-187) gains one paragraph, the only place 0026 is cited:

```cue
	// WHY a key two enabled entries list is a collision, not a conflict:
	// folding it made two majors of one catalog sharing keys a bottom on
	// metadata.catalogVersion, so no report could name them (0026:OQ17,
	// measured in enhancements/0026/experiments/01-one-major-per-build and
	// 06-collision-tolerant-fold). Only single-definer keys fold; the rest
	// report with routable false, an interim net until 0026:D9.
```

  and its closing SPEC pointer adds "Why a shared key is a collision and not a conflict".
- The `#contracts` doc comment (lines ~211-216): "An over-subscribed platform still evaluates" becomes "An over-subscribed or colliding platform still evaluates", within six lines.

### SPEC.md, the twelve sites

1. §2.1 `#Resource` Constraints, the count bullet ("That count is computed once, by `#Platform.#contracts`"): `routable` also carries `collisions`, so a platform on which two enabled entries list one contract key is not routable either.
2. §3.4 Definition (the `#contracts` paragraph): name `collisions` and `collidingEntries` among the reports (the keys more than one enabled entry lists, and those entries).
3. §3.4 Shape block: the `#contracts` fold carries `_definers`, the guarded `defined`/`definedBy`, `collisions` and `collidingEntries`, as in § The fold.
4. §3.4 Constraints, the `#registry` keys bullet: two majors MAY be admitted, but keys both list are collisions and the platform is not routable.
5. §3.4 Constraints, the `defined`/`definedBy` bullet: both cover only keys exactly one enabled entry lists.
6. §3.4 Constraints, new bullet: a platform whose enabled entries list the same contract key MUST still evaluate, the key reported in `collisions` with its definers in `collidingEntries`; a disabled entry never counts.
7. §3.4 Constraints, the empty-registry bullet: add empty `collisions` and `collidingEntries`.
8. §3.4 Rationale, new bullet "Why a shared key is a collision and not a conflict": cites experiments 01 and 06, the interim status until 0026:D9, and the limitation.
9. §3.4 Rationale, amend "Why the inventory reports and does not refuse": a colliding key is one more report, and before this fold it was the one case the rule did not hold.
10. §3.4 Rationale, amend "Why one entry names one build": the registry admits one build per major, and two majors sharing keys are reported as collisions, not refused by map semantics.
11. §3.4 `#ContractInventory` Definition, Shape and Constraints: Definition adds which keys more than one entry lists; Shape adds the two fields and the new `routable` expression; Constraints scope `defined`/`definedBy` to single-definer keys, add MUSTs for `collisions` (sorted, exactly the keys with two or more enabled definers) and `collidingEntries` (exactly those keys, sorted registry keys), and redefine `routable` as no over-subscription AND no collision.
12. §3.4 `#ContractInventory` Rationale: a limitation bullet, "Why a colliding key reads as fulfilled and discriminated": `requiredBy`, `unfulfilled` and `comparable` are blind to colliding keys, so `fulfilled` and `discriminated` can read true while `routable` is false; consumers treat a non-empty `collisions` as overriding both; the report names the colliding keys and entries, not which transformers demand them.

### Pins

In `src/platform_contracts_pins.cue`. `_pinInventoryReadout` is untouched, so every existing readout literal stays byte-identical. New fixtures:

- `_pinInventoryVolume`: a resource `opmodel.dev/catalogs/opm/resources/volume@v1beta1` only the second major lists.
- `_pinInventoryDeploymentV2` and `_pinInventoryDeploymentV3`: `deployment@2.0.0` and `deployment@3.0.0`, each requiring the container alone (equal predicates with `deployment@1.0.0`).
- `_pinInventoryBaseV2Catalog`: `opmodel.dev/catalogs/opm@v2` at `2.0.0`, listing the base catalog's four keys plus `volume`, shipping `deployment@2.0.0`.
- `_pinInventoryBaseV3Catalog`: `opmodel.dev/catalogs/opm@v3` at `3.0.0`, listing container and backup, shipping `deployment@3.0.0`.

New platforms: `_pinInventoryCollide` (opm v1 and v2), `_pinInventoryCollideDisabled` (v2 with `enable: false`), `_pinInventoryCollideOverSubscribed` (v1, v2, the bare k8up v2 and velero), `_pinInventoryCollideThreeMajors` (v1, v2, v3).

New helper, beside `_pinInventoryReadout`:

```cue
_pinInventoryCollisionReadout: {
	#in: #ContractInventory
	out: "collisions=[\(strings.Join(#in.collisions, ","))] collidingEntries=[\(strings.Join([for k in #in.collisions {"\(k)=\(strings.Join(#in.collidingEntries[k], "+"))"}], ";"))] entries=\(len(#in.collidingEntries)) routable=\(#in.routable)"
}
```

It joins `collisions` without re-sorting, so the pin also holds the list's own order, and `entries` holds that `collidingEntries` carries colliding keys only.

Expected values, measured 2026-09-30 on cue v0.17.1 against the patched fold (keys shortened here to `opm/...` for `opmodel.dev/catalogs/opm/...`; the pins carry them in full):

| Pin | Value |
| --- | --- |
| Collide, existing fields (the red pin) | `routable=false composed=2` |
| Collide, `_pinInventoryReadout` | `defined=1 unfulfilled=[] overSubscribed=[] fulfilled=true routable=false comparable=0 discriminated=true` |
| Collide, collision readout | collisions = blueprints/stateless-workload, resources/container, traits/backup, traits/scaling (in that order), each entry `opm@v1+opm@v2`, `entries=4 routable=false` |
| Collide, second-major-only key | `len(definedBy)`, `definedBy[volume]`, `len(requiredBy[volume])` = `1|opmodel.dev/catalogs/opm@v2|0` |
| Collide, LIMITATION | `requiredBy[container] == _|_`, `requiredBy[backup] == _|_`, `fulfilled`, `discriminated`, `routable` = `true|true|true|true|false` |
| CollideDisabled | `_pinInventoryReadout` equals `_pinInventoryBaseOnlyReadout`; collision readout `collisions=[] collidingEntries=[] entries=0 routable=true`; `definedBy[volume] == _|_` is `true` |
| CollideOverSubscribed | readout `defined=1 unfulfilled=[] overSubscribed=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] fulfilled=true routable=false comparable=0 discriminated=true`; collision readout as Collide; `providedBy[backup]` = `opmodel.dev/catalogs/k8up@v2,opmodel.dev/catalogs/velero@v1`; composed 4 |
| CollideThreeMajors | container and backup collide across `opm@v1+opm@v2+opm@v3`, stateless-workload and scaling across `opm@v1+opm@v2`, `entries=4 routable=false`; `definedBy[volume]` = `opmodel.dev/catalogs/opm@v2`; composed 3 |
| Empty and Bare | collision readout `collisions=[] collidingEntries=[] entries=0 routable=true` |

The Collide limitation readout is the contrast the SPEC bullet cites: `_pinInventoryBaseOnlyReadout`, the one-major equivalent, already pins `fulfilled=false` with `backup` unfulfilled, while Collide reads `fulfilled=true`; and Collide pairs `deployment@1.0.0` with `deployment@2.0.0` at equal predicates over the container, yet reads `discriminated=true`. The limitation pins carry a `LIMITATION PIN` comment stating that a future fix of the limitation changes them deliberately. There are no MUST-FAIL cases: the property is that the platform evaluates.

The fixture comment above `_pinInventoryK8upV2BareCatalog` (lines ~182-186) says "listing nothing keeps two majors from conflicting in `defined`": a workaround for the bug this change fixes. It becomes: listing nothing keeps the two majors out of `collisions`, so the readout isolates the provider count. The file header's fixture paragraph and the "The nine platforms" heading are updated for the new fixtures and platforms.

## Research & Decisions

### Adopt experiment 06's fold as measured

**Context**: OQ17 recommends a core fix; experiment 06 measured one against a copy of this repo's `src/` at `cbe93e0`.
**Explored**: enhancements `0026/experiments/06-collision-tolerant-fold` (probe and toy model, Concluded), `01-one-major-per-build` case A (the failure), `07-render-shipped-core` (duplicate objects under shared keys). For this design, the patch was re-applied to this worktree's `src/` in the session scratchpad (`collisions/proto`), the full pin suite vetted clean, and the § Pins fixtures were exported for their values.
**Decision**: Apply the patch's logic verbatim, with experiment 06's field names.
**Rationale**: It is measured, it is minimal (two guarded comprehensions and two new derived fields), and a one-major platform is provably unchanged: with every key at one definer, each guard is true and the comprehensions are the old ones. `collidingEntries` keeps its measured name: it holds only colliding keys, so a `providedBy`-style name such as `definedByAll` would misdescribe it.

### Report the collision; do not key requiredBy or comparable over it

**Context**: A colliding key leaves `defined`, so it also leaves `requiredBy`, `unfulfilled` and `comparable`, and `fulfilled`/`discriminated` can read true on a platform that is not routable.
**Explored**: Keying `requiredBy` and `comparable` over `_definers` instead of `defined`.
**Decision**: Deferred. State the limitation in SPEC and pin it.
**Rationale**: The colliding members can disagree across majors (fulfilment, `appliesTo`, schema), so folding them would need a divergence rule, which is design work 0026 D9 owns. `routable: false` already withholds generation, and change B refuses the render on the collision itself, so no consumer acts on the blind fields while `collisions` is non-empty.

### Release class: feat, not feat!

**Context**: `routable`'s published invariant changes shape.
**Decision**: `feat(platform):`, one commit, no `!`.
**Rationale**: Principle I's test is "validated yesterday, fails today"; here every input that evaluated yesterday reads the same values today (the pin suite passes unchanged), and only inputs that were bottom change. `AGENTS.md` classes a new field on a published definition as `feat`. In prerelease mode `feat` and `feat!` both advance the alpha counter (expected `v2.0.0-alpha.13`), so a `!` would only mark the changelog. The proposal's Impact states the redefined invariant and the old-kernel hazard so consumers see it anyway.

### Red first on existing fields only

**Context**: A pin on `collisions` fails on today's core as "field not allowed", which proves nothing about the bug.
**Decision**: Write `_pinInventoryCollideIntact` (`routable` and `len(#composedTransformers)`) first and watch `task vet` fail; add the pins on the new fields after the fold.
**Rationale**: Measured on this worktree's unpatched `src/`: the pin fails with the `metadata.catalogVersion` and `definedBy` conflicts for all four shared keys, which is the bug itself.

### One section

**Context**: Principle VI allows several sections, but the fold, its SPEC section (Principle II) and the pins that make it checkable cannot land apart without leaving `main` asserting nothing, and a red pin cannot be committed alone.
**Decision**: One section, one `feat(platform):` commit carrying pins, fold, SPEC, docs page, spec Purpose and INDEX.

### The Over-subscription requirement is modified too

**Context**: The approved design lists three MODIFIED requirements. The live requirement "Over-subscription counts providing registry entries, not transformers" also states "`routable` MUST be true exactly when `overSubscribed` is empty", which the fold makes false.
**Decision**: MODIFY that requirement too, changing only that sentence and keeping all four scenario headings and bodies verbatim.
**Rationale**: Leaving it would archive a main spec that contradicts the ADDED requirement. It is a spec-text correction, not a design change; reported as a deviation.

## Risks / Trade-offs

- [An old kernel renders a colliding platform pinned to this core] → Core cannot prevent it: the library gate before change B never reads `routable`, and both majors' transformers match every component under the shared keys (duplicate objects when a bridge transformer is present, measured on library `30f08c1`). Mitigations are in `orchestration.md`: B ships right after this release, B moves `DefaultSchemaModule` so generated platforms never pin this core before a refusing kernel exists, and the workspace `task deps:update` waits for B's release.
- [Consumers read `fulfilled` or `discriminated` as safe on a colliding platform] → Stated in SPEC and pinned; `routable` is false on every such platform, and B, C and D all put collisions first.
- [The redefined `routable` surprises a consumer that derives its message from `overSubscribed`] → The operator today prints "0 over-subscribed contracts" on a collision-only inventory, and the cli check would read vacuously routable; C and D fix both. Until then those platforms were bottom anyway, so no consumer regresses.
- [The release number is assumed to be `2.0.0-alpha.13`] → The worker does not tag; the supervisor reads the release-please tag and hands it to B, C and D.
- [Evaluation cost] → One extra pass over the enabled entries' contract maps; measured `cue vet ./...` on the patched `src/` at 0.26s wall against 0.20s unpatched, both within noise of the usual range.

## Migration Plan

Merge, then the supervisor merges the release-please PR, which publishes the module to GHCR. Rollback is a revert commit plus a new alpha; no consumer pins this release until change B does. The downstream sequence (library refusal and `DefaultSchemaModule`, then the workspace `task deps:update`, then operator and cli) is in `orchestration.md`.
