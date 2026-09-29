## Context

See `proposal.md` (Why) for the two bugs. The state this design starts from, in `src/platform.cue` at `origin/main` (4c68be0, core v2.0.0-alpha.11 plus docs):

```cue
		// Per provider-fulfilled contract, the set of catalogs whose
		// transformers require it (keyed by stamped modulePath; ...).
		_providers: {
			for fqn, c in defined if c.kind != "Blueprint" if c.fulfilment == "provider" {
				(fqn): {for _, k in requiredBy[fqn] {(#composedTransformers[k].metadata.modulePath): true}}
			}
		}
		unfulfilled: [for fqn, ps in _providers if len(ps) == 0 {fqn}]
		overSubscribed: [for fqn, ps in _providers if len(ps) > 1 {fqn}]
```

Two properties of that fold cause both bugs:

1. It iterates `defined`, so a contract that no enabled entry defines is never counted (Bug 2).
2. It keys a provider by the transformer's stamped `metadata.modulePath`. `#Catalog` stamps that as `"\(registryPath)/transformers"` (`src/catalog.cue:162`), which carries no major, so `k8up@v2` and `k8up@v3` collapse to one key (Bug 1).

The library render build (`library/opm/internal/renderstage/render.cue.tmpl`, `guard._providerSuppliers`) iterates `#registry` per entry, reads `req.fulfilment` off each transformer's own requirement, and keys by the registry key `rkey`. It refuses every render when its count exceeds one. `opm-operator` and `opm platform check` gate on the inventory's `routable`. So on both bug shapes the generation step accepts a platform on which every render is then refused.

Files touched: `src/platform.cue`, `src/platform_contracts_pins.cue`, `src/INDEX.md` (regenerated), `SPEC.md`, `docs/site/concepts/platforms-and-catalogs.md`. Constructs in `.tasks/spec-tracked.txt` whose `SPEC.md` sections move: `#Platform` and `#ContractInventory` (§3.4). `#Resource` (§2.1) and `#Trait` (§2.2) move only in prose describing where the count lives; their CUE is unchanged. No construct is newly tracked; `providedBy` is a field of the already-tracked `#ContractInventory`.

## Goals / Non-Goals

**Goals:**

- One provider count, computed once in `core` as `#Platform.#contracts.providedBy`, that the library render build can read verbatim in change B instead of its own guard.
- The inventory's `overSubscribed`, `routable`, `unfulfilled` and `fulfilled` derived from that count.
- Pins that are red on today's core for both bug shapes and green after the fix.

**Non-Goals:**

- Any change to `definedBy`, `requiredBy`, `comparable` or `discriminated`.
- The pre-existing conflict when two majors of a contract's DEFINING catalog are both enabled: `defined` and `definedBy` conflict (catalogVersion `"1.0.0"` vs `"2.0.0"`; `path@v1` vs `path@v2`). Measured, out of scope, reported as a follow-up core issue.
- Library, operator and cli edits. They are changes B, C and D in `orchestration.md`.

## Decisions

### The counting rule

ONE rule, computed once in core as `#Platform.#contracts.providedBy` and read by everything else.

