---
title: "Versions in OPM"
description: "The four different version numbers in OPM and what each one promises."
type: explanation
sidebar:
  order: 35
---

<!-- Open with OPM as the subject: OPM artifacts carry four separate version numbers, each answering a different question, and this page says what each one promises and what reads it. The four: the major at the end of a module or catalog path (`@v3`), the release SemVer in `identity/identity.cue` (`3.0.1`), a contract's `apiVersion` (`v1beta1`), and the major of the core schema every artifact imports (`opmodel.dev/core@v2`). Assumes Modules and instances and Platforms and catalogs. Link The Catalog Contract for the full additive-only rule rather than restating it. The CLI and operator release versions are outside the four; give them one sentence at most (the CLI refuses to apply when the cluster's operator is newer than it). Check against: core/SPEC.md, core/src/types.cue, modules/apprise/identity/identity.cue, modules/apprise/cue.mod/module.cue, cli/internal/inventory/gates.go (GateOperatorVersionCeiling) 
Kubernetes comparison, only if it helps: weave it into the sentence that introduces the concept, or into How it works, never as a section of its own. Researched candidate: Nearest idea: a Kubernetes API version on the alpha, beta, GA ladder (`v1beta1` becoming `v1`). A contract's `apiVersion` uses the same ladder with the same meaning: alpha promises nothing, beta and GA promise compatibility. Where it stops: the API server serves several versions of one kind and converts between them. OPM converts nothing. `…/scaling@v1beta1` and `…/scaling@v1` are two unrelated contract keys, a module demands exactly one, and a transformer matches only the key it names. For the release version, make no comparison (0018:D9): a release version names fixed bytes, and an OPM breaking release moves the major inside the module path (`…/apprise@v3`), so a new major is a new module, not a new version of the old one. Check against: core/src/types.cue (#APIVersionType, #APIVersionGated, #ContractFQNType, #ModulePathType), cli/internal/compat/level.go, library/opm/errors/match.go -->

## How it works

<!-- One illustrative snippet showing all four numbers in one module: `identity/identity.cue` with `ModulePath: "…/apprise@v3"` and `Version: "3.0.1"`; `cue.mod/module.cue` requiring `opmodel.dev/catalogs/opm@v4` at `v4.4.0` and `opmodel.dev/core@v2` at `v2.0.0-alpha.10`; and an import of `opmodel.dev/catalogs/opm/traits/v1beta1`, where `v1beta1` is the contract level. Point out that the catalog's major (v4) and its contracts' level (v1beta1) are unrelated numbers. Use a neutral path such as `example.com/modules/my_app@v1` in the snippet if the real values are likely to move. Check against: modules/apprise/identity/identity.cue, modules/apprise/cue.mod/module.cue, modules/apprise/components.cue, catalog_opm/opm/identity/identity.cue -->

### The path major

