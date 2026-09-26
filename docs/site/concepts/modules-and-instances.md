---
title: "Modules and instances"
description: "How a module you write becomes an instance running on a cluster."
type: explanation
sidebar:
  order: 30
---

<!-- Open with OPM as the subject, in one or two sentences: a module is a versioned, published description of an application, and an instance is one configured deployment of it, with a name, in one namespace. Say what the page leaves to other pages: identity formulas to "Identity and names", the version numbers to "Versions in OPM", CLI versus operator ownership to "Who owns an instance", deletion to "Deletion and pruning". Link the glossary entries for module, instance, component and CUE on first use. No steps, no field tables. Check against: core/src/module.cue, core/src/module_instance.cue, core/SPEC.md §3.2 and §3.5 Definition 
Kubernetes comparison, only if it helps: weave it into the sentence that introduces the concept, or into How it works, never as a section of its own. Researched candidate: Compare with a Helm chart and a Helm release: a module is the packaged, versioned chart published to an OCI registry, an instance is one installed, configured copy with a name in one namespace. Where the comparison stops: (1) values are unified with the module's `#config` schema before anything renders, so a misspelled or mistyped field fails instead of being templated; (2) there are no templates: `#components` is data, and transformers from the platform's catalogs turn it into objects; (3) the instance's identity is computed from the module's registry path without its major, the instance name and the namespace, so it survives every upgrade of the module; (4) an instance exists in two forms, the `#ModuleInstance` CUE value that renders and the `ModuleInstance` custom resource (`opmodel.dev/v1alpha1`) that records it on the cluster. Check against: core/src/module_instance.cue, core/SPEC.md §3.5 Constraints, opm-operator/api/v1alpha1/moduleinstance_types.go, library/opm/kernel/validate.go -->

## How it works

<!-- One diagram: a published module (`<path>@vN`, tagged with a SemVer version) plus values, a name and a namespace becomes an instance; the instance renders against a platform into Kubernetes objects; the cluster keeps a ModuleInstance record. Check against: core/src/module_instance.cue, library/opm/kernel/doc.go ("Rendering") -->

### A module is a published package

<!-- A module is a CUE module with four parts: `cue.mod/module.cue`; `identity/identity.cue` holding `ModulePath` and `Version`; `module.cue` with `metadata`, `#config` and `debugValues`; and `components.cue` with `#components`. `#config` is the configuration schema, and the only place a module author writes defaults (`*` values). `#components` maps component names to components. `debugValues` is example data for local iteration, not defaults. `metadata.modulePath` carries the major (`example.com/modules/my_app@v0`) and `metadata.name` is snake_case and equals the path's last segment. `opm module init <path@vN>` scaffolds one; `opm module publish` publishes from committed source, and a published version is never replaced. Check against: core/src/module.cue, cli/QUICKSTART.md ("Scaffold"), cli/internal/cmd/module/init.go, cli/internal/cmd/module/publish.go, cli/internal/publish/gates.go -->

### An instance binds a module to values, a name and a namespace

<!-- `#ModuleInstance` takes `#module` (the imported module), `metadata.name`, `metadata.namespace`, `metadata.clusterDomain` (default `cluster.local`) and `values`. The values are unified into the module's `#config`; the resulting `components` are the module's `#components`, each given the instance identity through `#ctx.instance` and `#instance`, which is how a component's default object name becomes `<instance>-<component>`. Use cli/examples/instances/podinfo/instance.cue as the snippet: it imports `opmodel.dev/core@v2`, embeds `core.#ModuleInstance`, sets `metadata` and `#module`, and keeps `values` in a sibling `values.cue`. Do not copy the instance snippet in cli/QUICKSTART.md: its import `opmodel.dev/core/v1alpha1/modulerelease@v1` is stale. Check against: core/src/module_instance.cue, core/src/module.cue (`#components`, `#ctx`), core/src/component.cue (`resourceName`, `#names`), cli/examples/instances/podinfo/instance.cue, cli/examples/instances/podinfo/values.cue -->

### Three ways an instance reaches a cluster

