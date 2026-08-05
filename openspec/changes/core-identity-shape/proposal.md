## Why

An OPM artifact's identity is currently spread across fields that must be kept in agreement by hand, and the agreement is not checked anywhere. `#Module.metadata` carries a `modulePath` prefix, a `name`, a `nameSnakeCase` projection of that name, and a `version`, and its `fqn` recombines three of them into `path/name:semver`. Nothing states that the path leaf is the name, nothing states that the declared version is the tag the artifact was published at, and `uuid` hashes a string containing the version — so `uuid` moves on every release.

That last property is the reason this is not a tidying exercise. `#ModuleInstance.metadata.uuid` derives from `#Module.metadata.uuid`, and it is the value carried in the `module-instance.opmodel.dev/uuid` label that `opm-operator/internal/apply/prune.go:107` reads to decide whether it owns a live object. An identity that moves with the version means every upgrade silently orphans whatever the new render stopped emitting — the delete is skipped, the reconcile reports success, and the resources stay.

Enhancement `0010` (Module and Catalog Identity, `accepted`) resolves this by making an artifact's declared path *be* its complete CUE module path, major suffix included, and by splitting artifact identity from ownership identity so the two can move differently. This change is that enhancement's `core-identity-shape` slice: the schema half, in the repo that publishes the contract.

It is the root of the whole enhancement. `core-primitive-keying` and `core-platform-and-match` both depend on the types introduced here, `0011`'s `core-identity-package` cannot compile without `#ArtifactRef` and the widened `#ModulePathType`, and every downstream slice in `library`, `cli`, `opm-operator`, the catalogs and the module fleet sits behind the `v1.0.0-alpha.4` cut that these four core changes feed.

## What Changes

**Path types split in two.** `#ModulePathType` gains a required `@vN` suffix and becomes what an *artifact* declares. A new `#PackagePathType` — the current no-suffix regex — becomes what a *primitive* declares. Both admit underscores in segments, because a module path now ends in the module's own snake_case name.

**A module path decomposes once, in one place.** A new `#ArtifactRef` splits a module path into `registryPath` (the OCI repository) and `major`. This replaces every "compose an address from a prefix and a name" site in `cli` and `library`.

**`fqn` stops being a recombination and becomes a field.** `#Module.metadata.fqn` and `#Catalog.metadata.fqn` are the module path verbatim. `#ModuleFQNType`'s `path/name:semver` form retires with the derivation it existed to type.

**Module names become snake_case.** `metadata.name` is retyped `#SnakeNameType`, the path's leaf is constrained to equal it, and `nameSnakeCase` and `#KebabToSnake` are deleted — with `name` already in the constrained form there is no projection left to make.

**Instance identity is severed from artifact identity.** `#ModuleInstance.metadata` gains an explicit `fqn` derived from the module's *major-free* `registryPath`, and `uuid` derives from that. `module.uuid` answers *which module is this* and moves across a major; `instance.uuid` answers *which resources does this manage* and survives every upgrade including a major bump.

**`#Module.metadata.version` is retained and reaches no key.** It is supplied by the module's identity subpackage and read by the instance and by the `module.opmodel.dev/version` label — but neither `fqn` nor `uuid` reads it.

Two things this change deliberately does **not** do, both on decisions taken after the ones above:

- **No version-major agreement is asserted in `core`** (D45, transposing D43). `identity/identity.cue` asserts `VersionMajor: Major` at the point both values are written; `core` re-deriving it one hop downstream tests the same relation over the same two values. The exposure this accepts — an artifact whose identity package is absent or non-conformant carries no consumer-runnable check — is stated in `05-risks.md` and bounded by `0011` D8/D12/D21 at publish.
- **No module rename migration is included.** Measured 2026-08-05: zero hyphenated module names remain on either `modules/` branch, so the `#SnakeNameType` retype breaks nothing that exists.

## Capabilities

### New Capabilities

- `artifact-identity`: what a `#Module` and a `#Catalog` declare about themselves — the path types, `#ArtifactRef`'s decomposition, `fqn`, `registryPath`, the snake_case name and the leaf-equals-name constraint, and which of those values reach a key.
- `instance-identity`: what a `#ModuleInstance` declares about the deployment it owns — its own `fqn`, the `uuid` derived from it, and the invariant that neither the module's version nor its major reaches either.

### Modified Capabilities

None. This repo has no existing specs — `openspec/specs/` was created empty when OpenSpec was added on 2026-08-05, and this is its first change.

## Impact

**Schema — this repo.** `src/types.cue` (path types, `#ArtifactRef`, `#SnakeNameType`, deletions), `src/module.cue`, `src/module_instance.cue`, `src/catalog.cue`. `SPEC.md` sections for `#Module`, `#Catalog` and `#ModuleInstance` co-update in the implementing commits, per `core-schema-edit`. `src/INDEX.md` regenerates.

**Version.** `feat!:` — advances `v1.0.0-alpha.4`. **Not** a module-major event: `opmodel.dev/core@v1` has published `v1.0.0-alpha.1`, `.2` and `.3` and no stable `v1.0.0`, so the compatibility promise has not started and the module path does not move. Rollback is a re-pin to `alpha.3`.

**Not published by this change.** `core-alpha-release` is the single cut point, and it also waits on `core-primitive-keying`, `core-platform-and-match` and `0011`'s `core-identity-package`. Nothing downstream moves until that tag exists.

**Downstream, once it is published.** Every consumer pins an explicit prerelease, so retargeting is a `task update-deps` sweep over an enumerable set: `library` (compile breakage plus testdata), `cli` (address-composition helpers deleted), `opm-operator` (dep bump only — no feature code), `catalog_opm` / `catalog_kubernetes` / `catalog_opm_experimental`, and `modules/`. Every module's `uuid` moves once, and every live instance's `uuid` moves once; the live-instance relabel is out of scope here and handled by the `v0 → v1` fleet migration (D18).

**Design source.** `enhancements/0010` — D1, D6, D8, D38, D41, D43, D45, and D40's identity half. `02-design.md` §Integration Points names the exact lines; `schemas/target.cue` carries `#ModuleIdentity`, `#InstanceIdentity`, `#CatalogIdentity` and `#ArtifactRef` as the target shapes plus the MUST-FAIL and MUST-VET-CLEAN cases this change's tests mirror.
