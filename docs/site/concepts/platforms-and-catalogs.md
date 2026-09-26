---
title: "Platforms and catalogs"
description: "What a platform declares, what a catalog supplies, and how the two meet."
type: explanation
sidebar:
  order: 34
---

<!-- Open with OPM as the subject: a catalog is a versioned artifact that defines contracts (resources, traits, blueprints) and ships the transformers that implement them; a platform is the list of catalogs a render may use, each pinned to one build. Say what the page leaves to others: matching in "How matching works", member reference in "Catalog members", writing and publishing catalogs in "Write a transformer" and "Publish a catalog". Link the glossary entries for catalog, platform, contract, transformer and provider on first use. No steps, no field tables. Check against: core/src/catalog.cue, core/src/platform.cue, core/SPEC.md §3.4 and §3.6 Definition 
Kubernetes comparison, only if it helps: weave it into the sentence that introduces the concept, or into How it works, never as a section of its own. Researched candidate: A catalog is like an operator's bundle: API types (its contracts) plus the code that acts on them (its transformers), versioned and shipped together. A platform is like the set of operators installed in a cluster: it decides which APIs a render can use. Provider contracts compare with the Gateway API, where one project defines the API and another implements it. Where the comparison stops: (1) transformers run once, inside the render, not as controllers in the cluster, so admitting a catalog installs nothing; (2) a platform is a CUE module whose `cue.mod/module.cue` pins choose each catalog's build, closer to a lockfile than to installed software; (3) unlike GatewayClass there is no per-use choice between implementations: a provider contract must have exactly one implementing catalog on the platform, and OPM has no provider classes. Check against: core/src/platform.cue, core/src/catalog.cue, core/src/resource.cue (`fulfilment`), cli/internal/config/templates.go (`DefaultPlatformModuleFile`, `DefaultPlatformCUE`) -->

## How it works

### A catalog defines contracts and implements some of them

<!-- `#Catalog` has `metadata` (`modulePath` with its major, such as `opmodel.dev/catalogs/opm@v4`, and `version`, both read from `identity/identity.cue`), three contract maps (`#resources`, `#traits`, `#blueprints`) and `#transformers`, each keyed by the member's own FQN. The catalog stamps every member's `modulePath` and `catalogVersion`, so a member cannot claim another catalog or build. Name the two first-party catalogs: `opmodel.dev/catalogs/opm@v4`, the abstraction family, and `opmodel.dev/catalogs/k8s@v1`, the raw Kubernetes family. Check against: core/src/catalog.cue, catalog_opm/opm/catalog.cue, catalog_opm/opm/identity/identity.cue, catalog_opm/k8s/catalog.cue, catalog_opm/k8s/identity/identity.cue -->

### A platform admits catalogs by import

<!-- `#Platform` has `metadata.name`, an informational `type` and `#registry`, keyed by each catalog's module path. An entry embeds the imported catalog as `#catalog` and may set `enable: false`. The platform module's `cue.mod/module.cue` chooses the build; each entry's `version` is read from the imported catalog, never written by hand. `#composedTransformers` folds every enabled entry's transformers, and that fold is the set matching reads. Use the `~/.opm/platform/platform.cue` that `opm config init` writes as the snippet. Check against: core/src/platform.cue (`#CatalogEntry`, `#registry`, `#composedTransformers`), cli/internal/config/templates.go (`DefaultPlatformCUE`) -->

### Where a render gets its platform

<!-- The CLI resolves by precedence: `--platform <dir>`, then the cluster's Platform resource (read by `opm instance apply`, `opm instance diff` and `opm module apply`), then the local default in `~/.opm/platform/`. When `opm instance apply` falls back to the local default, it creates the cluster Platform if none exists. The operator generates a platform module from the cluster's Platform resource: `spec.registry` subscriptions (catalog path to version) plus catalogs contributed by accepted and active TransformerRegistration claims, recorded on `status.registry` with the source `Subscription` or `Registration`. `opm platform pull <dir>` writes the cluster's platform module to disk. Check against: cli/internal/platform/spec.go, cli/internal/platform/resolve.go, cli/internal/workflow/apply/apply.go (`EnsureClusterPlatform`), cli/internal/cmd/platform/pull.go, opm-operator/api/v1alpha1/platform_types.go, opm-operator/api/v1alpha1/transformerregistration_types.go, library/opm/helper/platformmodule/ -->

### Catalog contracts and provider contracts

<!-- Each resource and trait declares `fulfilment`: `catalog`, the default, where the declaring catalog ships the transformer; or `provider`, where it deliberately ships none and exactly one other catalog on the platform must implement it. The opm catalog's `backup` trait is a provider contract. The render refuses a provider contract supplied by transformers from two catalogs (`OverSubscribedContractsError`) and a demanded contract nothing implements (`UnresolvedDemandsError`). Check against: core/src/resource.cue, core/src/trait.cue, catalog_opm/opm/traits/v1alpha1/backup.cue, library/opm/internal/renderstage/render.cue.tmpl (`guard`), library/opm/errors/oversubscribed.go, library/opm/errors/match.go -->

### The contract inventory

<!-- `#Platform.#contracts` is derived with no module in hand: `defined` and `definedBy` (every contract and the catalog listing it), `requiredBy` (the transformers requiring each), `unfulfilled` and `overSubscribed` (provider contracts with no implementing catalog, or with several), `comparable` (transformer pairs where one matches everything the other does over a shared catalog contract), and the booleans `fulfilled`, `routable` and `discriminated`. `opm platform check [dir]` prints it: over-subscribed and comparable exit with the validation error code, unfulfilled exits 0. Check against: core/src/platform.cue (`#ContractInventory`), cli/internal/cmd/platform/check.go, library/opm/platform/contracts.go -->