<!-- (1) The CLI renders and applies it: `opm instance apply <instance.cue>` for an authored instance file, or `opm module apply [path]`, which synthesises an instance around module source (values from `debugValues` or `-f`, name `<module>-debug` unless `--name` is given). Either way the CLI applies the objects itself and records a `ModuleInstance` with `spec.owner: cli`. (2) The operator reconciles a `ModuleInstance` created some other way: it fetches the published module named by `spec.module.path` and `spec.module.version`, takes `spec.values`, and renders it. (3) The operator renders a `ModulePackage`: a Flux source (`spec.sourceRef`) whose `spec.path` directory holds an authored `instance.cue`. State plainly that no command moves an instance between the CLI and the operator, and point to "Who owns an instance". Verify: the synthetic name is `<module.metadata.name>-debug`, and a snake_case module name containing `_` gives a name `#NameType` rejects unless `--name` is passed. Check against: cli/README.md ("CLI-managed vs operator-managed instances"), cli/internal/cmd/instance/apply.go, cli/internal/cmd/module/apply.go, cli/internal/workflow/render/module.go (`syntheticIdentity`), core/src/types.cue (`#NameType`), opm-operator/api/v1alpha1/moduleinstance_types.go, opm-operator/api/v1alpha1/common_types.go (`ModuleReference`), opm-operator/api/v1alpha1/modulepackage_types.go, opm-operator/internal/render/kernel_module_renderer.go, opm-operator/internal/render/kernel_package_renderer.go -->

### What a rendered object carries from its instance

<!-- What a reader sees in `kubectl get -o yaml`: `module-instance.opmodel.dev/name` and `module-instance.opmodel.dev/uuid` (the ownership label the prune step compares), the module's `module.opmodel.dev/name`, `module.opmodel.dev/version` and `module.opmodel.dev/uuid`, and `app.kubernetes.io/managed-by` set to `opm-cli` or `opm-controller`. Keep the identity formulas on "Identity and names". Check against: core/src/module_instance.cue (`metadata.labels`), core/src/module.cue (`metadata.labels`), core/src/transformer.cue (`#TransformerContext`), cli/internal/workflow/render/env.go (`RuntimeName`), opm-operator/pkg/core/labels.go (`LabelManagedByControllerValue`) -->

## Why it is built this way

### Why a module and its values are separate

<!-- One module is deployed many times, into different namespaces with different values, without forking it: the instance identity is injected by the module into every component rather than written on the component. Compare Helm's chart and values, and say that OPM makes the split a type boundary rather than a file convention. Check against: core/SPEC.md §3.5 Definition; core/SPEC.md §3.1 Rationale, "Why `#instance` is hidden and module-injected, not author-supplied"; core/SPEC.md §3.2 Rationale, "Why the `#components` pattern injects `#instance` instead of leaving it for `#ModuleInstance`" -->

### Why the configuration schema stays plain data

<!-- `#config` is the module's public contract and travels with the published module, so it has to stay expressible as OpenAPI v3 with no CUE comprehensions, for tools that do not run CUE (form UIs, kubectl plugins, generated bindings). Say that nothing checks this today (see What enforces this). Check against: core/SPEC.md §3.2 Rationale, "Why `#config` is bare `_` and not a typed schema" and "Why no CUE templating in `#config`" -->

### Why an instance is one value with no builder

<!-- The instance wires its name, namespace, uuid and cluster domain into the module inline, so module plus instance is a single CUE value with no evaluation order and no context-building step. Check against: core/SPEC.md §3.5 Rationale, "Why `#ModuleInstance` sets `#ctx.instance` inline and ships no builder" and "Why `clusterDomain` lives on `#InstanceIdentity` and not buried inside a runtime context type" -->

### Why instance identity ignores the module version

<!-- The measured failure: while instance identity moved with every module release, the ownership label on live objects stopped matching after an upgrade, and the operator's prune skipped deletes it should have made while reporting success. Identity is now computed from the module's registry path without its major, the instance name and the namespace. State only the consequence for upgrades here; the formula belongs on "Identity and names". Check against: core/SPEC.md §3.5 Rationale, "Why instance identity derives from the module's `registryPath` and not from its `fqn` or `uuid`" and "Why `uuid` is computed deterministically from module + name + namespace"; core/SPEC.md §3.2 Rationale, "Why `fqn` is a field rather than a recombination, and why the version left it" -->

### Why default object names include the instance name

