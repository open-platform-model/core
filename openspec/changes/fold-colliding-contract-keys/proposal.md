## Why

A platform that enables two majors of one catalog whose catalogs list the same contract keys fails to evaluate today. `#Platform.#contracts` folds `defined` and `definedBy` keyed by contract FQN, so two enabled definers of one key conflict (`metadata.catalogVersion` "1.0.0" against "2.0.0" in `defined`, `opm@v1` against `opm@v2` in `definedBy`) and the whole platform value is bottom. That violates `SPEC.md` §3.4's own rule that no inventory report makes the platform fail to evaluate, and it leaves every consumer reading a failed value instead of a named reason. Measured in enhancement 0026 (`experiments/01-one-major-per-build` case A; `experiments/06-collision-tolerant-fold`), and recommended as its own core fix by 0026 OQ17. The user approved the fix on 2026-09-30.

It is the interim safety net, not side-by-side majors: 0026 D9 later makes two majors legitimate through per-resolution builds. Until then a colliding platform must evaluate, name its collisions, and read `routable: false`.

## What Changes

- **`#Platform.#contracts` folds only contract keys with exactly one enabled definer.** A hidden `_definers` set records, per contract key, the enabled registry entries whose catalog lists it in `#resources`, `#traits` or `#blueprints`. `defined` and `definedBy` keep their per-entry comprehensions, each member guarded to single-definer keys. This is experiment 06's `core.patch`, applied without its probe markers.
- **`#ContractInventory` gains `collisions: [...#ContractFQNType]`**: every contract key more than one enabled entry lists, sorted ascending.
- **`#ContractInventory` gains `collidingEntries: [#ContractFQNType]: [...#ModulePathType]`**: each colliding key mapped to the ascending registry keys (path with its major) of the enabled entries listing it. The pair mirrors `providedBy` and `overSubscribed`.
- **`routable` is redefined** as `len(overSubscribed) == 0 && len(collisions) == 0`. A colliding platform evaluates and is not routable.
- `requiredBy`, `providedBy`, `unfulfilled`, `overSubscribed` and `comparable` are textually unchanged. A disabled entry never counts as a definer. A platform with one enabled major reads the same value in every field (measured: every existing `*_pins.cue` file passes unchanged against the patched fold).
- **Stated limitation.** A colliding key leaves `defined`, so it also leaves `requiredBy`, `unfulfilled` and `comparable`. `fulfilled` and `discriminated` can therefore read `true` while `routable` is `false`. Consumers MUST treat a non-empty `collisions` as overriding both. `SPEC.md` states it and pins hold it.
- `SPEC.md` §2.1 (the provider count bullet), §3.4 `#Platform` (Definition, Shape, Constraints, Rationale) and §3.4 `#ContractInventory` (Definition, Shape, Constraints, Rationale). `docs/site/concepts/platforms-and-catalogs.md` lists the new fields. `src/INDEX.md` regenerates if a first doc line moves.
- New pins in `src/platform_contracts_pins.cue`: a second and third major of the base catalog, collision readouts, and the limitation pins. The first pin, on existing fields only, is red on today's core.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `platform-contract-inventory`: `defined` and `definedBy` cover only single-definer keys; keys with more than one enabled definer are reported as `collisions` and `collidingEntries`; `routable` also requires no collision; a platform whose enabled entries share keys still evaluates.

`contract-fulfilment` needs no change: its requirements speak of provider counts and render refusals, which this change leaves untouched.

## Impact

**Release classification: `feat(platform):`, not breaking.** The only value change is on inputs that failed to evaluate before, and the whole pin suite passes unchanged, so Principle I's breaking test (validated yesterday, fails today) is not met; `AGENTS.md` classes a new field on a published definition as `feat`. Contrast `e8a69be`, which was `feat(platform)!` because it flipped `routable` on platforms that already evaluated. It relies on the v2 line being in prerelease only in the ordinary sense (Principle IV): in prerelease mode `feat` and `feat!` both advance the alpha counter, expected `v2.0.0-alpha.13`. The module path does not move.

**Downstream migration cost, stated although nothing breaks:**

- The published invariant "`routable` is true exactly when `overSubscribed` is empty" is redefined. `library` (the render gate and `Contracts()` decode), `opm-operator` (the inventory refusal) and `cli` (`opm platform check`) each encode it, and each derives a message from `overSubscribed` when `routable` is false.
- **Old-kernel render hazard.** A kernel older than change B (library `v1.0.0-alpha.35` and earlier, meaning the current operator and cli `alpha.25`) given a colliding platform pinned to this core renders it instead of failing: its gate never reads `routable`, and both majors' transformers match every component under the shared keys, so a bridge transformer yields duplicate objects (measured by the change-set mapper on library `30f08c1`: two Deployments named `probe-maj0-web`). Core cannot prevent this. Change B's typed refusal must follow this release closely, and no workspace platform moves to this core before B is released.

| Consumer | What it has to do |
| --- | --- |
| `library` | Change B, `refuse-colliding-contracts`: decode `collisions` and `collidingEntries` (absent read as empty), raise a typed `ContractCollisionsError` in the render gate and `Contracts()`, add a not-routable catch-all, move `DefaultSchemaModule` to this release. |
| `opm-operator` | Change C, `name-contract-collisions`: a `ContractCollisions` Ready reason ahead of `OverSubscribedContracts`, after B's release. |
| `cli` | Change D, `name-contract-collisions`: `opm platform check` prints the collisions and counts them in the routable verdict and the exit message, after B's release. |
| `catalog_opm`, `modules`, `opm-modules` | Nothing required. The workspace `task deps:update` re-pins them, held until B is released. |

Principle V: both fields have named consumers before they ship (B's render rows and decode, C's finding, D's report). Without them a consumer could only say "not routable" and would have to recount definers itself, which is the drift the previous change set removed.

No enhancement decision is fully delivered (0026 OQ17 recommends the fix; D9 is not delivered by it), so the change carries no `enhancement.yaml`. The five-change set, its ordering and the core release it waits on are in `orchestration.md`.
