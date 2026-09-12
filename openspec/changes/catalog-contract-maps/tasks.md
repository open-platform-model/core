# Tasks: catalog-contract-maps

Load `.claude/skills/core-schema-edit/SKILL.md` before task 1.1. Schema tasks and their SPEC.md tasks land in the same commit (Principle II); they are paired below, not scheduled apart.

## 1. src/catalog.cue

- [x] 1.1 Add `#resources`, `#traits` and `#blueprints` inside `#Catalog` per design.md (pattern constraints keyed `#ContractFQNType`, `A=apiVersion` label alias, `modulePath: "\(M._ref.registryPath)/<kind>/\(A)"`, `catalogVersion: M.version`), each with a doc comment of at most 6 lines ending in `See SPEC.md § 3.6`. Pair: `SPEC.md` §3.6 Shape adds the three maps; Constraints replace the "NOT enumerated" bullet with the key-type, stamp, unstamped-fqn, no-adapter-required and empty-is-valid rules. Verify: `(cd src && cue vet ./...)` passes.
- [x] 1.2 Rewrite the `#Catalog` WHY block paragraph and doc-comment sentence that say primitives surface only transitively, within the 6-line rule. Pair: `SPEC.md` §3.6 Definition sentence, Rationale bullets (replace "Why catalogs don't enumerate ..."; add the apiVersion-segment and primitive-not-projection bullets), and "See also" Publishes line. Verify: `task docs:check` reports nothing for `catalog.cue` and `task spec:check` passes.

## 2. src/catalog_pins.cue

- [x] 2.1 Create `src/catalog_pins.cue` with hidden positive pins: a lean listed trait's stamped `modulePath` and `catalogVersion` read by key; a `fulfilment: "provider"` trait read through `#traits` on a catalog with `#transformers: {}`; an empty catalog's three maps as `len(...) == 0`. Each pin forces evaluation (indexing, `len`, or interpolation). Verify: `(cd src && cue vet ./...)` passes, and temporarily flipping one expected value makes it fail.
- [x] 2.2 Add the four MUST-FAIL cases as comments (filing drift on `modulePath`, stale `catalogVersion`, a `#Resource` under `#traits`, a build-form key), each run once in place and the printed `cue vet` error recorded verbatim beneath it. Verify: with every case commented back out, `(cd src && cue vet ./...)` passes.

## 3. src/types.cue

- [x] 3.1 Add the `#Catalog.#resources/#traits/#blueprints  map keys  #ContractFQNType` row to the "WHY unused inside `core`, per role" comment table. Comment-only. Verify: `task fmt:check` passes and the published schema is byte-identical for that file apart from the comment.

## 4. Validation

- [x] 4.1 `task generate:index`; review that only the `#Catalog` description row changed and no new row appeared. Verify: `task generate:index:check` passes.
- [x] 4.2 `task check` (fmt, vet, INDEX freshness, SPEC inventory, doc-comment limit) passes.
- [x] 4.3 Grep `src/`, `SPEC.md`, `docs/` and `README.md` for "transitively" and "not enumerated" and confirm every remaining hit is about something other than catalog membership.