<!-- `<instance>-<component>` follows Helm's `<release>-<chart>` convention, so two instances of one module in one namespace do not overwrite each other's objects. Check against: core/SPEC.md §3.1 Rationale, "Why the default is `<instance>-<component>` rather than the bare component name" -->

## Common mistakes

### `debugValues` are not defaults

<!-- Readers take `debugValues` for a values.yaml of defaults. It is example data that `opm module vet`, `opm module build` and `opm module apply` use when no `-f` file is given; an instance file never reads it, and the kernel never falls back to it. Defaults are `*` values inside `#config`. Check against: core/src/module.cue (`debugValues`), library/opm/module/module.go, library/opm/kernel/synth.go, cli/internal/cmd/module/vet.go, cli/internal/workflow/render/module.go -->

### The `ModuleInstance` resource is a record, not the thing that renders

<!-- The custom resource is the cluster's record: owner, inventory, status, and for an operator-owned instance the desired module path, version and values. The CUE `#ModuleInstance` is the value that renders. A CLI-owned resource carries `spec.module` too, but the operator does not act on it while `spec.owner` is `cli`. Check against: opm-operator/api/v1alpha1/moduleinstance_types.go (`OwnerCLI`, `ModuleInstanceSpec`), core/src/module_instance.cue, cli/README.md -->

### The operator deploys only published modules

<!-- `spec.module` holds a registry path and a version and nothing else, so a module on local disk cannot reach an operator-owned instance, and `opm instance apply` refuses one against an operator-managed instance. Iterate locally with `opm module build` or a CLI-owned instance. Check against: opm-operator/api/v1alpha1/common_types.go (`ModuleReference`), cli/README.md ("CLI-managed vs operator-managed instances") -->

### `app.kubernetes.io/instance` holds the component name

<!-- Helm users expect this label to hold the release name. OPM sets it, and `app.kubernetes.io/name`, to the component's name; the instance name is on `module-instance.opmodel.dev/name`. Select an instance's objects by that label. Check against: core/src/transformer.cue (`controllerLabels`, `componentLabels`) -->

### Upgrading the module keeps the same instance

<!-- Bumping the module version, even to a new major path, keeps the instance's uuid, so the ownership label on live objects still matches after the upgrade. A different instance name or namespace is a different instance. Check against: core/src/module_instance.cue (`metadata.fqn`, `metadata.uuid`), core/src/identity_pins.cue -->

### Deleting the record does not always delete the workloads

<!-- Two sentences and a pointer to "Deletion and pruning": `spec.prune` has no default and the CLI does not write it, so an operator-owned delete leaves workloads running unless `spec.prune` is `true`; and a CLI-owned instance carries no finalizer, so `kubectl delete` on its resource removes the only inventory record. Do not restate the full rules. Check against: cli/README.md (the `spec.prune` note), opm-operator/api/v1alpha1/moduleinstance_types.go (`Prune`, `OwnerCLI`) -->

## What enforces this

<!-- One line per rule, each with its badge:
- `metadata.modulePath` ends in `@vN`: cue (`#ModulePathType`).
- `metadata.name` is snake_case and equals the path's last segment: cue (`#SnakeNameType`, the hidden `_leaf` check).
- The version's major agrees with the path's major: publish (`#IdentityPackage.VersionMajor`, unified by `opm module publish`; `opm module vet` runs the same identity check).
- A published version is never republished: publish (the tag-exists gate).
- Values satisfy `#config`, with no stray fields: cue (unification inside `#ModuleInstance`) and kernel (the closed-schema disallowed-field walk), surfacing at `opm module vet`, `opm instance vet`, build and apply.
- Instance name and namespace are DNS labels: cue (`#NameType`).
- Components receive the instance identity, and an author setting `#instance` conflicts: cue.
- `#config` stays OpenAPI-expressible with no comprehensions: convention. The specification says the render pipeline enforces it; no such check exists in library/opm.
Check against: core/src/types.cue, core/src/module.cue, core/src/module_instance.cue, core/src/identity_package.cue, cli/internal/publish/gates.go, cli/internal/publish/identity.go, cli/internal/cmd/module/vet.go, library/opm/kernel/validate.go, core/SPEC.md §3.2 Constraints -->
