## Context

See `proposal.md` § Why. Three existing facts shape the approach:

- `#ContractInventory` already carries the split this change extends: `core` derives a report (`unfulfilled`, `overSubscribed`) and a boolean (`fulfilled`, `routable`); the generation step outside `core` decides what to refuse (0015 D18). The new report follows that shape exactly rather than inventing one.
- The demand maps `requiredResources`, `requiredTraits` and `requiredLabels` are all **optional** on `#ComponentTransformer` (`src/transformer.cue:78,86,93`), so every fold over them needs a presence guard. `requiredBy` already does this.
- `src/platform.cue` currently imports nothing. It gains `list` and `strings`, both already used by other schema files (`src/schemas.cue`).

## Goals / Non-Goals

**Goals**: derive the report; define "comparable" operationally (0015 OQ9); keep the platform value evaluable when it reports a pair.

**Non-Goals**: the refusal (a `library` change); arbitration or most-specific-wins (0015 D5 excludes it, and a successor entry may add it additively on top of this report); any check against the shipped `catalog_opm` catalog, which `core` cannot import.

## Research & Decisions

### What "comparable" means operationally (0015 OQ9)

**Context**: D5 says "one's required set a subset of the other's" without fixing which demands form the set. A differing required *label value* is the discriminator that first comes to mind, and it is what keeps the shipped 8-transformer `#ContainerResource` bucket legal in the five-workload half of that bucket. (Corrected during implementation: `src/platform.cue` carried no WHY block on this at all — it names labels nowhere — so the file gains one rather than having one rewritten.)

**Explored**: read every transformer in `catalog_opm/opm/transformers/` at `opm` 4.4.0 and tabulated the full `#ContainerResource` bucket.

| Transformer | requiredResources | requiredTraits | requiredLabels |
| --- | --- | --- | --- |
| `deployment` | Container | — | `workload-type: stateless` |
| `statefulset` | Container | — | `workload-type: stateful` |
| `daemonset` | Container | — | `workload-type: daemon` |
| `job` | Container | — | `workload-type: task` |
| `cronjob` | Container | — | `workload-type: scheduled-task` |
| `hpa` | Container | `#ScalingTrait` | — |
| `service` | Container | `#ExposeTrait` | — |
| `pdb` | Container | `#DisruptionBudgetTrait` | — |

**Decision**: the predicate is the union of all three demand kinds, as a canonical token set (`resource:<fqn>`, `trait:<fqn>`, `label:<key>=<value>`).

**Rationale**: on labels alone, `hpa` declares none and `deployment` declares one, so `hpa`'s label set is a strict subset of `deployment`'s and the guard would refuse the shipped catalog — a false refusal of a transformer that is *supposed* to fire alongside Deployment, because it produces a different kind. Its `requiredTraits` is what separates them. The same holds for `service` and `pdb`. With all three kinds folded in, every pair in the bucket is incomparable and the shipped catalog is clean. A WHY block recording this is added above `#Platform.#contracts` in the same commit.

### Testing subset without probing for absent fields

**Context**: a subset test needs "is every key of A present in B". The obvious spelling probes `B[k]` for a key that may not exist and leans on absent-field-is-bottom semantics.

**Explored**: a spike evaluating both shapes against synthetic transformers (cue v0.17.1).

**Decision**: test by union cardinality. Both predicates are structs of `true`, so `_union: {for k, v in _pa {(k): v}, for k, v in _pb {(k): v}}` never conflicts, and `A ⊆ B` is exactly `len(_union) == len(_pb)`.

**Rationale**: it needs no absent-field probing at all, and it yields both directions from one union, so the equal-predicate case falls out rather than needing a third test.

### The pair key is the sorted pair, not bucket position

**Context**: a pair of transformers sharing two catalog-fulfilled contracts is found twice, once per bucket, and must collapse to one row carrying both contracts.

**Explored**: the spike first keyed rows by `"\(a)|\(b)"` using the `i < j` position guard, then fed it a second bucket listing the same two transformers in the opposite order.

