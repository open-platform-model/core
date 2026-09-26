---
title: "Components and blueprints"
description: "Why every component needs a blueprint, and how a component is derived from it."
type: explanation
sidebar:
  order: 31
---

<!-- Open with OPM as the subject: a component is one deployable part of a module, assembled from resources, traits and blueprints, and OPM derives everything about it (its spec, its matching labels, its names) from what it attaches. A blueprint is the catalog's ready-made bundle for one kind of workload. Scope note for the author: the description says every component needs a blueprint, but only a component carrying the `container` resource does, because that resource declares a required matching key; a component of only ConfigMaps, or of a raw `k8s-*` resource, needs none. Confirm the description with the owner before publishing. Link the glossary entries for component, blueprint, resource, trait and unification on first use. No steps, no field tables. Check against: core/src/component.cue, core/src/blueprint.cue, catalog_opm/opm/resources/v1beta1/container.cue, catalog_opm/opm/resources/v1beta1/configmap.cue, catalog_opm/opm/transformers/configmap_transformer.cue 
Kubernetes comparison, only if it helps: weave it into the sentence that introduces the concept, or into How it works, never as a section of its own. Researched candidate: The nearest idea is choosing a workload kind. The five workload blueprints in the opm catalog (`stateless-workload`, `stateful-workload`, `daemon-workload`, `task-workload`, `scheduled-task-workload`) lead to a Deployment, StatefulSet, DaemonSet, Job or CronJob, through the `core.opmodel.dev/workload-type` value each sets. A component is closer to "one workload and everything around it" (the pod spec, its Service, its autoscaler) written as one value. Where it stops: a blueprint is not a kind, it answers a matching key and the kind follows from which transformer then matches; a component is not an object, since several transformers can each emit objects from it; and unlike a pod template, a component's `spec` accepts only the fields its attached pieces define. Check against: catalog_opm/opm/blueprints/v1beta1/stateless_workload.cue, catalog_opm/opm/blueprints/v1beta1/stateful_workload.cue, catalog_opm/opm/blueprints/v1beta1/daemon_workload.cue, catalog_opm/opm/blueprints/v1beta1/task_workload.cue, catalog_opm/opm/blueprints/v1beta1/scheduled_task_workload.cue, catalog_opm/opm/transformers/deployment_transformer.cue, catalog_opm/opm/transformers/statefulset_transformer.cue, catalog_opm/opm/transformers/daemonset_transformer.cue, catalog_opm/opm/transformers/job_transformer.cue, catalog_opm/opm/transformers/cronjob_transformer.cue, core/src/component.cue (`spec`) -->

## How it works

### What a component is made of

<!-- `#Component` carries `#resources`, `#traits` and `#blueprints`, each a map keyed by the member's FQN, plus `metadata.name`, an optional `metadata.resourceName` override, and descriptive `metadata.labels` and `metadata.annotations`. Authors do not write the maps by hand: the catalog ships a wrapper per member (`res.#Container`, `tr.#Expose`, `bp.#StatelessWorkload`) and a component embeds the wrappers it wants. Model the snippet on a first-party module: `bp.#StatelessWorkload` plus `tr.#Expose`, with `res.#Volumes` and `tr.#HttpRoute` attached under a condition. Check against: core/src/component.cue, catalog_opm/opm/resources/v1beta1/container.cue (`#Container`), catalog_opm/opm/traits/v1beta1/expose.cue (`#Expose`), modules/apprise/components.cue -->

### The derivation rule

<!-- The centre of the page. Three things are derived, never authored: `spec` is the closed unification of every attached member's spec (`_allFields`); `matchLabels` is exactly the union of every attached member's `matchLabels` (`_matchLabelsFromPrimitives`); and `#names` computes the object name and the DNS names from `metadata.resourceName` and the instance. A component that adds a matching label of its own fails, even when the key is one a member declared. Illustrate with the matching-label union; leave `matchLabels` versus `metadata.labels` to "How matching works". Check against: core/src/component.cue (`_allFields`, `spec`, `_matchLabelsFromPrimitives`, `_matchLabelsAreDerived`, `#names`) -->

### What a blueprint adds