## Why it is built this way

### Why a module and a catalog are separate artifacts

<!-- One artifact consumes and the other publishes: a module has components to render, a catalog has contracts and transformers. Merging the roles forced each to carry the other's surface. Check against: core/SPEC.md §3.6 Rationale, "Why a single `#Catalog` construct instead of a `#Module.#defines` block"; core/SPEC.md §3.2 Rationale, "Why publication moved out of `#Module`" -->

### Why a platform imports catalogs instead of naming versions

<!-- A version string is inert data something else has to resolve; an import is resolved by CUE from the platform module's own dependency list, which is committed source. Each entry's version is read from the imported bytes, so the two cannot disagree. Check against: core/SPEC.md §3.4 Rationale, "Why an import instead of a version string" and "Why the version is derived and not authored" -->

### Why a platform carries one build per catalog

<!-- Every use of carrying several builds of one catalog collapsed on inspection, and testing a new build beside the old one is two platforms. `cue.mod` admits one build per catalog major, and two majors are two registry entries. Check against: core/SPEC.md §3.4 Rationale, "Why one entry names one build, and why breadth stays out" and "Why the registry map is path-keyed, not Id-keyed" -->

### Why upgrading a catalog is an edit

<!-- A new catalog build reaches a platform only when someone edits the pin, so an upgrade appears in a diff and gets reviewed instead of arriving because someone else published. Check against: core/SPEC.md §3.4 Rationale, "Why a catalog upgrade is a manual edit, and why that is not a regression" -->

### Why a catalog lists contracts it does not implement

<!-- Without the listing, a catalog declaring a provider contract looked the same as one that had never heard of it, and the refusal could not say the contract was defined at all. Listing makes "defines" and "implements" two separate stated facts. Check against: core/SPEC.md §3.6 Rationale, "Why a catalog publishes its contracts as members"; core/SPEC.md §2.1 Rationale, "Why a contract declares where its fulfilment comes from, rather than the platform inferring it" -->

### Why a provider contract has exactly one provider

<!-- When this was measured no cross-catalog provider existed, so there was nothing to arbitrate; refusing two keeps the choice explicit, where silently picking one would make behaviour depend on catalog load order. Over-subscription counts catalogs rather than transformers, because one provider catalog may carry two transformers for one contract. Check against: core/SPEC.md §2.1 Rationale, "Why exactly one provider, with no arbitration between two"; core/SPEC.md §3.4 Rationale, "Why over-subscription counts catalogs" -->

### Why the inventory reports and does not refuse

<!-- An assertion inside the platform would fail the whole value on the first bad contract and could not name it; a report that still evaluates can name every party. An unfulfilled contract must not block anything, because a platform may list a contract ahead of its provider. Check against: core/SPEC.md §3.4 Rationale, "Why the inventory reports and does not refuse" -->

## Common mistakes

### Publishing a new catalog build changes no platform

<!-- Platforms pin builds in `cue.mod/module.cue`, and nothing resolves "latest". Edit the pin, or run `cue mod get <path>@<version>` in the platform module, then run `opm config vet`. Check against: cli/internal/config/templates.go (`DefaultPlatformModuleFile`), core/SPEC.md §3.4 Constraints -->

### Build and apply can use different platforms

<!-- `opm instance build` and `opm module build` use `--platform` or `~/.opm/platform/`; `opm instance apply`, `opm instance diff` and `opm module apply` prefer the cluster's Platform when they can read it. A component that renders locally can therefore match differently on apply. Pass the same `--platform`, or fetch the cluster's module with `opm platform pull`. Check against: cli/internal/platform/spec.go, cli/internal/platform/resolve.go, cli/internal/cmd/instance/apply.go, cli/internal/cmd/instance/diff.go, cli/internal/cmd/module/apply.go, cli/internal/cmd/platform/pull.go -->

### The platform `type` does not affect matching

<!-- `type` is informational; nothing in matching reads it. Check against: core/src/platform.cue (`type`), cli/internal/config/templates.go (`DefaultPlatformCUE`) -->

### A listed contract is not always implemented

<!-- A catalog can define a provider contract and ship no transformer for it. `opm platform check` reports it as unfulfilled and exits 0; a module that demands it fails at render. Check against: cli/internal/cmd/platform/check.go, core/src/platform.cue (`unfulfilled`), catalog_opm/opm/traits/v1alpha1/backup.cue -->

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
- A provider contract supplied by two catalogs: kernel (render refused), also reported by `opm platform check`.
- An unfulfilled provider contract: nothing refuses it until a module demands it, then kernel.
- Comparable transformer pairs: reported by `opm platform check`, validation exit. Verify whether anything else refuses them; nothing in opm-operator does.
- Every provider contract a catalog declares is listed in its contract maps: the catalog's own CI (`task vet:listing` in catalog_opm), not a publish gate. Verify which badge the writing guide wants for catalog CI.
Check against: core/src/platform.cue, core/src/catalog.cue, core/src/identity_package.cue, cli/internal/publish/catalog_gates.go, cli/internal/publish/gates.go, cli/internal/compat/compat.go, cli/internal/cmd/platform/check.go, library/opm/internal/renderstage/render.cue.tmpl, catalog_opm/Taskfile.yml -->
