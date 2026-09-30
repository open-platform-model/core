---
title: "Platforms and catalogs"
description: "What a platform declares, what a catalog supplies, and how the two meet."
type: explanation
weight: 34
---

<!-- Open with OPM as the subject: a catalog is a versioned artifact that defines contracts (resources, traits, blueprints) and ships the transformers that implement them; a platform is the list of catalogs a render may use, each pinned to one build. Say what the page leaves to others: matching in "How matching works", member reference in "Catalog members", writing and publishing catalogs in "Write a transformer" and "Publish a catalog". Link the glossary entries for catalog, platform, contract, transformer and provider on first use. No steps, no field tables. Check against: core/src/catalog.cue, core/src/platform.cue, core/SPEC.md §3.4 and §3.6 Definition 
Kubernetes comparison, only if it helps: weave it into the sentence that introduces the concept, or into How it works, never as a section of its own. Researched candidate: A catalog is like an operator's bundle: API types (its contracts) plus the code that acts on them (its transformers), versioned and shipped together. A platform is like the set of operators installed in a cluster: it decides which APIs a render can use. Provider contracts compare with the Gateway API, where one project defines the API and another implements it. Where the comparison stops: (1) transformers run once, inside the render, not as controllers in the cluster, so admitting a catalog installs nothing; (2) a platform is a CUE module whose `cue.mod/module.cue` pins choose each catalog's build, closer to a lockfile than to installed software; (3) unlike GatewayClass there is no per-use choice between implementations: a provider contract must have exactly one implementing catalog on the platform, and OPM has no provider classes. Check against: core/src/platform.cue, core/src/catalog.cue, core/src/resource.cue (`fulfilment`), library/opm/helper/platformmodule/generate.go -->

## How it works

### A catalog defines contracts and implements some of them

<!-- `#Catalog` has `metadata` (`modulePath` with its major, such as `opmodel.dev/catalogs/opm@v4`, and `version`, both read from `identity/identity.cue`), three contract maps (`#resources`, `#traits`, `#blueprints`) and `#transformers`, each keyed by the member's own FQN. The catalog stamps every member's `modulePath` and `catalogVersion`, so a member cannot claim another catalog or build. Name the two first-party catalogs: `opmodel.dev/catalogs/opm@v4`, the abstraction family, and `opmodel.dev/catalogs/k8s@v1`, the raw Kubernetes family. Check against: core/src/catalog.cue, catalog_opm/opm/catalog.cue, catalog_opm/opm/identity/identity.cue, catalog_opm/k8s/catalog.cue, catalog_opm/k8s/identity/identity.cue -->

### A platform admits catalogs by import

<!-- `#Platform` has `metadata.name`, an informational `type` and `#registry`, keyed by each catalog's module path. An entry embeds the imported catalog as `#catalog` and may set `enable: false`. The platform module's `cue.mod/module.cue` chooses the build; each entry's `version` is read from the imported catalog, never written by hand. `#composedTransformers` folds every enabled entry's transformers, and that fold is the set matching reads. Use the `platform.cue` that `opm platform pull <dir>` writes as the snippet; `opm config init` writes no platform. Check against: core/src/platform.cue (`#CatalogEntry`, `#registry`, `#composedTransformers`), library/opm/helper/platformmodule/generate.go (`renderPlatformFile`), cli/internal/cmd/platform/pull.go -->

### Where a render gets its platform

