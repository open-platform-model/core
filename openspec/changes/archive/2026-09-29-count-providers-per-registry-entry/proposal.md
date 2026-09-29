## Why

The single-provider rule for a provider-fulfilled contract is counted in two places that disagree. `#Platform.#contracts` (this repo) counts only contracts an enabled catalog DEFINES and keys a provider by its transformers' stamped, major-free `metadata.modulePath`; the library render build's guard counts every enabled registry entry's transformers, reads fulfilment from each transformer's own requirement, and keys a provider by registry key (path plus major). Measured in CUE on 2026-09-29, the two diverge on two real platform shapes:

- **Bug 1.** Two majors of one provider catalog enabled (k8up at v2 and v3, both requiring `backup`): the inventory counts one provider and reports `routable: true`; the render guard counts two and refuses every render on the platform.
- **Bug 2.** Two providers enabled while the catalog that DEFINES the contract is disabled or absent: the inventory omits the contract and reports `routable: true`; the render guard counts two and refuses every render.

`opm-operator` generates a platform package only when the inventory is routable, so on both shapes it hands out a platform on which every render then fails, and `opm platform check` says "routable: yes". The user approved (2026-09-29) making the render guard's count the only count: core computes it once, and the library render reads core's value instead of keeping its own guard, so the two cannot drift again.

This corrects the delivery of `0015:D2` (one provider per contract, refused naming both catalog paths) and `0015:D18` (routable is the generation gate), both already delivered; `0010:D37` is the rule being counted. It implements no undelivered decision, so it carries no `enhancement.yaml`.

## What Changes

- **`#ContractInventory` gains `providedBy: [#ContractFQNType]: [...#ModulePathType]`.** For every provider-fulfilled contract FQN that some enabled transformer requires, the ascending-sorted registry keys (`path@vN`) of the enabled entries whose transformers require it. A key is present exactly when there is at least one provider. It is the value the library render build will read instead of its own guard, and the list operator and cli diagnostics print as "provided by".
- **BREAKING: `overSubscribed` and `routable` change meaning.** `overSubscribed` becomes "every key of `providedBy` with two or more registry keys", which now includes contracts no enabled entry defines. The counting key is the registry key, so two majors of one catalog are two providers; two adapters in one entry stay one provider. Platforms of the Bug 1 and Bug 2 shapes, which today read `routable: true`, read `routable: false`.
- **`unfulfilled` is recounted** against `providedBy`: a defined provider-fulfilled resource or trait with no `providedBy` key. A contract no enabled catalog defines is never unfulfilled. The result is unchanged on every platform core pins today.
- **Fulfilment is read from the transformer's own requirement**, never from the defining catalog's member, so counting no longer depends on whether an enabled entry defines the contract.
- `definedBy`, `requiredBy`, `comparable`, `fulfilled` and `discriminated` are unchanged in shape and value. The hidden `_providers` field is replaced by hidden `_providerSet` plus the exported `providedBy`.
- `SPEC.md` §2.1 (the `fulfilment` constraint) and §3.4 (`#Platform` rationale and `#ContractInventory` shape, constraints and rationale) drop the documented divergence and state the one count. `docs/site/concepts/platforms-and-catalogs.md` and `docs/site/concepts/how-matching-works.md` follow.
- New pins in `src/platform_contracts_pins.cue` for both bug shapes (two majors; definer disabled; definer absent) and `providedBy` pins on the existing platforms, written first and red on today's core.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `platform-contract-inventory`: `unfulfilled` and over-subscription are counted per registry entry over every enabled transformer, and the inventory exposes `providedBy`.
- `contract-fulfilment`: the single-provider requirement stops documenting a second, divergent inventory count; the render build and the inventory count the same thing.

## Impact

**Release classification: `feat(platform)!:` with a `BREAKING CHANGE:` footer.** Nothing is removed and one field is added, but the published values of `overSubscribed` and `routable` change for two platform shapes, which is a tightened contract under Principle I. It relies on `@v2` still being in prerelease (Principle IV): in prerelease mode it advances the alpha counter within the major, expected to cut `2.0.0-alpha.12` (alpha.9 to alpha.11 were each one `feat`; core `HEAD` is docs-only since alpha.11). The module path does not move.

Downstream migration cost: every render on a Bug 1 or Bug 2 platform is already refused by the library render build, so no platform that works today stops working. What changes is where the refusal lands: consumers that generate on `routable` now refuse at generation.

| Consumer | What it has to do |
| --- | --- |
| `library` | Change B, `read-provider-count-from-core`: bump `schema.DefaultSchemaModule` to this release, add the render/inventory parity test (red on alpha.10, green here), decode `ProvidedBy`, make the render build read `#contracts.providedBy`, `overSubscribed` and `routable` instead of its own guard, and refuse a platform pinning an older core. |
| `opm-operator` | Change C: pick up B's release; the inventory refusal names `provided by <providedBy>`; `TransformerRegistration` acceptance reads `ProvidedBy`. Bug 1 and Bug 2 platforms become `Ready=False` with reason `OverSubscribedContracts` instead of per-render `RenderFailed`. |
| `cli` | Change D: pick up B's release; `opm platform check` prints `provided by` and stops reporting a Bug 2 platform as vacuously routable. `cli/hack/platform` and `cli/examples` re-pin through `task deps:update`. |
| `catalog_opm`, `modules`, `opm-modules` | Nothing required. Their core pins do not bind the render. The routine `task deps:update` after the release re-pins them. |

Principle V: `providedBy` has three named consumers before it ships (the library render build, the operator refusal message and acceptance check, the cli report). Without it the render needs its own count, which is the drift this change removes.

The four-change set, its ordering and the core release it waits on are in `orchestration.md`.