<!-- The `@vN` at the end of `metadata.modulePath` on a module or catalog: the same string as the `module:` line in `cue.mod/module.cue` and as an import statement. It is part of artifact identity: `metadata.fqn` is the path verbatim and `metadata.uuid` hashes it, so a new major is a new module. A path at `@v3` publishes only `3.x.y` tags. Instance identity ignores it (Identity and names covers why). Resources, traits, blueprints and transformers carry a package path with no major (`#PackagePathType`). Check against: core/src/types.cue (#ModulePathType, #PackagePathType, #ArtifactRef), core/src/module.cue, core/src/catalog.cue, cli/internal/publish/gates.go (gateTagMajor) -->

### The release version

<!-- The SemVer in `identity/identity.cue` `Version`, read into `metadata.version`, written by `opm module version set` or `opm catalog version set`, and published as the tag `v<version>`. A published tag names fixed bytes and is never replaced. It is not part of any `fqn` or `uuid`. On a module it becomes the `module.opmodel.dev/version` label on every rendered object and a ModuleInstance's `spec.module.version`, written with a "v" prefix. On a catalog it is stamped as `catalogVersion` on every member, as provenance that no match compares, and it is the version inside every transformer key (`…/transformers/deployment-transformer@4.4.1`). A catalog's release version also decides when the compatibility check runs at publish: never for a dev build, and not for beta or GA members while the tag being published is a release prerelease (`-alpha.N`, `-beta.N`, `-rc.N`); it arms at the first stable tag. Check against: core/src/module.cue, core/src/catalog.cue, core/src/transformer.cue, catalog_opm/opm/transformers/deployment_transformer.cue, cli/internal/workflow/render/moduleref.go, cli/internal/publish/registry.go, cli/internal/publish/compat.go (isDevTag, isReleasePrerelease, eligibleByPackage) -->

### The contract level

<!-- `metadata.apiVersion` on a resource, trait or blueprint: `vNalphaM`, `vNbetaM` or `vN` (`#APIVersionType`). It is the only version inside a contract key (`opmodel.dev/catalogs/opm/traits/scaling@v1beta1`) and the package the member is filed and imported under (`opmodel.dev/catalogs/opm/traits/v1beta1`). Matching compares keys for equality and never orders two levels. Alpha promises nothing and the compatibility check skips it; beta and GA are held to the additive-only rule. A breaking change ships as a new apiVersion, which is a new key beside the old one. The level is per member: catalog_opm at `@v4` ships `v1beta1` and `v1alpha1` members in one build. Transformers have no apiVersion. Check against: core/src/types.cue (#APIVersionType, #APIVersionGated, #ContractFQNType), core/src/catalog.cue, core/src/transformer.cue, catalog_opm/opm/traits/v1beta1/scaling.cue, catalog_opm/opm/traits/v1alpha1/backup.cue, cli/internal/compat/level.go -->

### The core schema major

<!-- Every module, catalog and platform imports `opmodel.dev/core@v2`. Core versions like any CUE module: a breaking schema revision moves the major (it has gone from `@v0` to `@v1` to `@v2`), and consumers move by rewriting the import. The `@v2` line ships `v2.0.0-alpha.N` prereleases and has taken breaking changes inside that line (alpha.7 removed `#Subscription`), so it promises nothing yet. The kernel is verified against one exact core release and names it (`DefaultSchemaModule`), and the platform module `opm config init` seeds pins one core release. Check against: core/src/cue.mod/module.cue, core/README.md, core/CHANGELOG.md, library/opm/schema/loader.go, cli/internal/config/templates.go (DefaultCorePath, DefaultCorePin) -->

### Which build a render uses

<!-- A module's `cue.mod/module.cue` pins the core and catalog builds it was written against; the platform module pins its own. For every path both pin, the render uses the platform's build. When the module requires a newer build of an `opmodel.dev` path than the platform carries, core included, that is version skew: by default the render continues against the platform's build and reports the skew; under the refuse policy it stops before evaluation. The policy is the cluster Platform's `spec.skewPolicy` (`Warn` or `Refuse`) when the cluster Platform is the platform source, otherwise `skewPolicy` in the CLI config (`warn` or `refuse`, default `warn`). Link Version skew. Check against: library/opm/internal/renderstage/promote.go, library/opm/internal/renderstage/skew.go, library/opm/kernel/render.go (SkewPolicy), opm-operator/api/v1alpha1/platform_types.go, cli/internal/config/config.go, cli/internal/workflow/render/env.go -->

## Why it is built this way

<!-- Rewritten from core's specification rationale, with no decision numbers. Check against: core/SPEC.md -->

### Why a contract key carries its level and not the catalog build

<!-- A module's demand and a platform's supply have to match on an equal key. When contract keys carried the catalog build, a contract whose transformer came from a different catalog broke on every release of the declaring catalog until both sides were rebuilt together. Keying on the contract's own level lets the two catalogs release on their own schedules. Check against: core/SPEC.md (§2.1 Rationale, "Why the key carries `apiVersion` and not `catalogVersion`"), core/src/types.cue (#ContractFQNType) -->

### Why the level follows the Kubernetes ladder

<!-- The ladder lets a contract say it promises nothing yet (alpha) without leaving the versioning scheme; a bare `vN` would force a promise from the first day or none anywhere. Nothing compares two levels in matching; the promise is read off one string. Check against: core/SPEC.md (§2.1 Rationale, "Why the level follows the Kubernetes ladder rather than a bare major"), core/src/types.cue (#APIVersionGated), cli/internal/compat/level.go -->

### Why the release version stays out of identity

<!-- When a module's `fqn` included its version, its uuid moved on every release, the instance uuid derived from it moved too, and the operator, which skips deleting objects whose instance label disagrees with the uuid it recorded, left stale objects running on every upgrade while reporting success. Now module identity moves only with the path major, and instance identity moves with neither. Check against: core/SPEC.md (§3.2 and §3.5 Rationale), core/src/module.cue, core/src/module_instance.cue, opm-operator/internal/apply/prune.go -->

### Why a transformer key names the build

<!-- A transformer may change on every release, so its key names the exact build that ships it; two builds of one transformer never share a key, and a platform operator can see which bytes run. This is also why transformers carry no apiVersion and the compatibility check never judges them. Check against: core/SPEC.md (§4.1 Rationale), core/src/types.cue (#ImplFQNType), cli/internal/publish/compat.go -->

### Why the major check lives in the identity file

<!-- The path and the version are both written in `identity/identity.cue`, so their agreement is asserted there (`#IdentityPackage.VersionMajor`) and a failure names the file the author has open. `#Module` and `#Catalog` deliberately do not repeat the check. Check against: core/SPEC.md (§5.2 Rationale, §3.2 Rationale), core/src/identity_package.cue, core/src/module.cue -->

## Common mistakes

### A contract's stability comes from its `apiVersion`

<!-- Misreading: a catalog release like `4.5.0-alpha.1` makes its contracts unstable, or a stable catalog release makes every contract stable. Correct: each member's `apiVersion` states its promise, and one build mixes levels. State the one interaction plainly: `opm catalog publish` does not compare beta or GA members while the catalog's own tag is a release prerelease. Verify: The Catalog Contract page says a `v1beta1` contract inside an alpha release is fully bound, which the current publish check does not enforce; reconcile the two pages before publishing either. Check against: cli/internal/publish/compat.go, core/src/types.cue, catalog_opm/docs/site/reference/catalog-contract.md -->

### A new `apiVersion` is a new contract beside the old one

<!-- Misreading: moving a contract from `v1beta1` to `v1beta2` upgrades the modules that use it. Correct: it is a new key with no history. A module demanding the old key keeps matching it only while an enabled catalog still ships a transformer requiring it; otherwise the render fails with an unresolved demand that lists the apiVersions the platform does implement. Verify: catalog_opm ships each contract at a single apiVersion today, so there is no in-tree example of two levels side by side. Check against: library/opm/errors/match.go (UnresolvedDemand.Alternatives), cli/internal/publish/compat.go, catalog_opm/opm/resources, catalog_opm/opm/traits -->

### A module release keeps the module's identity

<!-- Misreading: publishing `3.0.2` creates a new module or a new instance. Correct: `fqn` and `uuid` are the same for every release inside `@v3`; only the `module.opmodel.dev/version` label on rendered objects changes. A major bump changes the module's uuid and leaves the instance's alone. Check against: core/src/module.cue, core/src/module_instance.cue, core/src/identity_pins.cue -->

### The operator's API version is not a contract level

<!-- Misreading: the `v1alpha1` in `apiVersion: opmodel.dev/v1alpha1` on a ModuleInstance or Platform is a contract level, or says how mature the module is. Correct: it is the Kubernetes API version of the operator's custom resources, a separate number. Check against: opm-operator/api/v1alpha1/groupversion_info.go, cli/internal/inventory/cr.go -->

### The platform's catalog build is the one that renders

<!-- Misreading: requiring `opmodel.dev/catalogs/opm@v4` at `v4.4.0` in the module's `cue.mod` makes the render use 4.4.0. Correct: the render uses the build the platform pins; a newer requirement is reported as skew, and refused only under the refuse policy. Check against: library/opm/internal/renderstage/promote.go, library/opm/internal/renderstage/skew.go, library/opm/errors/skew.go -->

### A member's `catalogVersion` is provenance

<!-- Misreading: `metadata.catalogVersion` on a resource or trait is that member's version. Correct: it records which catalog build shipped the definition, moves on every catalog release, and no match or publish comparison reads it; the member's own version is its `apiVersion`. Check against: core/src/resource.cue, core/src/catalog.cue, cli/internal/compat/compat.go (provenance exclusion) -->

## What enforces this

<!-- cue: `metadata.modulePath` must end in `@vN` (#ModulePathType); `version` must be SemVer 2.0 (#VersionType); `apiVersion` must be on the ladder (#APIVersionType); a catalog with no `metadata.version` is an incomplete value; `fqn` on a module or catalog is the path and cannot be supplied. Check against: core/src/types.cue, core/src/module.cue, core/src/catalog.cue -->

<!-- publish: the identity file's version major must equal its path major (#IdentityPackage, refused as "the identity package does not conform to core's #IdentityPackage"); the tag's major must match the path ("the tag would not name a version within the major this artifact's path declares"); a published tag is never replaced ("<path> already holds <tag>"); each catalog member's key and `catalogVersion` must agree with the identity file (#CatalogMemberFQNGate); beta and GA members may only grow ("<repo> would break a contract it already published"), skipped for alpha members, dev builds and release-prerelease tags. Say that `opm module vet` runs the first two early. Check against: cli/internal/publish/identity.go, cli/internal/publish/gates.go, cli/internal/publish/registry.go, cli/internal/publish/catalog_gates.go, cli/internal/publish/compat.go, cli/internal/publish/vet.go -->

<!-- kernel: contract keys match by equality, so a demand at an apiVersion nothing implements fails the render; skew is reported, or refused under the refuse policy ("version skew on <path>: module requires <version>, platform carries <version> (refused by policy)"); a module fetched from a registry whose declared version differs from its tag fails with an identity mismatch. Check against: library/opm/errors/match.go, library/opm/errors/skew.go, library/opm/errors/identity.go, library/opm/kernel/render.go -->

<!-- convention: a module's release version follows SemVer; nothing compares a module's `#config` with its previous release, since the additive-only check runs for catalogs only. Core moving its major on a breaking change is its maintainers' policy, and the `@v2` alpha line has taken breaking changes without one. Check against: cli/internal/publish/compat.go (gateCompat returns early for anything but a catalog), core/CHANGELOG.md -->