<!-- `#Blueprint` lists `composedResources` and `composedTraits`, declares one spec key that gathers their fields (`statelessWorkload`, `statefulWorkload`, `daemonWorkload`, `taskWorkload`, `scheduledTaskWorkload`), and sets the concrete `core.opmodel.dev/workload-type` value the `container` resource declares required. The catalog's wrapper attaches the blueprint and its composed members, and copies values from the blueprint's key into each member's own key. A blueprint is itself a versioned contract (`opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1beta1`), like a resource or a trait. Check against: core/src/blueprint.cue, catalog_opm/opm/blueprints/v1beta1/stateless_workload.cue (`#StatelessWorkloadBlueprint`, `#StatelessWorkload`), catalog_opm/opm/catalog.cue (`#blueprints`) -->

### The same component with and without a blueprint

<!-- The teaching device: two snippets side by side (the format of the retired v0 page; none of its facts apply). Left: `res.#Container` plus `tr.#Scaling`, with values under `spec.container` and `spec.scaling`. It fails, because nothing answers the container's required key: `matchLabels."core.opmodel.dev/workload-type": field is required but not present`. Right: `bp.#StatelessWorkload` with the same values under `spec: statelessWorkload:`, which renders a Deployment. One sentence on why: the blueprint is where the workload type is answered. Verify the exact error text and path by building the left-hand component with `opm module build`; the recorded text comes from a core pin that uses a different key name. Check against: core/src/platform_and_match_pins.cue (`_failBareContainer`), catalog_opm/opm/resources/v1beta1/container.cue, catalog_opm/opm/blueprints/v1beta1/stateless_workload.cue, modules/apprise/components.cue -->

## Why it is built this way

### Why the spec is computed

<!-- A component that authored its own spec could contradict the schemas of what it attaches; computing it makes the attached members the single source of schema truth. Keeping the members behind `#resources`, `#traits` and `#blueprints` lets the module definition stay closed, so stray fields are still caught. Check against: core/SPEC.md §3.1 Rationale, "Why `spec` is computed via `_allFields` rather than authored" and "Why the spec is hidden behind `#resources` / `#traits` / `#blueprints` rather than flattened at the Component root" -->

### Why a component cannot set its own matching labels

<!-- The measured story: a written rule that catalog fragments must not declare matching labels went unchecked, which is the defect the check corrects. It binds every component because CUE cannot tell a catalog fragment from an author's component, and `close()` did not refuse an extra key when measured, so the check compares sizes. The cost, no inline answer to a required key, was measured against the module fleet first: no module set a matching label by hand. Check against: core/SPEC.md §3.1 Rationale, "Why the derivation is enforced, and why the rule binds every Component rather than only fragments" and "Why the old claim is deleted rather than corrected" -->

### Why the required key survives into the component

<!-- The union embeds each member's labels whole rather than iterating over them, because CUE refuses to iterate a struct holding an unset required field. Any filtered design would have forced the container to drop its required marker, and a component with no workload type would then render as incomplete instead of failing. Check against: core/SPEC.md §3.1 Rationale, "Why the union is a comprehension over the attachment maps and never over the labels"; core/SPEC.md §2.1 Rationale, "Why matching has its own field instead of riding on `metadata.labels`" -->

### Why a blueprint is versioned like a resource

<!-- A module names a blueprint and writes values under its spec key, so a change to the blueprint breaks the module exactly as a change to a resource would. That earns it an `apiVersion` and a contract key. It carries no `fulfilment`, because no transformer can demand a blueprint. Check against: core/SPEC.md §3.3 Rationale, "Why Blueprints are classified as primitives, having previously sat under Constructs" and "Why Blueprints repeat the primitive-metadata shape of `#Resource` and `#Trait`"; core/SPEC.md §3.3 Constraints (`fulfilment`) -->

### Why each field gets one default

<!-- CUE defaults do not layer: two different defaults on one field cancel, and the field fails at render. So a blueprint may set at most one field-level default, the module author writes defaults only in `#config`, and component fields receive plain data. The precedence of author data over blueprint default over transformer fallback falls out of that. Check against: core/SPEC.md §6.1 Definition; core/SPEC.md §6.4 Rationale, "Why exactly one `*` per field" and "Why the author's layer is `#config`" -->

