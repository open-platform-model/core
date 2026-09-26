---
title: "How matching works"
description: "How OPM picks the transformer that renders each component, and the two label sets involved."
type: explanation
sidebar:
  order: 33
---

<!-- Open with OPM as the subject: at render, OPM decides which transformers turn each component into Kubernetes objects, by comparing what each transformer requires with what the component carries. Say early that one component usually matches several transformers, so "the transformer" in the description means the one behind each object. Say what the page leaves to others: the component side in "Components and blueprints", where the transformers come from in "Platforms and catalogs", and each failure's fix in "Unresolved demands", "No matching transformer" and "Over-subscribed provider contracts". Link the glossary entries for transformer, render, FQN and matching labels on first use. No steps, no field tables. Check against: core/src/transformer.cue, library/opm/internal/renderstage/render.cue.tmpl, library/opm/kernel/doc.go ("Rendering") 
Kubernetes comparison, only if it helps: weave it into the sentence that introduces the concept, or into How it works, never as a section of its own. Researched candidate: Compare with label selectors: a Service's `spec.selector` picks Pods by their labels. A transformer's `requiredLabels` plays the selector, and the component's `matchLabels` is the label set being selected. Where the comparison stops: (1) the names are the reverse of Kubernetes, where `selector.matchLabels` is the query; in OPM `matchLabels` is what gets matched; (2) labels are one of three conditions, beside required resources and required traits named by FQN; (3) matching runs once, inside the render, over components rather than live objects, and `matchLabels` never reach the cluster; (4) several transformers can match one component, each emitting its own objects. Check against: core/src/transformer.cue (`requiredLabels`, `requiredResources`, `requiredTraits`), core/src/component.cue (`matchLabels`), library/opm/internal/renderstage/render.cue.tmpl (`#Match`) -->

## How it works

### Two label sets on a component

<!-- `matchLabels` is the component's matching identity: derived from what it attaches, read only by matching, never rendered. `metadata.labels` is descriptive: not derived, never matched on, and copied onto every rendered object through `#TransformerContext.componentLabels`, including the workload's `spec.selector.matchLabels`, which Kubernetes makes immutable. The opm catalog matches on one key today, `core.opmodel.dev/workload-type`, with the values `stateless`, `stateful`, `daemon`, `task` and `scheduled-task`. Verify: the catalog's `#Container` and workload wrappers also write `core.opmodel.dev/workload-type` into `metadata.labels` (a comment there calls it transitional), so rendered objects and their selectors do carry that key today, although the specification says rendered objects stopped carrying it. Check against: core/src/component.cue, core/src/transformer.cue (`#TransformerContext`), catalog_opm/opm/resources/v1beta1/container.cue (`#Container`), catalog_opm/opm/blueprints/v1beta1/stateless_workload.cue (`#StatelessWorkload`), catalog_opm/opm/transformers/deployment_transformer.cue (`selector`), catalog_opm/opm/traits/v1beta1/pod_metadata.cue, core/SPEC.md §2.1 Rationale, "Why `matchLabels` is not rendered" -->

### What a transformer declares

<!-- `requiredLabels`, `requiredResources` and `requiredTraits` are the conditions; `optionalResources` and `optionalTraits` name what the transformer can use without needing. Use two real transformers: the Deployment transformer requires the `container` resource and `core.opmodel.dev/workload-type: stateless`, and lists `scaling`, `restart-policy` and others as optional traits; the HPA transformer requires `container` and the `scaling` trait and no label. Verify: `optionalLabels` is declared on `#ComponentTransformer`, but the render glue never reads it. Check against: core/src/transformer.cue, catalog_opm/opm/transformers/deployment_transformer.cue, catalog_opm/opm/transformers/hpa_transformer.cue -->

### The three checks

<!-- For each component: (1) candidates: only transformers that name one of the component's resource or trait FQNs, required or optional, are considered; (2) unify: at every FQN both sides carry, the component's copy is unified with the transformer's, and a conflict disqualifies that candidate; (3) predicate: every required label is present in `matchLabels` with the same value, and every required resource and trait is attached. A candidate passing both checks forms a matched pair. A small diagram of the three steps fits here. Check against: library/opm/internal/renderstage/render.cue.tmpl (`_bucketsResources`, `_bucketsTraits`, `_unify`, `_pred`, `_candidates`, `matched`) -->

