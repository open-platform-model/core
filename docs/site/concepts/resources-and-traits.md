---
title: "Resources and traits"
description: "What a resource describes, what a trait adds to it, and why they are separate."
type: explanation
sidebar:
  order: 32
---

<!-- Open with OPM as the subject: a resource describes something that must exist (a container, volumes, ConfigMaps), a trait describes how it behaves (scaling, exposure, restart policy), and a catalog publishes both as versioned contracts. Say what the page leaves to others: attaching them in "Components and blueprints", how transformers pick them up in "How matching works", contract keys and `apiVersion` in "Versions in OPM" and "Identity and names". Link the glossary entries for resource, trait, catalog, contract and FQN on first use. No steps, no field tables. Check against: core/src/resource.cue, core/src/trait.cue, core/SPEC.md §2.1 and §2.2 Definition 
Kubernetes comparison, only if it helps: weave it into the sentence that introduces the concept, or into How it works, never as a section of its own. Researched candidate: Each resource and trait is a versioned schema with an `apiVersion` on the Kubernetes ladder (`v1alpha1`, `v1beta1`, `v1`), which a Kubernetes reader knows from CRD versions. A resource is closest to the part of a pod spec that says what runs; a trait to a setting Kubernetes spreads across objects (replicas on the Deployment, ports on a Service, a disruption budget on a PodDisruptionBudget). Where the comparison stops: neither is a Kubernetes kind. The `container` resource becomes a Deployment, StatefulSet, DaemonSet, Job or CronJob depending on the workload type its blueprint sets, and a trait may produce its own object (`expose` becomes a Service) or only change another. Nothing is installed in the cluster to serve them; transformers read them at render time. Check against: core/src/types.cue (`#APIVersionType`), catalog_opm/opm/resources/v1beta1/container.cue, catalog_opm/opm/traits/v1beta1/expose.cue, catalog_opm/opm/transformers/service_transformer.cue, catalog_opm/opm/transformers/deployment_transformer.cue -->

## How it works

### A resource is something that must exist

<!-- `#Resource`: `metadata` (`name`, `apiVersion`, a catalog-authored `fqn` such as `opmodel.dev/catalogs/opm/resources/container@v1beta1`, `catalogVersion` as provenance, `description`, categorisation `labels`), one `spec` field named after the resource in camelCase (`spec: container:`), optional `matchLabels`, `fulfilment`, and the hidden `#nameConstraint`. Every resource a component attaches is a required demand: if no transformer on the platform handles it, the render fails. Check against: core/src/resource.cue, core/SPEC.md §3.1 Constraints (demands), library/opm/internal/renderstage/render.cue.tmpl (`unresolvedResources`) -->

### A trait modifies a resource

<!-- `#Trait` has the same metadata and spec shape plus `appliesTo` (the resources it modifies) and `optional`, its posture when no transformer handles it. The catalog states the posture as a default: `bool | *true` for advisory traits such as `expose` and `scaling`, `bool | *false` for load-bearing ones such as `backup`. A module overrides it where it attaches the trait: `#traits: (FQN): SomeTrait & {optional: true}`. An unhandled advisory trait renders with a warning; an unhandled load-bearing one fails the render. In catalog_opm every trait's `appliesTo` lists `container`, except `backup`, which lists `volumes`. Check against: core/src/trait.cue, catalog_opm/opm/traits/v1beta1/expose.cue, catalog_opm/opm/traits/v1beta1/scaling.cue, catalog_opm/opm/traits/v1alpha1/backup.cue, library/opm/internal/renderstage/render.cue.tmpl (`_handled`, `unhandledWarnings`, `unresolvedTraits`) -->

### Each spec sits under its own key

<!-- A component's spec is the union of its members' specs, and each member's fields sit under its own camelCase name (`spec.container`, `spec.expose`, `spec.scaling`), so two members that both define `port` never collide. Check against: core/src/resource.cue (`spec`), core/src/trait.cue (`spec`), core/src/component.cue (`_allFields`) -->

### Who implements a resource or trait

<!-- Usually the declaring catalog also ships the transformer (`fulfilment: "catalog"`, the default). A `provider` contract is one the declaring catalog deliberately ships no transformer for, such as the opm catalog's `backup@v1alpha1` trait; another catalog on the platform must implement it. Keep the platform side on "Platforms and catalogs". Verify: no catalog in the workspace implements `backup@v1alpha1` today. Check against: core/src/resource.cue (`fulfilment`), core/src/trait.cue (`fulfilment`), catalog_opm/opm/traits/v1alpha1/backup.cue -->

### The raw Kubernetes family

<!-- The `opmodel.dev/catalogs/k8s@v1` catalog carries one resource per Kubernetes kind (`deployment`, `service`, `configmap` and so on) and no traits or blueprints. Each raw resource renders to exactly one object of its kind. It is the escape hatch for what the abstraction resources do not model, and the abstraction members must not depend on it. Point to "Use a raw Kubernetes resource" and "Raw Kubernetes resources". Check against: catalog_opm/k8s/catalog.cue, catalog_opm/k8s/resources/v1/, catalog_opm/k8s/transformers/deployment_transformer.cue, catalog_opm/Taskfile.yml (`vet:layering`) -->

## Why it is built this way

### Why a trait is separate from a resource