**Decision**: key by `strings.Join(list.Sort([a, b], list.Ascending), "|")`, and take `broader`/`narrower` from the subset test rather than from position.

**Rationale**: **measured** — with position-derived keys the reversed bucket produced a second row, `dup-b|dup-a` beside `dup-a|dup-b`, breaking the spec's "one row, not two". With the sorted key the two rows unify into one whose `contracts` struct holds both FQNs. In practice `requiredBy` lists are built by one comprehension over `#composedTransformers` and so should already agree on order, but the report must not depend on that.

**Not pinned, and cannot be** (verified during implementation): every `requiredBy` bucket is built by that one comprehension over `#composedTransformers`, so two buckets always list a pair in the same order and the disagreeing-order input the spike used is **unreachable through `#Platform`**. Replacing `list.Sort([a, b], list.Ascending)` with a bare `[a, b]` leaves `task vet` green. The sort is therefore correct defensive coding against a shape the derivation cannot produce, not a testable behaviour — a reader should not go looking for the missing fixture. Pinning it would take a hand-built `#ContractInventory` outside `#Platform`, which the pins file deliberately does not do.

### Scope: catalog-fulfilled contracts only

**Context**: D5 scopes the guard to catalog-fulfilled buckets. Whether to extend it to provider-fulfilled ones was worth checking rather than assuming.

**Decision**: catalog-fulfilled only, enforced by `if c.kind != "Blueprint" if c.fulfilment == "catalog"`.

**Rationale**: `src/platform.cue`'s own WHY block records that one provider catalog may carry two adapters over one contract, naming k8up's Schedule and PreBackupPod, and `overSubscribed` deliberately counts catalogs so that topology passes. Nothing guarantees those two adapters have incomparable predicates, so extending the test to provider buckets risks refusing a topology this schema explicitly permits. Blueprints are excluded by the same guard that already excludes them from `_providers`: a blueprint carries no `fulfilment` and reading the field would fail the platform.

### The row is an inline struct, not a new definition

**Context**: `comparable` rows carry three facts, where every existing report list carries one FQN.

**Decision**: declare the row shape inline in `#ContractInventory.comparable`. No new top-level construct, so `.tasks/spec-tracked.txt` is unchanged.

**Rationale**: Principle V — a named `#ComparablePredicates` would be published surface whose only consumer decodes JSON and never names the CUE definition. The shape is documented in `SPEC.md` § 3.4's existing `#ContractInventory` subsection, which is where a reader already looks.

## Decisions

### Shape

Added to `#ContractInventory` in `src/platform.cue`:

```cue
	// Pairs of enabled transformers whose match predicates are comparable
	// over at least one shared catalog-fulfilled contract: `broader`
	// matches every component `narrower` matches. Provider-fulfilled
	// contracts are `overSubscribed`'s business, not this list's.
	comparable: [...{
		broader:  #ImplFQNType
		narrower: #ImplFQNType
		contracts: [...#ContractFQNType]
	}]

	// True exactly when nothing is comparable. The second gate the
	// generation step (operator, CLI) reads; `core` itself refuses
	// nothing on it.
	discriminated: bool & (len(comparable) == 0)
```

### Derivation

Added inside `#Platform.#contracts`, after `_providers`:

```cue
	// Each enabled transformer's match predicate as a canonical token set.
	// All three demand kinds, not labels alone: a required trait is what
	// separates the shipped hpa and service transformers from deployment,
	// and on labels alone their empty label map would read as a subset.
	_predicates: {
		for fqn, tf in #composedTransformers {
			(fqn): {
				if tf.requiredResources != _|_ {for r, _ in tf.requiredResources {"resource:\(r)": true}}
				if tf.requiredTraits != _|_ {for t, _ in tf.requiredTraits {"trait:\(t)": true}}
				if tf.requiredLabels != _|_ {for k, v in tf.requiredLabels {"label:\(k)=\(v)": true}}
			}
		}
	}

	// Keyed by the SORTED pair, so a pair found in two buckets collapses to
	// one row carrying both contracts whatever order each bucket lists it
	// in (measured: position-derived keys double-report a reversed bucket).
	// Subset is tested by union cardinality, which needs no probing for
	// absent fields and yields both directions at once.
	_comparablePairs: {
		for cfqn, c in defined if c.kind != "Blueprint" if c.fulfilment == "catalog" {
			let _bucket = requiredBy[cfqn]
			for i, a in _bucket for j, b in _bucket if i < j {
				let _pa = _predicates[a]
				let _pb = _predicates[b]
				let _union = {for k, v in _pa {(k): v}, for k, v in _pb {(k): v}}
				let _aSubB = len(_union) == len(_pb)
				let _bSubA = len(_union) == len(_pa)
				if _aSubB || _bSubA {
					let _pair = list.Sort([a, b], list.Ascending)
					(strings.Join(_pair, "|")): {
						broader: [if _aSubB && _bSubA {_pair[0]}, if _aSubB {a}, b][0]
						narrower: [if _aSubB && _bSubA {_pair[1]}, if _aSubB {b}, a][0]
						contracts: (cfqn): true
					}
				}
			}
		}
	}
	comparable: [for _, r in _comparablePairs {{
		broader:  r.broader
		narrower: r.narrower
		contracts: [for c, _ in r.contracts {c}]
	}}]
```

`_aSubB` reads "A's predicate is contained in B's", which means A demands less and therefore matches more — so A is `broader`. When both hold the predicates are equal and the sorted pair decides the two field values arbitrarily but deterministically; the diagnostic names both either way.

### Files touched

| File | Change |
| --- | --- |
| `src/platform.cue` | the two fields, the two hidden derivations, `import ("list"; "strings")`, and a corrected WHY block on what discriminates a bucket |
| `src/platform_contracts_pins.cue` | pins for every scenario in the delta spec |
| `SPEC.md` § 3.4, `#### #ContractInventory` | shape, constraints and a Rationale entry — co-committed (Principle II) |
| `src/INDEX.md` | regenerated by `task generate:index` |

Tracked constructs whose SPEC.md section moves: `#ContractInventory` and `#Platform`, both already in `.tasks/spec-tracked.txt`. Nothing is newly tracked.

### Closedness, defaults and required fields

Unchanged. `#ContractInventory` gains two fields that are always derived, never authored; no existing field's type, default or optionality moves, and no definition's closedness changes. A consumer unifying against `#Platform` today keeps validating.

## Risks / Trade-offs

- **A future catalog pair is refused that the authors consider legitimate** → the report is additive and the refusal lives outside `core`; a successor entry can add arbitration on top of this report without changing it, exactly as D5 anticipated.
- **Evaluation cost is pairwise per bucket** → **measured, not material.** `cue vet ./...` from `src/`, three runs each, median reported (cue v0.17.1, 2026-09-16): **0.10 s** before the change; **0.11 s** with the derivation in place against the *pre-existing* fixtures, which isolates the fold's own cost at roughly +0.01 s, inside run-to-run noise; **0.16 s** on the final tree, where the extra ~0.05 s is the twelve new fixture catalogs and nine new platforms the pins add, not the pairwise fold. No narrowing was needed, so the fold stays as designed. Largest shipped bucket is 8 transformers (28 pairs). If a future catalog does regress it materially, the fold can still be narrowed to pairs that share a *required* contract before the predicate union runs.
- **`comparable`'s list order is comprehension order**, as `overSubscribed`'s already is → deterministic for a given input, and pinned; a consumer that needs a stable order sorts it itself.
- **The corrected WHY block contradicts what the file said before** → that is the point, and the pins make the correction checkable rather than asserted.

## Migration Plan

None. Additive fields on a derived value; no consumer action is required to keep working. `library` picks the pin up when its gate change lands.

## Open Questions

None material. Evaluation cost is measured during implementation, and a regression changes only the fold's shape, not the specs or the task breakdown.
