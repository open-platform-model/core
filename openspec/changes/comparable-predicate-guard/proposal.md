## Why

Two enabled catalogs can each ship a transformer over the same catalog-fulfilled contract with predicates that are not discriminated from one another — the accidental case being two catalogs that both carry a daemonset adapter. Today nothing notices: the component matches both, renders twice, and no report names either transformer. Enhancement `0015` D5 decided this is refused, not arbitrated, and that the refusal names the bucket and both transformer FQNs. `core` owns the derivation half of that: the inventory reports, the generation step refuses (0015 D18, already the shape of `overSubscribed`/`routable`).

Implements `enhancements/0015` D5, and resolves OQ9 ("what *comparable* means operationally"), which D5 deferred to this slice.

## What Changes

- **`#ContractInventory` gains `comparable`**: the list of transformer pairs whose match predicates are comparable — one's demand set a subset of the other's — and which share at least one **catalog-fulfilled** contract. Each row names both implementation FQNs and the shared contracts, so a diagnostic can print all three facts D5 requires.
- **`#ContractInventory` gains `discriminated: bool`**: true exactly when `comparable` is empty. The third report boolean, beside `fulfilled` and `routable`, and the one a generation step refuses on.
- **No new top-level construct.** The row shape is declared inline on `comparable`, so `.tasks/spec-tracked.txt` is unchanged and nothing new joins the published definition surface (Principle V; see `design.md` § The row is an inline struct).
- **The predicate is all three demand kinds together** — `requiredResources`, `requiredTraits` and `requiredLabels` (key *and* value) folded into one canonical token set. Comparing `requiredLabels` alone, which `src/platform.cue`'s existing WHY block implies is the discriminating property, produces a **false refusal against the shipped catalog**: `hpa-transformer` declares no `requiredLabels` and `deployment-transformer` declares `workload-type: stateless`, so on labels alone HPA's predicate is a subset of Deployment's. Their `requiredTraits` is what actually separates them (HPA requires `#ScalingTrait`; Deployment requires no trait). Measured against `catalog_opm` `opm` at 4.4.0.
- **Scope is catalog-fulfilled contracts only.** Provider-fulfilled buckets keep their existing guard (`overSubscribed`, one catalog per contract) and are excluded here, because one provider catalog is explicitly allowed to carry two adapters over one contract (`src/platform.cue`: k8up's Schedule and PreBackupPod). Running the comparability test over provider buckets would refuse that shipped-by-design topology.
- **No refusal in `core`.** The inventory still reports and never refuses (0015 D18): an ambiguous platform evaluates, with the pairs named.
- `SPEC.md` § 3.4 co-updates in the same commit, and `src/INDEX.md` regenerates.

Not in this change: the refusal itself, which needs two follow-up changes. `library` decodes the two fields onto `platform.ContractInventory` (`opm/platform/contracts.go`, whose decode reads the inventory field-by-field and whose doc comment says "the six data fields"), and then `cli`'s `opm platform check` refuses on `discriminated` where it already refuses on `routable` (`cli/internal/platform/check.go`). Note that `library`'s render gate (`gateErrors`, beside `OverSubscribedContractsError`) is a **different** path: it reads render-time `RenderDiagnostics`, not the platform inventory, and is not this guard's site. Also not in this change: a parity check that the shipped `catalog_opm` catalog stays discriminated — `core` cannot import a catalog, so that pin belongs to `library`'s parity harness.

## Capabilities

### New Capabilities

None. The behaviour extends an existing capability.

### Modified Capabilities

- `platform-contract-inventory`: adds the comparable-predicate report and its boolean to what a `#Platform` derives, defines what "comparable" means operationally (subset over the canonical predicate token set), and fixes the scope to catalog-fulfilled contracts.

## Impact

**Release classification: MINOR (`feat:`).** Purely additive — two derived fields on a definition that is derived and never authored, plus one new definition. No published constraint tightens, nothing is removed, and no consumer that validates today stops validating. This does **not** rely on `@v2` still being in prerelease (Principle IV).

Justification against Principle V: the fields have a named consumer before they ship — `library`'s render gate, which already refuses on `routable` and gains the same treatment for `discriminated`. This is not speculative surface.

Downstream:

| Consumer | What it has to do |
| --- | --- |
| `library` | Pick up the core pin, then a follow-up change decodes `comparable` and `discriminated` onto `platform.ContractInventory`. Its parity harness gains a pin that the shipped catalog stays discriminated. |
| `cli` | After the `library` bump, `opm platform check` reports the pairs and refuses on `discriminated`, beside its existing `routable` refusal. |
| `opm-operator` | Nothing in this change, but it is where D5's stated guard site is (platform-package generation) and it consults the contract inventory **nowhere** today — it does not refuse on `routable` either. Closing that is a pre-existing gap against 0015 D18 and 0010 D37, not one this change opens. |
| `catalog_opm` | Nothing to change — measured clean today. It acquires an obligation: a new transformer must be discriminated from every existing transformer sharing one of its contracts, by a differing required label value or a distinct required trait or resource. |
| `modules`, `opm-modules` | Nothing. Modules author no transformers. |

Evaluation cost: the derivation is pairwise within each catalog-fulfilled bucket. The shipped catalog's largest bucket is 8 transformers (`#ContainerResource`), so 28 pairs; cost is measured in the implementation section rather than assumed.
