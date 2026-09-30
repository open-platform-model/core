---
title: "The application model and the platform model"
description: "Why OPM is named a platform model while it models applications today, and what each model covers."
type: explanation
sidebar:
  order: 29
---

<!-- Open with OPM as the subject: Open Platform Model names two models. The application model, which OPM has today, describes an application and what it needs from a cluster. The platform model describes the platform an application runs on. Today OPM models a platform only as far as rendering needs. Say what the page assumes ("What OPM is", linked from its Common mistakes entry) and what it covers: what each model describes, what exists of each today, and why the application model came first. Check against: core/SPEC.md (section 1), opm/README.md (Vision) -->

## How it works

### The application model

<!-- What OPM models today, in one paragraph: a module (its components and its `#config`), components built from resources, traits and blueprints, and a module instance that embeds a module and holds the values. This is the page that names the schema definitions, so link each one on first use to its generated schema reference entry, written as the plain word followed by the definition name, for example "module (`#Module`)": `#Module`, `#Component`, `#config`, `#ModuleInstance`, `#Resource`, `#Trait`, `#Blueprint`. Until the generator writes per-definition entries, link the definitions index (/docs/reference/definitions/). Point to "Modules and instances" and "Components and blueprints" by title rather than repeating them. Check against: core/SPEC.md (sections 2, 3.1 to 3.3 and 3.5), core/src/module.cue, core/src/component.cue, core/src/module_instance.cue -->

### The platform, as far as OPM models it today

<!-- A `#Platform` carries the catalogs it admits (`#registry`, one entry per catalog module path) and, from them, the transformers that decide how components become Kubernetes objects (`#composedTransformers`). It also reports a contract inventory (`#contracts`): which contracts its catalogs define, which ones its transformers require, whether each provider-fulfilled contract has exactly one provider, and which contract keys collide because more than one enabled catalog lists them. That is the whole platform half today. Point to "Platforms and catalogs". Check against: core/src/platform.cue, core/SPEC.md (section 3.4) -->

### The platform model

:::note[Direction]
The platform model is meant to describe a whole platform: its global settings, the controllers and APIs it is built from, and the services it offers to teams. No design exists yet.
:::

<!-- Direction note rules (0018:D3): present-tense status, no dates, and a link to the enhancement once one exists. No enhancement proposes the platform model itself, so the note links none for it. Two draft enhancements, both not started, touch the platform side without being the platform model; decide whether the note names them, by id. 0026 (module-dictated catalog versions and the generated platform) lets a platform admit each catalog lineage with a version range and lets the module's own pin pick the version inside it, refusing a pin outside the range. The CLI's deps fallback is not part of 0026 and the note must not present it as such: when a render runs with no `--platform` and no cluster `Platform` is used, the CLI generates a platform from the render's own catalog pins, so the module's pin is used because no platform exists to admit or bound it. 0026 covers the case the fallback leaves untouched: a platform is given, it holds a range, and the kernel checks the pin against it. 0027 (self-service kinds from published modules) lets a platform team bind a published module to a kind that consumers create by supplying values only; an offering binds one exact release and an update policy, not a 0026 range. Check against: enhancements/0026/README.md, enhancements/0027/README.md, cli/openspec/specs/platform-resolution/spec.md ("Module commands render against the module's deps", "Renders fall back to their own deps"), opm/README.md (Roadmap, Phase 3) -->

## Why it is built this way

### Why the application model came first

<!-- Opinion is allowed here. Your own reasoning for starting with applications, for example that an application model is useful on any cluster by itself, while a platform model needs applications to serve. Check against: opm/README.md (Vision, Roadmap), opm/CONSTITUTION.md -->

### Why the two are separate models

<!-- Module authors and platform teams change different things on different schedules. The application model must not depend on one platform's shape, which is why rendering lives in the platform's transformers and not in the module. Check against: core/SPEC.md (section 1, "Type System Overview"; section 4.1 Rationale) -->

## Common mistakes

### OPM does not model your whole platform

<!-- The wrong assumption, invited by the name: OPM describes the cluster, its controllers and the services it offers. Correct reading: today it models applications, and a platform only as far as rendering needs. Point to "What OPM does not do". Check against: core/src/platform.cue -->

### The Platform resource is not the platform model

<!-- The wrong assumption: the `Platform` custom resource the operator reads is the platform model. Correct reading: its spec holds the platform's `type`, the catalogs it subscribes to (`registry`, each with `enable` and `version`) and its `skewPolicy`, and nothing else about the cluster. Check against: opm-operator/api/v1alpha1/platform_types.go, core/src/platform.cue -->

## What enforces this

<!-- The platform-side rules that hold today, each with its badge: a platform admits at most one provider for each provider-fulfilled contract (kernel; `OverSubscribedContractsError`, also reported by `opm platform check` and the operator's `OverSubscribedContracts` reason); a contract key has at most one enabled defining catalog (reported by `#contracts.collisions`; kernel, `ContractCollisionsError`; also reported by `opm platform check` and the operator's `ContractCollisions` reason); the catalog builds a render uses are the ones the platform module's `cue.mod` pins (cue). Nothing enforces the platform model, which does not exist. Check against: core/src/platform.cue, library/opm/errors/oversubscribed.go, library/opm/errors/collision.go, cli/internal/cmd/platform/check.go, opm-operator/internal/status/conditions.go -->
