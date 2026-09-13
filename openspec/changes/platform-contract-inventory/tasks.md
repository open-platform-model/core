# Tasks: platform-contract-inventory

Load `.claude/skills/core-schema-edit/SKILL.md` before task 1.1. Schema tasks and their SPEC.md tasks land in the same commit (Principle II); they are paired below, not scheduled apart.

## 1. src/platform.cue

- [ ] 1.1 Add `#ContractInventory` beside `#CatalogEntry` per design.md, with a doc comment of at most 6 lines ending in `See SPEC.md § 3.4`. Pair: `SPEC.md` §3.4 gains the `#ContractInventory` subsection (Definition, Shape, Constraints, Rationale). Add `#ContractInventory` to `.tasks/spec-tracked.txt`. Verify: `(cd src && cue vet ./...)` passes and `task spec:check` passes.
- [ ] 1.2 Add `#Platform.#contracts` after `#composedTransformers` per design.md (the fold, the guarded demand comprehensions, `_providers` keyed by the stamped `modulePath`), with a WHY block on report-versus-gate (0015 D18) and on counting catalogs. Pair: `SPEC.md` §3.4 `#Platform` Shape, Constraints (derived, never authored; reports, never refuses) and the three Rationale bullets named in design.md. Verify: `(cd src && cue eval -e '#Platform.#contracts' ./)` prints the empty inventory with both booleans true.

## 2. src/platform_contracts_pins.cue

- [ ] 2.1 Create the pins file with the three stand-in catalogs (base with a resource, a catalog-fulfilled trait, a provider-fulfilled trait and a blueprint plus one adapter; two provider catalogs each with one adapter requiring the provider-fulfilled trait) and the five platforms from design.md, as hidden fields; pin each platform's `unfulfilled`, `overSubscribed`, `fulfilled`, `routable`, one `definedBy` entry and one `requiredBy` list by interpolation or `len`. Verify: `(cd src && cue vet ./...)` passes, and flipping one expected value makes it fail.
- [ ] 2.2 Add the pin that a transformer declaring only `requiredResources` is counted without error (the presence-guard case). Verify: `cue vet` passes; removing one guard in `platform.cue` makes it fail.

## 3. Validation

- [ ] 3.1 `task generate:index`; review that exactly one row (`#ContractInventory`) was added. Verify: `task generate:index:check` passes.
- [ ] 3.2 `task check` (fmt, vet, INDEX freshness, SPEC inventory, doc-comment limit) passes.
- [ ] 3.3 Grep `src/`, `SPEC.md` and `docs/` for `#ContractRouting`; confirm no hit (the construct is deliberately not landed).