<!-- The CLI resolves by precedence, and every render prints where its platform came from, such as `platform: instance deps (opmodel.dev/catalogs/opm@v4 v4.4.0; generated module ...)`. `opm module build` and `opm module vet` use `--platform <dir>`, else a platform generated from the module's own dependency pins (`cue.mod/module.cue`); they never read the cluster. `opm instance build`, `vet`, `diff`, `apply` and `opm module apply` use `--platform <dir>`, else the cluster Platform named `cluster`, else a platform generated from the render's own pins (the instance package's `cue.mod/module.cue`, the module's for `opm module apply`). An absent or forbidden cluster Platform warns and falls through to the pins; for `diff` and the applies, a cluster that cannot be reached is an error. `opm instance build` and `vet` never fail because of the cluster: with no kube context they skip it silently, an API server that does not answer within 10 s warns and falls through, and `--offline` never contacts a cluster. No command reads `~/.opm/platform/` any more; pass `--platform ~/.opm/platform` to keep using one left from an earlier release, and `opm config vet` warns when it finds one. No apply creates a Platform; only `opm operator install` seeds one. `opm platform check` takes `[dir]`, else `--platform`, else the cluster Platform, and refuses when there is none. The operator generates a platform module from the cluster's Platform resource: `spec.registry` subscriptions (catalog path to version) plus catalogs contributed by accepted and active TransformerRegistration claims, recorded on `status.registry` with the source `Subscription` or `Registration`. `opm platform pull <dir>` writes the cluster's platform module to disk. Check against: cli/internal/platform/spec.go, cli/internal/platform/resolve.go, cli/internal/cmd/instance/cluster.go, cli/internal/cmd/config/init.go, cli/internal/cmd/config/vet.go, cli/internal/cmd/operator/install.go (`EnsureClusterPlatformForCatalog`), cli/internal/cmd/platform/check.go, cli/internal/cmd/platform/pull.go, opm-operator/api/v1alpha1/platform_types.go, opm-operator/api/v1alpha1/transformerregistration_types.go, library/opm/helper/platformmodule/ -->

### Catalog contracts and provider contracts

<!-- Each resource and trait declares `fulfilment`: `catalog`, the default, where the declaring catalog ships the transformer; or `provider`, where it deliberately ships none and exactly one other catalog on the platform must implement it. The opm catalog's `backup` trait is a provider contract. The render refuses a provider contract required by transformers of two registry entries (path with major) (`OverSubscribedContractsError`) and a demanded contract nothing implements (`UnresolvedDemandsError`). It also refuses any platform whose inventory lists a contract collision (`ContractCollisionsError`, the first cause it reports), whatever the instance and whatever the caller's skip switch says. One exception belongs to the render's caller: a demand on a provider contract that nothing on the platform provides (zero providers) may be skipped (core/SPEC.md §3.1 `#Component`), which the CLI exposes as `--skip-unprovided` on `opm module build`, `vet` and `apply` and `opm instance build`, `vet`, `diff` and `apply`. A catalog-fulfilled gap, a provider that is present but did not match, and an over-subscribed contract still refuse. Link How matching works for what a skip renders. Check against: core/src/resource.cue, core/src/trait.cue, catalog_opm/opm/traits/v1alpha1/backup.cue, cli/internal/cmdutil/flags.go, library/opm/internal/renderstage/render.cue.tmpl (`guard`), library/opm/errors/oversubscribed.go, library/opm/errors/match.go, library/opm/errors/collision.go -->

### The contract inventory

<!-- `#Platform.#contracts` is derived with no module in hand: `defined` and `definedBy` (every contract key exactly one enabled registry entry's catalog lists, and that entry), `requiredBy` (the transformers requiring each), `providedBy` (the registry keys, path with major, providing each provider contract, whether or not an enabled catalog defines it), `unfulfilled` and `overSubscribed` (defined provider contracts with no provider, or provider contracts with several registry entries providing them), `collisions` and `collidingEntries` (contract keys more than one enabled entry's catalog lists, and the sorted registry keys, path with major, of those entries), `comparable` (transformer pairs where one matches everything the other does over a shared catalog contract), and the booleans `fulfilled`, `routable` and `discriminated`. A colliding key is in none of `defined`, `definedBy`, `requiredBy`, `unfulfilled` or `comparable`, so `fulfilled` and `discriminated` can read true while it is listed; `routable` reads false while any collision exists. The usual cause is two majors of one catalog enabled side by side, which is not supported yet (enhancement 0026 D9 designs it). Before core v2.0.0-alpha.13 such a platform did not evaluate at all (`conflicting values` on `defined` or `definedBy`). `opm platform check [dir]` prints it, including a `colliding contracts: N` section naming each key and the entries it is defined by: colliding, over-subscribed and comparable exit with the validation error code, unfulfilled exits 0. Check against: core/src/platform.cue (`#ContractInventory`), core/SPEC.md §3.4 Rationale, "Why a shared key is a collision and not a conflict", cli/internal/platform/check.go, cli/internal/cmd/platform/check.go, library/opm/platform/contracts.go -->