### One component, several transformers

<!-- A stateless workload with `expose` and automatic scaling matches the Deployment, Service and HPA transformers; each emits its own object, and every matched pair renders. Check against: catalog_opm/opm/transformers/deployment_transformer.cue, catalog_opm/opm/transformers/service_transformer.cue, catalog_opm/opm/transformers/hpa_transformer.cue, library/opm/internal/renderstage/render.cue.tmpl (`rendered`) -->

### Verdicts and the gate

<!-- Every attached resource and trait is a demand. A demand is satisfied when some candidate in its bucket passes both checks; a trait also counts as handled when any matched transformer lists it as optional. The render is refused on three verdicts, each a typed error: an unresolved demand (`UnresolvedDemandsError`, whose message tells apart "implemented at a different apiVersion", "defined by <catalog> and nothing on this platform implements it" and "no enabled catalog defines this contract"), an unmatched component (`UnmatchedComponentsError`, listing each candidate's missing labels), and a provider contract supplied by more than one catalog (`OverSubscribedContractsError`). An unhandled advisory trait is a warning, and unify conflicts are reported as rows. Check against: library/opm/internal/renderstage/render.cue.tmpl (`unresolved`, `unmatched`, `warnings`, `unifyFailures`, `guard`, `gate`), library/opm/kernel/render_decode.go (`gateErrors`), library/opm/errors/match.go, library/opm/errors/unmatched.go, library/opm/errors/oversubscribed.go -->

### Where matching runs

<!-- Matching is split between core and the library. `core` defines both sides and the transformer set: `#Component.matchLabels`, the demand maps on `#ComponentTransformer`, and `#Platform.#composedTransformers`. For each render the library kernel generates one CUE module that imports the instance and the platform; matching is CUE inside that single build (`#Match`), and Go only decodes the verdicts and turns them into errors. There is no Go matcher. Check against: core/src/component.cue, core/src/transformer.cue, core/src/platform.cue (`#composedTransformers`), library/opm/internal/renderstage/render.cue.tmpl, library/opm/internal/renderstage/doc.go, library/opm/kernel/render_decode.go -->

## Why it is built this way

### Why matching has its own label field

<!-- The measured story: matching once rode on `metadata.labels`, and folding those upward from every member cannot work, because categorisation labels legitimately differ (`resource.opmodel.dev/category` is `workload` on the container and `storage` on volumes) and conflict on the first real component. A filter would have had to iterate, and iterating loses the required marker. A separate field removed all of that, and gave the transformer's demand and the component's supply the same shape. Check against: core/SPEC.md §2.1 Rationale, "Why matching has its own field instead of riding on `metadata.labels`"; core/SPEC.md §4.1 Rationale, "Why the label predicate reads `matchLabels` and not `metadata.labels`"; core/SPEC.md §3.1 Rationale, "Why matching identity unifies upward but `metadata.labels` does not" -->

### Why matching labels are never rendered

<!-- They choose a transformer; they do not describe the objects it emits. Rendering them would publish a catalog's matching vocabulary onto every live object. Check against: core/SPEC.md §2.1 Rationale, "Why `matchLabels` is not rendered" -->

### Why the catalog names the keys

<!-- `core` names no matching key, so a catalog can introduce one without a `core` release; the constant `core` used to export for it had no readers. The specification's example key (`opm.opmodel.dev/workload-type`) differs from the key catalog_opm ships (`core.opmodel.dev/workload-type`); write the shipped one. Check against: core/SPEC.md §2.1 Rationale, "Why `core` names no matching key"; catalog_opm/opm/resources/v1beta1/container.cue -->

### Why an unmet demand fails the render

<!-- The measured story: a component carrying a container and a backup trait, on a platform with no backup provider, used to match the Deployment transformer, render successfully, and have no backup. Making every demand required by default turns that into a render that names the trait. Check against: core/SPEC.md §3.1 Rationale, "Why an unmet demand is an error at all" -->

### Why matching always unifies

<!-- The component and the transformer may have been built against different catalog builds; unifying their copies at every shared FQN reports drift as a named conflict per component and FQN, instead of a render-time mystery. Check against: core/SPEC.md §4.1 Rationale, "Why match is key-driven and always unifies" -->

### Why matching runs inside the CUE build

<!-- A Go matcher and the platform field it filled were both removed, so the schema and the render cannot compute two different answers; the matcher builds its own index from the platform's transformer set inside one build. Check against: core/SPEC.md §3.4 Rationale, "Why `#matchers` is removed rather than derived" and "Why `#composedTransformers` stops being kernel-filled"; library/opm/kernel/doc.go ("Rendering") -->

## Common mistakes

### `matchLabels` is the label set, not the selector

<!-- Kubernetes readers see `matchLabels` and think of a selector. In OPM the selector is the transformer's `requiredLabels`, and `matchLabels` is the component's side. Check against: core/src/component.cue (`matchLabels`), core/src/transformer.cue (`requiredLabels`) -->

### A component's `metadata.labels` do not affect matching

<!-- They reach the rendered objects and the workload selectors, never the matcher. Because they land in `spec.selector.matchLabels`, changing them after the first apply changes a selector Kubernetes treats as immutable; pod-only labels go through the `pod-metadata` trait instead. Verify the rejected-update behaviour against a live apply. Check against: core/src/transformer.cue (`componentLabels`), catalog_opm/opm/transformers/deployment_transformer.cue (`selector`), catalog_opm/opm/traits/v1beta1/pod_metadata.cue -->

### A component can match more than one transformer

<!-- Matching is not "one component, one object". Every transformer whose checks pass renders, and each emits its own kinds. Check against: library/opm/internal/renderstage/render.cue.tmpl (`matched`, `pairs`, `rendered`) -->

### `opm module vet` does not run matching

<!-- `opm module vet` checks the module's identity and validates `#config` against `debugValues` or `-f` files; it does not render. Matching verdicts appear at `opm module build`, `opm module apply`, `opm instance vet`, `opm instance build`, `opm instance diff` and `opm instance apply`, and in the operator's reconcile. Check against: cli/internal/cmd/module/vet.go, cli/internal/cmd/instance/vet.go, cli/internal/cmd/module/build.go, cli/internal/cmd/instance/diff.go -->

### A missing transformer fails the render

<!-- Nothing is skipped silently except an advisory trait, which warns. A missing transformer for a resource, or for a trait resolved `optional: false`, refuses the whole render. Check against: library/opm/kernel/render_decode.go (`gateErrors`), library/opm/internal/renderstage/render.cue.tmpl (`unresolvedResources`, `unresolvedTraits`) -->

## What enforces this

<!-- One line per rule, each with its badge:
- A component's matching labels are exactly what it attaches: cue (`_matchLabelsAreDerived`).
- Two attached members disagreeing on a matching label: cue (conflicting values).
- An unanswered required matching key: cue, under concrete evaluation only, so it surfaces at render rather than at plain `cue vet`.
- `requiredLabels` are compared with `matchLabels`, never with `metadata.labels`: kernel (the render glue).
- An unresolved demand, an unmatched component, a provider contract supplied by two catalogs: kernel (render refused).
- An unhandled advisory trait: kernel, warning only.
- A unify conflict on a candidate: kernel, reported and the candidate disqualified.
- `matchLabels` never reach a rendered object: cue (`#TransformerContext` has no path from them). Verify against the catalog wrappers' copy in `metadata.labels` noted above.
- Two transformers where one matches every component the other does, over a shared catalog contract: reported by `#Platform.#contracts.comparable`, and `opm platform check` exits with the validation error code. Verify which badge fits a platform check; nothing in opm-operator refuses on it.
Check against: core/src/component.cue, core/src/transformer.cue, core/src/platform.cue (`#ContractInventory`), library/opm/internal/renderstage/render.cue.tmpl, library/opm/kernel/render_decode.go, library/opm/platform/contracts.go, cli/internal/cmd/platform/check.go -->