## Common mistakes

### A container needs a workload blueprint

<!-- The misreading: attaching `res.#Container` is enough for a workload. The container declares `core.opmodel.dev/workload-type` required, and only a workload blueprint answers it, so a bare container fails with a missing required field. Check against: catalog_opm/opm/resources/v1beta1/container.cue, core/src/platform_and_match_pins.cue (`_failBareContainer`) -->

### The workload type comes from the blueprint, not from a label you set

<!-- The misreading: write `matchLabels: "core.opmodel.dev/workload-type": "stateless"` on the component. It fails the derivation check (`_matchLabelsAreDerived: conflicting values false and true`). Setting the key under `metadata.labels` changes nothing about matching. Attach the blueprint. Check against: core/src/component.cue (`_matchLabelsAreDerived`), core/src/platform_and_match_pins.cue (`_failInlineAnsweredMatchLabel`) -->

### Values go under the blueprint's key

<!-- With `bp.#StatelessWorkload` attached, values are written under `spec: statelessWorkload:`, for example `spec: statelessWorkload: container: image: ...`; the wrapper copies them into `spec.container` and the other member keys. Verify what an author sees when writing `spec.container` directly beside the blueprint. Check against: catalog_opm/opm/blueprints/v1beta1/stateless_workload.cue (`#StatelessWorkload`), modules/apprise/components.cue -->

### A blueprint covers the workload, not everything around it

<!-- The stateless blueprint composes scaling, restart policy, update strategy, sidecar containers and init containers. Exposure (`tr.#Expose`), routes (`tr.#HttpRoute`) and, for a stateless workload, volumes (`res.#Volumes`) are attached beside it. Check against: catalog_opm/opm/blueprints/v1beta1/stateless_workload.cue (`composedTraits`), catalog_opm/opm/blueprints/v1beta1/stateful_workload.cue (`composedResources`), modules/apprise/components.cue -->

### A component's spec rejects fields nothing attached defines

<!-- `spec` is closed: a field no attached member defines is refused as not allowed. Attach the trait or resource that defines it. Verify the exact error text. Check against: core/src/component.cue (`spec: close(...)`) -->

### Defaults belong in `#config`

<!-- Writing a `*` default directly on a component field the blueprint already defaults makes the two defaults cancel, and the field fails at render with an error that names neither author. Put the default in `#config` and pass data; for a string, interpolate (`"\(#config.x)"`) to force resolution. Check against: core/SPEC.md §6.3 Constraints (L4, L5) -->

## What enforces this

<!-- One line per rule, each with its badge:
- A component adds no matching label of its own: cue (`_matchLabelsAreDerived`), at `cue vet`.
- Two attached members disagreeing on a matching label: cue (conflicting values).
- An unanswered required matching key: cue, under concrete evaluation only (`cue export`, and so at every OPM render); plain `cue vet` and `cue vet -c` pass it. Verify whether `opm module vet` reports it: it validates `#config` and does not render.
- `spec` accepts only the attached members' fields: cue.
- `metadata.resourceName` is a DNS subdomain and satisfies every attached member's name rule: cue (`#ObjectNameType`, `_nameFits`).
- A component no transformer matches: kernel (`UnmatchedComponentsError`).
- A blueprint carries no `fulfilment`: cue (field not allowed).
- A blueprint files under `.../blueprints/<apiVersion>` and its FQN agrees with the catalog's identity: publish (`#CatalogMemberFQNGate` in `opm catalog publish`).
- `composedResources` is non-empty, a trait in `composedTraits` applies to a composed resource, and both lists agree with what the catalog's wrapper attaches: convention. The specification states the first two as unification failures; core/src/blueprint.cue checks none of them.
- One default per field, and author defaults only in `#config`: convention.
Check against: core/src/component.cue, core/src/blueprint.cue, core/src/types.cue, core/src/platform_and_match_pins.cue, cli/internal/publish/catalog_gates.go, cli/internal/cmd/module/vet.go, library/opm/errors/unmatched.go, core/SPEC.md §3.3 Constraints, core/SPEC.md §6.1 -->