## Why it is built this way

### Why a module and a catalog are separate artifacts

<!-- One artifact consumes and the other publishes: a module has components to render, a catalog has contracts and transformers. Merging the roles forced each to carry the other's surface. Check against: core/SPEC.md §3.6 Rationale, "Why a single `#Catalog` construct instead of a `#Module.#defines` block"; core/SPEC.md §3.2 Rationale, "Why publication moved out of `#Module`" -->

### Why a platform imports catalogs instead of naming versions

<!-- A version string is inert data something else has to resolve; an import is resolved by CUE from the platform module's own dependency list, which is committed source. Each entry's version is read from the imported bytes, so the two cannot disagree. Check against: core/SPEC.md §3.4 Rationale, "Why an import instead of a version string" and "Why the version is derived and not authored" -->

### Why a platform carries one build per catalog

<!-- Every use of carrying several builds of one catalog collapsed on inspection, and testing a new build beside the old one is two platforms. `cue.mod` admits one build per catalog major, and two majors are two registry entries. Two majors that list the same contract keys collide, so the platform evaluates but is not routable and every render against it is refused; side-by-side majors are not supported yet (enhancement 0026 D9). Check against: core/SPEC.md §3.4 Rationale, "Why one entry names one build, and why breadth stays out", "Why the registry map is path-keyed, not Id-keyed" and "Why a shared key is a collision and not a conflict" -->

### Why upgrading a catalog is an edit

<!-- A new catalog build reaches a platform only when someone edits the pin, so an upgrade appears in a diff and gets reviewed instead of arriving because someone else published. Check against: core/SPEC.md §3.4 Rationale, "Why a catalog upgrade is a manual edit, and why that is not a regression" -->

### Why a catalog lists contracts it does not implement

<!-- Without the listing, a catalog declaring a provider contract looked the same as one that had never heard of it, and the refusal could not say the contract was defined at all. Listing makes "defines" and "implements" two separate stated facts. Check against: core/SPEC.md §3.6 Rationale, "Why a catalog publishes its contracts as members"; core/SPEC.md §2.1 Rationale, "Why a contract declares where its fulfilment comes from, rather than the platform inferring it" -->

### Why a provider contract has exactly one provider

<!-- When this was measured no cross-catalog provider existed, so there was nothing to arbitrate; refusing two keeps the choice explicit, where silently picking one would make behaviour depend on catalog load order. Over-subscription counts registry entries rather than transformers, because one provider catalog may carry two transformers for one contract; the entry is keyed with its major, so two majors of one catalog are two providers. The inventory computes this count once and the render build reads it, so the generation gate and the render refusal agree. Check against: core/SPEC.md §2.1 Rationale, "Why exactly one provider, with no arbitration between two"; core/SPEC.md §3.4 Rationale, "Why over-subscription counts registry entries" -->

### Why the inventory reports and does not refuse

<!-- An assertion inside the platform would fail the whole value on the first bad contract and could not name it; a report that still evaluates can name every party. An unfulfilled contract must not block anything, because a platform may list a contract ahead of its provider. A contract key two enabled entries list is one more report under the same rule: until core v2.0.0-alpha.13 it was the one case that failed the whole value instead. Check against: core/SPEC.md §3.4 Rationale, "Why the inventory reports and does not refuse" -->

## Common mistakes

### Publishing a new catalog build changes no platform

<!-- Platforms pin builds in `cue.mod/module.cue`, and nothing resolves "latest". Edit the pin, or run `cue mod get <path>@<version>` in the platform module, then run `opm platform check <dir>`. A platform generated from a render's own pins follows the module's or instance package's `cue.mod/module.cue`, so there that is the pin to edit. Check against: cli/internal/platform/moduledeps.go, cli/internal/cmd/platform/check.go, core/SPEC.md §3.4 Constraints -->

### Build and apply can use different platforms