<!-- A resource is a thing that must exist, so a component whose resource has no transformer has nothing to deploy and must fail. A trait modifies something that renders anyway, so "render without it, and say so" is a coherent outcome for a trait and an incoherent one for a resource. That asymmetry is why only traits have an `optional` posture. Check against: core/SPEC.md §3.1 Rationale, "Why resources get no optionality marker, and why that asymmetry is real rather than convenient" and "Why an unmet demand is an error at all" -->

### Why the catalog suggests and the module decides

<!-- Whether a trait matters depends on the trait and the component together: `backup` on a throwaway cache is advisory, on a database it is the point. The catalog knows the common case and states it as a default; the module knows its own case and narrows the default where it attaches the trait, which CUE never treats as a conflict. `core` states no default of its own, because two defaults cancel. Check against: core/SPEC.md §2.2 Rationale, "Why optionality is a property of the Trait, and why `core` states no default for it" and "Why the earlier demand-side marker was dropped" -->

### Why each spec is namespaced

<!-- Namespacing moves a field collision to the moment the definition is written, where unification reports it, instead of a silent merge at deploy time. Check against: core/SPEC.md §2.1 Rationale, "Why `spec` is namespaced under the definition's camelCase name" -->

### Why the schemas stay plain OpenAPI

<!-- A resource or trait schema has to be readable by tools that do not run CUE (CRD generation, form UIs, kubectl plugins), so a `spec` holds no comprehensions. Check against: core/SPEC.md §2.1 Rationale, "Why we don't allow free-form CUE inside `spec`" -->

### Why resources and traits publish no defaults

<!-- A good default depends on the kind being rendered (an update strategy means different things to a Deployment and a StatefulSet), and the resource or trait is the one layer that does not know the kind. Defaults live in blueprints, in the module's `#config`, or in the transformer. Check against: core/SPEC.md §6.4 Rationale, "Why primitives publish bounds and never defaults" -->

## Common mistakes

### A resource is not a Kubernetes kind

<!-- The misreading: `container` means Deployment. The kind is decided at render, by which transformer matches the component's workload type. Check against: catalog_opm/opm/transformers/deployment_transformer.cue, catalog_opm/opm/transformers/statefulset_transformer.cue, catalog_opm/opm/transformers/daemonset_transformer.cue, catalog_opm/opm/transformers/job_transformer.cue, catalog_opm/opm/transformers/cronjob_transformer.cue (`requiredLabels`) -->

### An attached advisory trait can be skipped

<!-- The misreading: attaching a trait guarantees its effect. An advisory trait (`optional` resolved `true`) that no matched transformer handles is skipped with a warning, and the render succeeds. Read the warnings, or narrow the posture to `false` at the attachment to make the render fail instead. Check against: library/opm/kernel/render.go (`UnhandledTraits`), library/opm/internal/renderstage/render.cue.tmpl (`unhandledWarnings`) -->

### `appliesTo` is not checked when you attach a trait

<!-- The misreading: OPM refuses a trait on a component without a resource from its `appliesTo`. The specification says unification refuses it; core/src/component.cue does not check it, so today the mismatch shows up only at render, as an unhandled or unresolved trait. Verify: attach `tr.#Expose` to a component with no container and record what `opm module build` reports. Check against: core/src/trait.cue (`appliesTo`), core/src/component.cue, core/SPEC.md §2.2 Constraints -->

### Every attached resource must be implemented

<!-- There is no optional resource. A resource with no transformer on the platform is an unresolved demand, and the render is refused as a whole, including the parts that did match. Check against: core/SPEC.md §3.1 Constraints, library/opm/errors/match.go (`UnresolvedDemandsError`), library/opm/kernel/render_decode.go (`gateErrors`) -->

### The labels on a resource or trait are only categories

<!-- `metadata.labels` on a resource or trait (`resource.opmodel.dev/category`, `trait.opmodel.dev/category`) categorise it; they never reach the component, and nothing matches on them. Matching uses `matchLabels`. Check against: core/src/resource.cue, core/src/component.cue, catalog_opm/opm/resources/v1beta1/container.cue -->

## What enforces this

<!-- One line per rule, each with its badge:
- `spec` has exactly one field, named after the member in camelCase: cue.
- `fulfilment` is `catalog` or `provider`: cue (closed enum).
- A trait's `optional` is stated as a default and not pinned to a value: publish (`#TraitOptionalGate` in `opm catalog publish`).
- `fqn`, `modulePath` and `catalogVersion` agree with the catalog's identity package: publish (`#CatalogMemberFQNGate`).
- Changes to a beta or GA contract are additive only: publish (the compatibility gate in `opm catalog publish`).
- An unhandled resource, or an unhandled trait resolved `optional: false`, fails the render: kernel (`UnresolvedDemandsError`).
- An unhandled trait resolved `optional: true` warns: kernel, advisory only.
- `appliesTo` is non-empty and a trait attaches only where it applies: convention (not checked; see Common mistakes).
- A resource or trait schema marks no defaults: convention.
- Abstraction members do not depend on the raw family: the catalog's own CI (`task vet:layering`), which none of the four badges names. Verify which badge the writing guide wants for catalog CI.
Check against: core/src/resource.cue, core/src/trait.cue, cli/internal/publish/catalog_gates.go, cli/internal/publish/gates.go, cli/internal/compat/compat.go, library/opm/internal/renderstage/render.cue.tmpl, library/opm/errors/match.go, catalog_opm/Taskfile.yml, core/SPEC.md §6.3 -->
