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

<!-- A `#Platform` carries the catalogs it admits (`#registry`, one entry per catalog module path) and, from them, the transformers that decide how components become Kubernetes objects (`#composedTransformers`). It also reports a contract inventory (`#contracts`): which contracts its catalogs define, which ones its transformers require, and whether each provider-fulfilled contract has exactly one provider. That is the whole platform half today. Point to "Platforms and catalogs". Check against: core/src/platform.cue, core/SPEC.md (section 3.4) -->

### The platform model

:::note[Direction]
The platform model is meant to describe a whole platform: its global settings, the controllers and APIs it is built from, and the services it offers to teams. No design exists yet.
:::

<!-- Direction note rules (0018:D3): present-tense status, no dates, and a link to the enhancement once one exists. Two draft enhancements touch the platform side without being the platform model: the generated platform with module-dictated catalog versions, and self-service kinds that a platform team serves from published modules. Decide whether the note names them. Check against: enhancements/0026/README.md, enhancements/0027/README.md, opm/README.md (Roadmap, Phase 3) -->

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

<!-- The platform-side rules that hold today, each with its badge: a platform admits at most one provider for each provider-fulfilled contract (kernel; `OverSubscribedContractsError`, also reported by `opm platform check`); the catalog builds a render uses are the ones the platform module's `cue.mod` pins (cue). Nothing enforces the platform model, which does not exist. Check against: core/src/platform.cue, library/opm/errors/oversubscribed.go, cli/internal/cmd/platform/check.go -->