<!-- `opm module build` and `opm module vet` never read the cluster: they use `--platform` or the module's own pins, while `opm module apply` prefers the cluster's Platform. `opm instance build` and `vet` read the cluster Platform when a kube context reaches it and otherwise fall back to the instance package's pins, and `--offline` skips the cluster. A component that renders locally can therefore match differently on apply. Compare the provenance lines, pass the same `--platform`, or fetch the cluster's module with `opm platform pull`. Check against: cli/internal/platform/spec.go, cli/internal/platform/resolve.go, cli/internal/cmd/instance/cluster.go, cli/internal/cmd/module/build.go, cli/internal/cmd/instance/apply.go, cli/internal/cmd/instance/diff.go, cli/internal/cmd/module/apply.go, cli/internal/cmd/platform/pull.go -->

### The platform `type` does not affect matching

<!-- `type` is informational; nothing in matching reads it. Check against: core/src/platform.cue (`type`), library/opm/helper/platformmodule/generate.go -->

### A listed contract is not always implemented

<!-- A catalog can define a provider contract and ship no transformer for it. `opm platform check` reports it as unfulfilled and exits 0; a module that demands it fails at render unless the render passes `--skip-unprovided`. Check against: cli/internal/cmd/platform/check.go, core/src/platform.cue (`unfulfilled`), catalog_opm/opm/traits/v1alpha1/backup.cue -->

### Enabling two majors of one catalog refuses every render

<!-- The wrong assumption: adding `opmodel.dev/catalogs/opm@v5` beside the enabled `opmodel.dev/catalogs/opm@v4` entry lets modules pick either major. Correct reading: every contract key both majors list is a collision, the platform is not routable, and every render is refused with `ContractCollisionsError`, the first cause the refusal names, even for a module that demands none of the colliding keys. Keep one of the defining entries enabled (`enable: false` on the other); `opm platform check` names the keys and the entries. Check against: core/src/platform.cue (`collisions`, `collidingEntries`), library/opm/errors/collision.go, cli/internal/platform/check.go -->

### A registry key must be the imported catalog's module path

<!-- The `#registry` key is the imported catalog's module path, major included; a mismatch fails the platform build naming the entry. Check against: core/src/platform.cue (`#registry`), cli/internal/config/platform.go -->

## What enforces this

<!-- One line per rule, each with its badge:
- A registry key equals the imported catalog's `modulePath`: cue.
- An entry's `version` equals the imported build: cue.
- One entry per catalog path, and one build per catalog major: cue (map semantics) and CUE's module resolution.
- A catalog stamps each member's `modulePath` and `catalogVersion`, and a divergent authored value conflicts: cue.
- A contract map key is a contract FQN and a transformer key an implementation FQN: cue.
- A catalog's `version` is concrete: cue (an unstamped catalog is an incomplete value).
- A catalog's version major agrees with its path, and every member's FQN agrees with the identity package: publish (`#IdentityPackage`, `#CatalogMemberFQNGate` in `opm catalog publish`).
- Changes to beta and GA contracts are additive only: publish (the compatibility gate).
- A contract key listed by more than one enabled registry entry's catalog: reported by `#contracts.collisions` (the platform still evaluates, `routable` false); kernel (render refused, `ContractCollisionsError`, the first cause the gate joins), also reported by `opm platform check` (validation exit) and by the operator (Platform `Ready=False`, reason `ContractCollisions`).
- A provider contract supplied by two registry entries (path with major, so two majors of one catalog count as two): kernel (render refused), also reported by `opm platform check` and by the operator (Platform `Ready=False`, reason `OverSubscribedContracts`).
- An unfulfilled provider contract: nothing refuses it until a module demands it, then kernel, unless the render's caller asked to skip unprovided demands.
- Comparable transformer pairs: reported by `opm platform check`, validation exit, and by the operator (Platform `Ready=False`, reason `ComparablePredicates`); the render gate does not refuse them.
- Every provider contract a catalog declares is listed in its contract maps: the catalog's own CI (`task vet:listing` in catalog_opm), not a publish gate. Verify which badge the writing guide wants for catalog CI.
Check against: core/src/platform.cue, core/src/catalog.cue, core/src/identity_package.cue, cli/internal/publish/catalog_gates.go, cli/internal/publish/gates.go, cli/internal/compat/compat.go, cli/internal/cmd/platform/check.go, library/opm/internal/renderstage/render.cue.tmpl, library/opm/errors/collision.go, opm-operator/internal/status/conditions.go, opm-operator/internal/controller/platform_inventory.go, catalog_opm/Taskfile.yml -->
