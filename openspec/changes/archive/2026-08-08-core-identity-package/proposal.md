## Why

Two schemas that enhancement `0010` relies on exist only inside a design document. `0010` D40's own alternatives record it plainly: `#IdentityPackage` is "defined in this entry's `schemas/target.cue` and nowhere in shipped code." A schema that lives only in a design document cannot validate anything.

That would be a documentation gap if nothing depended on it. Three decisions do:

- **`0010` D43 and D45 deleted `core`'s version-major assertion** for `#Catalog` and `#Module` respectively, on the ground that `0011` D8 "already requires publish to refuse an identity file that does not match `#IdentityPackage`." That reasoning holds only if the validation is real. Today it is not — D8 states the requirement and nothing implements it against a shipped schema — so the check was traded for a promise.
- **`0010` D21 removed `core`'s `fqn` derivation** for every catalog member, accepting a *measured* loss: a catalog on `1.2.0` shipping `fqn: "…/secrets@1.1.0"` passes `cue vet -c` with **exit 0**. It was traded explicitly for a publish gate. Under `0010` D4 a wrong key is permanent — modules match against it forever.
- **`0010` states the catalog-member path and FQN rule four times** — D17, D21, D25, D42 — and implements it nowhere.

This change ships both schemas in `core`, which is what makes those three trades honest rather than deferred.

## What Changes

**`#IdentityPackage` ships in `core`.** The shape an artifact's committed `identity/identity.cue` must match: `ModulePath!` and `Version!` written by tooling, `RegistryPath` and `Major` derived through `#ArtifactRef`, `VersionMajor` derived from `Version` and asserted equal to `Major`, and `kindPrefix` enumerating exactly one path prefix per catalog member kind.

**`#CatalogMemberFQNGate` ships beside it.** Given an identity package, a kind, a name and what the catalog actually authored, it derives what the declared path, FQN and `catalogVersion` must be — and unification produces the diagnostic. `declaredAPIVersion` is optional at the top level and required for the three primitive kinds, because a transformer declares none.

**Validation is by unification, not by comparison.** Neither schema is accompanied by a Go-side expected-versus-found check. The CLI loads the value and unifies it; what the author reads is CUE's own error. Every line of Go that re-states the contract is a line that can disagree with it.

**The identity package's import-free invariant is preserved.** `identity/identity.cue` deliberately imports nothing — `catalog_opm/src/identity/identity.cue` states that it "sits at the bottom of the catalog's import graph" and mirrors `core.#VersionType` locally for exactly that reason. Validation is **external**: the CLI unifies through the CUE API, in Go, and the author's file gains no import. Shipping the schema here does not change what an identity file imports.

## Capabilities

### New Capabilities

- `identity-package`: the shape of an artifact's committed identity file — what is written, what is derived, what relation is asserted between them, and the one place that relation is asserted.
- `catalog-member-gate`: the shape a catalog member's declared path, FQN and provenance must satisfy relative to its catalog's identity, expressed so that unification produces the diagnostic.

### Modified Capabilities

None. Both are new surfaces. `artifact-identity` supplies `#ArtifactRef` and `#ModulePathType`; `primitive-keying` supplies `#ContractFQNType`, `#ImplFQNType` and `#APIVersionType`. Neither requirement set changes.

## Impact

**Depends on `core-identity-shape`, and this is a hard compile dependency rather than an ordering preference.** `#IdentityPackage` types `ModulePath!` as `#ModulePathType` in the `@vN` form, `Version!` as `#VersionType`, and projects `RegistryPath`/`Major` through `_ref: #ArtifactRef`. Measured 2026-08-05 against `src/`: `#ArtifactRef` does not exist and `#ModulePathType` is still the no-major regex. This change cannot compile before that one lands.

**Also depends on `core-primitive-keying`** for `#CatalogMemberFQNGate`'s `declaredFQN` and `declaredAPIVersion` types.

**Schema — this repo.** A new file for both definitions, or an addition to `src/types.cue` — placement is an implementation choice, but they belong together because they are checked the same way. `SPEC.md` gains sections if either is added to `.tasks/spec-tracked.txt`, which it should be: both are top-level, non-helper, consumer-facing constructs, and the allowlist is the source of truth for what requires documentation.

**Version.** `feat:` — additive to the `v1.0.0-alpha.4` line. This change alone would be a minor; it rides in an alpha the sibling changes have already made breaking.

**What consumes it.** `cli`'s publish pipeline (`cli-publish-pipeline`), the catalog-member gate on `opm catalog publish` (`cli-catalog-member-gate`), `opm module vet`, and `opm mod init`'s repair mode — all in enhancement `0011`. Nothing in `library` reads either schema.

**Design source.** `enhancements/0011` D21 and D22, resting on `0010` D5, D17, D21, D25, D40, D42, D43, D45. `0010/schemas/target.cue` carries both target shapes.