1. **Which transformers count:** every transformer of every ENABLED registry entry, iterated per entry (`for rkey, entry in #registry if entry.enable for _, tf in entry.#transformers`). Iterating per entry keeps the key visible; iterating `#composedTransformers` would lose it. Only REQUIRED demands count (`requiredResources`, `requiredTraits`, each presence-guarded). Optional demands and `requiredLabels` never count.
2. **Where fulfilment is read:** from the transformer's own requirement value (`req.fulfilment == "provider"`; the default resolves to `"catalog"`). It is never read from the defining catalog's member, and counting never depends on whether an enabled entry defines the contract.
3. **The key:** the registry key `rkey`, which is the catalog module path WITH its major (`path@vN`). Core binds it to `#catalog.metadata.modulePath` (`platform.cue:157`). The key is never the transformer's stamped `metadata.modulePath`, which has no major (`"<registryPath>/transformers"`, `catalog.cue:162`). Consequences: two adapters in one entry count as ONE provider (k8up Schedule plus PreBackupPod); two majors of one catalog count as TWO (`k8up@v2` plus `k8up@v3`); two entries count as two whether or not any enabled entry defines the contract.
4. `providedBy: [#ContractFQNType]: [...#ModulePathType]`. For each such contract FQN it holds the ascending-sorted list of those registry keys. A key is present exactly when there is at least one provider. It is built from a hidden set `_providerSet: {(fqn): (rkey): true}`, then `list.Sort` per key.
5. `overSubscribed: [for fqn, ps in providedBy if len(ps) > 1 {fqn}]`. This includes contracts that no enabled entry defines.
6. `unfulfilled: [for fqn, c in defined if c.kind != "Blueprint" if c.fulfilment == "provider" if providedBy[fqn] == _|_ {fqn}]`. It covers defined provider contracts with zero providers. A contract that no enabled catalog defines is NEVER unfulfilled. Nothing on the platform declares it; if an enabled transformer requires it as a provider it is provided, and it may be over-subscribed. A component demand for a key nobody defines or provides is the render's unresolved or unprovided row, not an inventory fact.
7. `routable: len(overSubscribed) == 0` and `fulfilled: len(unfulfilled) == 0`. Both are unchanged in form, and so are `definedBy`, `requiredBy` (defined keys only), `comparable` and `discriminated`.
8. The render reads the same values (change B, library):
   - `match.#providers = platform.#contracts.providedBy` (the skip switch's `unprovided` test is presence only);
   - the over-subscription rows are `{key, catalogs: providedBy[key]}` for every key in `overSubscribed`;
   - `gate: match.resolved & platform.#contracts.routable`.

### Shape

`#ContractInventory` gains one field; the doc comments on `unfulfilled` and `overSubscribed` are rewritten. Every doc comment stays at six lines or fewer (`task docs:check`); references go in `// WHY` blocks.

```cue
	// WHY unfulfilled: 0015:D18.

	// Defined provider-fulfilled resources and traits with no providedBy
	// key. A report the operator surfaces as a non-gating condition; never
	// a refusal. Blueprints never appear, nor does a contract no enabled
	// catalog defines.
	unfulfilled: [...#ContractFQNType]

	// WHY providedBy: 0010:D37, 0015:D2/D18. It is the one provider count:
	// the render build reads it instead of keeping its own, so the refusal
	// and the generation gate cannot disagree. Keyed by registry key, major
	// included, because the stamped transformer modulePath is major-free.

	// Provider-fulfilled contract FQN to the sorted registry keys (path@vN)
	// of the enabled entries whose transformers require it, whether or not
	// an enabled entry defines it. Present exactly when some entry provides
	// it. See SPEC.md § 3.4.
	providedBy: [#ContractFQNType]: [...#ModulePathType]

	// WHY overSubscribed: 0010:D37.

	// Keys of providedBy with more than one registry entry, including a
	// contract no enabled entry defines. Two majors of one catalog are two
	// providers; two adapters in one entry are one. What the generation
	// step and the render build refuse on.
	overSubscribed: [...#ContractFQNType]
```

`#ContractInventory` stays closed, gains no default and no required field. `providedBy` is derived where it is used, like every other inventory field, so an authored `#contracts` conflicts at the first key exactly as today.

### Derivation

Inside `#Platform.#contracts`, replacing `_providers` and the two list comprehensions:

```cue
		// Per provider-fulfilled contract some enabled transformer requires,
		// the set of registry keys whose transformers require it. Iterated
		// per entry, not over #composedTransformers, so the key stays
		// visible; the demand maps are presence-guarded as for requiredBy.
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
		unfulfilled: [for fqn, c in defined if c.kind != "Blueprint" if c.fulfilment == "provider" if providedBy[fqn] == _|_ {fqn}]
		overSubscribed: [for fqn, ps in providedBy if len(ps) > 1 {fqn}]
```

`list` is already imported by `platform.cue` (the comparability report uses it). This is exactly the scratch prototype's diff against `origin/main`.

### Comments moving with the code

- `#ContractInventory` field comments, per § Shape. The old `overSubscribed` text ("a transformer's catalog being its stamped metadata.modulePath") goes.
- The `#Platform` WHY block above `#contracts`: the paragraph "WHY over-subscription counts catalogs, not transformers" becomes:

```cue
	// WHY over-subscription counts registry entries, not transformers: one
	// provider catalog may carry two adapters over one contract (k8up's
	// Schedule and PreBackupPod), so counting transformers refuses its own
	// shape. The key is the registry key, major included: the stamped
	// transformer metadata.modulePath is major-free, so it cannot tell
	// k8up@v2 from k8up@v3, and the render build counts them as two.
	// Fulfilment is read off each transformer's own requirement, so
	// providers of a contract no enabled entry defines are counted too.
```

  and its closing SPEC pointer names "Why over-subscription counts registry entries".
- The `#contracts` doc comment: "crossed with the required demands of #composedTransformers" becomes "crossed with the required demands of the enabled entries' transformers", keeping six lines or fewer.

### SPEC.md

- §2.1 `#Resource` Constraints, the two `fulfilment: "provider"` bullets (lines 115-116): the count is of registry entries (path with major), not catalogs; `#Platform.#contracts` computes it once as `providedBy`, `overSubscribed` and `routable`, and the render build and generation step refuse on that count. Delete the documented divergence and "The render refuses on the render build's count, not the inventory's." The skip clause reads "only a contract with no `providedBy` key makes a demand skippable".
- §2.2 `#Trait` Constraints (line 213): "whose provider count the kernel's render build enforces" becomes "whose provider count `#Platform.#contracts` computes and the render build enforces".
- §3.4 `#Platform`: the Definition paragraph (line 577) names `providedBy` among the arity reports; the Shape block (lines 623-657) carries the derivation above in place of `_providers`; Constraints gain a fold-specific `providedBy` bullet (drawn from every enabled entry's `#transformers`, keyed by registry key, independent of `defined`) and the empty-registry bullet adds `providedBy`; the Rationale bullet "Why over-subscription counts catalogs" (line 740) becomes "Why over-subscription counts registry entries": two adapters in one entry are one provider, two majors are two, fulfilment is read off the transformer, the sentence "two builds of one catalog are already inexpressible (one entry per path)" is deleted as false across majors, and the render build reads this count rather than keeping one.
- §3.4 `#ContractInventory`: Definition adds "which registry entries provide each"; Shape adds `providedBy`; Constraints (lines 794-795) restate `unfulfilled` (defined, provider-fulfilled, no `providedBy` key; an undefined contract never appears) and `overSubscribed` (keys of `providedBy` with more than one entry, undefined contracts included) and add a MUST for `providedBy`; the Rationale bullet on comparability scope (line 809, "by counting catalogs") says "by counting registry entries".

## Research & Decisions

### Count per registry key, not per stamped transformer path

**Context**: Two keys were available: the transformer's stamped `metadata.modulePath` (unforgeable per 0010:D25 but major-free) and the registry key (major included).
**Explored**: Scratch prototype `design/core/src/platform.cue` with `zz_parity_pins.cue`, cue v0.17.1, under the session scratchpad `parity/`. A verbatim replica of the library guard (`render.cue.tmpl:445-466`) was evaluated against the prototype inventory and against today's core (`design/core-orig`).
**Decision**: The registry key.
**Rationale**: It is what the render build already refuses on, so parity holds by construction once the render reads core's value. The prototype's key sets equal the guard's on 7 platforms (two-majors, definer-disabled, definer-absent, TwoProviders, OneProvider, BaseOnly, DisabledProvider). Today's core diverges on exactly the three bad platforms (inventory `routable=true`, guard refuses); the controls agree. Every existing core pin passes unchanged on the prototype (`cue vet ./...` OK).

### Read fulfilment off the transformer's requirement

**Context**: Today fulfilment is read from `defined[fqn]`, the defining catalog's member, which is absent when the definer is disabled or not on the platform.
**Decision**: Read `req.fulfilment` from the transformer's own requirement value.
**Rationale**: The requirement is the contract value the transformer compiled against, carried on every enabled transformer, so the count needs no definer. The divergent case (a definer member saying `"provider"` while a transformer's copy says `"catalog"`) is only reachable with two majors of the DEFINING catalog enabled, and measured, that already makes `defined` and `definedBy` conflict, so no evaluable platform can make `unfulfilled` and `providedBy` disagree.

### A contract no enabled catalog defines is never unfulfilled

**Context**: `providedBy` now reaches contracts outside `defined`; `unfulfilled` could follow.
**Decision**: `unfulfilled` stays scoped to `defined`.
**Rationale**: With zero providers and no definer, nothing on the platform mentions the contract, so the inventory has nothing to report; a component demanding it is the render's unresolved or unprovided row. With one or more providers it is provided (and possibly over-subscribed), not unfulfilled.

### Expose the count rather than keep it hidden

**Context**: `_providers` was hidden, so every consumer that needed the providing catalogs (library guard rows, operator acceptance, cli report) recomputed them.
**Decision**: Export `providedBy` as a sorted list per contract.
**Rationale**: The render rows, the operator's refusal ("provided by ...") and the cli report all print the providing registry keys; with the list in core, each reads it and none counts. A sorted list rather than a set so it decodes to Go `[]string` and prints deterministically. Principle V is met: three named consumers.

### Pins written first, red on today's core

**Context**: The parity bug hid because nothing pinned the two shapes.
**Decision**: New platforms in `src/platform_contracts_pins.cue` use provider transformers that require ONLY the provider contract, so comparability cannot confound the readout:
- `_pinInventoryTwoMajors`: base `opm@v1`, plus `k8up@v2` (pre-backup-pod@2.0.0 only), plus `k8up@v3` (pre-backup-pod@3.0.0 only).
- `_pinInventoryDefinerDisabled`: base present with `enable: false`, plus `k8up@v2`, plus `velero@v1`.
- `_pinInventoryDefinerAbsent`: `k8up@v2` plus `velero@v1`, with no base entry.

Expected readouts (measured on the prototype):
- TwoMajors: `"defined=4 unfulfilled=[] overSubscribed=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] fulfilled=true routable=false comparable=0 discriminated=true"`
- DefinerDisabled and DefinerAbsent: `"defined=0 unfulfilled=[] overSubscribed=[opmodel.dev/catalogs/opm/traits/backup@v1alpha1] fulfilled=true routable=false comparable=0 discriminated=true"`

`providedBy` pins:
- TwoMajors: backup to `[k8up@v2, k8up@v3]`.
- DefinerDisabled: backup to `[k8up@v2, velero@v1]`; `definedBy` and `requiredBy` are both `{}`.
- OneProvider: backup to `[k8up@v2]` (two adapters, one key).
- TwoProviders: backup to `[k8up@v2, velero@v1]`.
- BaseOnly and bare `#Platform`: `{}`.

**Rationale**: On today's core the three readouts read `routable=true` (measured), so `task vet` fails before the `platform.cue` edit. The `providedBy` pins cannot be red on today's core in a useful way (the closed `#ContractInventory` has no such field, so they fail as "field not allowed"), so they are added with the field. Nothing red is committed: pins and fix land in one section.

### One section

**Context**: Principle VI allows several sections, but the schema edit, its `SPEC.md` section (Principle II) and the pins that make it checkable cannot be separated without leaving `main` asserting nothing, and a red-first pin cannot be committed alone.
**Decision**: One section, one commit, `feat(platform)!:` with a `BREAKING CHANGE:` footer. The docs page lands in the same commit because its comment cites the renamed `SPEC.md` rationale bullet.

## Risks / Trade-offs

- [Consumers accepting a Bug 1 or Bug 2 platform now refuse at generation] → Every render on those platforms is already refused by the library render build, so nothing that works stops working; the refusal moves earlier and names the registry keys. State it in the `BREAKING CHANGE:` footer. The footer writes path majors glued (`opmodel.dev/catalogs/k8up@v2`), never a bare at-sign.
- [Library consumers still on alpha.10 or alpha.11 keep the divergent guard until change B ships] → B floors core at this release and deletes the guard; until then behaviour is today's. Ordering is in `orchestration.md`.
- [The release number is assumed to be `2.0.0-alpha.12`] → The worker does not tag; the supervisor reads the release-please tag after merge and hands the actual tag to B, C and D.
- [Evaluation cost] → The fold is one pass over the enabled entries' transformers' required maps, the same work `requiredBy` already does; it drops the `requiredBy` lookup `_providers` did. No measurement is planned beyond `task vet` wall time staying in its usual range.
- [Two majors of a DEFINING catalog still conflict in `defined`/`definedBy`] → Pre-existing and out of scope. `routable` does not read `defined`, so the render gate change B lands is unaffected. Filed as a follow-up.

## Migration Plan

Merge, then the supervisor merges the release-please PR, which publishes the module to GHCR. Rollback is a revert commit plus a new alpha; no consumer pins this release until change B does. The downstream sequence (library floor and re-pins, workspace `task deps:update`, operator and cli) is in `orchestration.md`.
