## Why

Three unrelated-looking defects in the platform and match surface share one root: `core` expresses *selection* and *matching* through structures that also carry other meanings, so a disagreement between two parties reads as a coincidence rather than an error.

**Selection floats.** `#Subscription` carries a `#SubscriptionFilter` with `range`, `allow`, `deny`, a prerelease flag and an empty-filter default that falls through to `highestStable(published)`. That default *is* a float: it moves on the next catalog release whether or not a constraint was written. Ranges without a lockfile is the one combination that cannot be made reproducible, and every ecosystem shipping ranges ships a lock beside them. OPM shipped ranges and recorded its resolution in an in-memory map whose only non-test consumer in the whole workspace was an integration harness, and whose own doc comment told callers they "MUST NOT branch behavior on it".

**Matching rides on `metadata.labels`.** A component's matching identity is unioned up from its primitives' `metadata.labels` — the same field that carries categorisation. Measured in `experiments/04`: a full union fails on `resource.opmodel.dev/category`, which takes `workload` on Container, `storage` on Volumes and `config` on ConfigMaps. Real `catalog_opm` fails at `#StatefulWorkload` before reaching a module at all. Every filtered union that was tried must *iterate*, and CUE refuses to iterate a struct holding an unset required field — so each filter design forced dropping `!` from the container's workload type, degrading "the author must pick" into an incomplete value.

**An unmet demand renders successfully.** `Match` records a `MissingFQN` for a demanded FQN with no bucket — and that field has no production consumer. It is populated, asserted in one integration test, and read nowhere else. A bucket that exists but disqualifies every candidate records nothing at all. So a component carrying `#Container` and `#Backup`, on a platform with no backup provider, matches the deployment transformer, is not `Unmatched`, renders successfully, and has no backup. Under enhancement `0010` D4's contract model that is not an edge case — it is the routine failure.

This change is the schema half of all three fixes.

## What Changes

**`#SubscriptionFilter` is deleted outright.** `#Subscription` carries a required scalar `version!: #VersionType` naming the single build that subscription materializes. No range to solve, no `allow`/`deny` to arbitrate, no highest-stable default, no maturity inference — a prerelease is selected by being written down. Catalog selection becomes a pure function of committed source: git-identical inputs materialize identical catalog bytes on any day, from any machine, with no lockfile, because the platform file *is* the resolution.

**Matching moves into `matchLabels`.** `#Resource`, `#Trait`, `#Blueprint` and `#Component` gain a dedicated `matchLabels`. A component's is the **wholesale unification** of its attached primitives' — no filter, no key list. `metadata.labels` is left alone and never unified upward. `#ComponentTransformer.requiredLabels` selects on `matchLabels`. Component fragments become pure wrappers that attach primitives and declare nothing of their own.

**`#LabelWorkloadType` is deleted from `core`.** The key it names is renamed `opm.opmodel.dev/workload-type` and owned by `catalog_opm`. The vocabulary becomes catalog-owned by construction rather than by a filter's cooperation.

**Contracts declare where fulfilment comes from.** `#Resource` and `#Trait` gain `fulfilment: *"catalog" | "provider"`. `"catalog"` is today's behaviour and the default, so nothing opts in by accident. `"provider"` means the declaring catalog ships no transformer deliberately, and a platform must carry **exactly one** transformer requiring that contract. `#Blueprint` does not get the field — a transformer can never demand a blueprint, so it would be unreachable.

**Demand-side optionality gets a spelling.** Every resource a component declares is required. Traits carry an explicit opt-out; an unhandled trait without one is an error, and only the opted-out case degrades to a warning.

## Capabilities

### New Capabilities

- `platform-subscription`: what a `#Platform` declares about the catalog builds it materializes — one build per subscription, named as a scalar, with no resolution step.
- `component-matching`: what a component and its primitives declare that a transformer selects on — `matchLabels`, its wholesale upward unification, its separation from categorisation, and its absence from rendered output.
- `contract-fulfilment`: where a contract's implementation is expected to come from, and the demand-side statement of what is required versus optional.

### Modified Capabilities

None. The three capabilities above are new surfaces. `primitive-keying` and `artifact-identity` are unchanged by this change.

## Impact

**Depends on `core-identity-shape`.** Shares the alpha with `core-primitive-keying` and `core-identity-package`; ordering between the three is not constrained beyond both depending on identity.

**Schema — this repo.** `src/platform.cue` (filter deleted, scalar `version`), `src/resource.cue`, `src/trait.cue`, `src/blueprint.cue`, `src/component.cue` (`matchLabels`; `fulfilment` on two of them), `src/transformer.cue` (`requiredLabels` selects on `matchLabels`), `src/types.cue` (`#LabelWorkloadType` deleted). `SPEC.md` sections for `#Platform`, `#Component` and the primitives co-update — including `SPEC.md`'s existing claim that matching unions `metadata.labels`, which becomes wrong.

**Version.** `feat!:` into `v1.0.0-alpha.4`. Not published here.

**Two fleet-visible consequences, both landing in this window rather than adding a new one.**

1. Rendered objects carry `core.opmodel.dev/workload-type` today, via the `componentLabels` fold at `src/transformer.cue:147-157`. `matchLabels` is **not rendered**, so that label disappears from every live workload. This is provisional by the author's call — an opt-in render flag was demonstrated working in `experiments/04` and deliberately not taken now.
2. Every live `Platform` with a `range`-based subscription must be rewritten to a scalar `version`. That is out of scope for both enhancement entries and is handled with the cluster migration.

**A catalog upgrade becomes an explicit edit** on every platform that wants it. For a system whose platforms live in git and reconcile continuously, an upgrade that appears in a diff and gets reviewed is the correct interaction rather than a regression; automating the bump is enhancement `0004`'s subject.

**The library half is a separate slice.** `library-subscription-collapse` deletes `materialize/filter.go`; `library-match-labels` moves `compile/match.go:111` off `metadata.labels`; `library-contract-match` implements the unresolved-demand error and the single-provider guard. Shipping this change's schema without them leaves matching reading a field the design has emptied.

**Design source.** `enhancements/0010` — D14, D28, D32, D36, D37. Measurements in `experiments/04-component-label-union/`.
