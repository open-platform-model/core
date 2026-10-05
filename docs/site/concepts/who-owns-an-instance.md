---
title: "Who owns an instance"
description: "The difference between an instance the CLI manages and one the controller manages."
type: explanation
weight: 37
---

<!-- Open with OPM as the subject: every deployed instance is managed by exactly one of two actors, the `opm` CLI or the OPM controller, and the ModuleInstance's `spec.owner` records which. The page explains what each actor does for the instances it owns, what the other actor does with them, and what that changes when you apply, delete or inspect. Say once, plainly, that no command moves an instance from one owner to the other; describe no transfer. Assumes Modules and instances; links Deletion and pruning and Delete an instance safely for the full deletion story. Check against: cli/README.md (CLI-managed vs controller-managed instances), cli/internal/inventory/ownership.go, opm-controller/api/v1alpha1/moduleinstance_types.go 
Kubernetes comparison, only if it helps: weave it into the sentence that introduces the concept, or into How it works, never as a section of its own. Researched candidate: Nearest idea: a Job's `spec.managedBy`, which tells the built-in Job controller to leave that Job to another controller. `spec.owner: cli` works the same way: the controller sees the ModuleInstance and deliberately does nothing but mark it. State the purpose without a tool comparison: the owner field stops the CLI and the controller from both managing one instance. Where it stops: a ModuleInstance exists in both modes and is the record for both actors; a CLI-managed one works with only the CRDs installed and no controller running, and it carries no finalizer, so it is a plain record rather than an object a controller guards. Verify: whether Job `spec.managedBy` is immutable, before contrasting it with `spec.owner`, which carries no validation rule beyond its enum. Check against: opm-controller/api/v1alpha1/moduleinstance_types.go, opm-controller/config/crd/bases/opmodel.dev_moduleinstances.yaml, opm-controller/internal/reconcile/moduleinstance.go (handleCLIOwned) -->

## How it works

<!-- One diagram of one ModuleInstance and its two branches. `spec.owner: cli`: the CLI renders, applies as field manager `opm-cli`, prunes and writes `status.inventory`; the controller, if installed, only sets `Ready=Unknown` with reason `ManagedExternally`. `spec.owner: controller` or absent: the CLI writes `spec.module` and `spec.values` and waits; the controller adds its finalizer, renders, applies as field manager `opm-controller`, prunes and writes status. Check against: cli/internal/workflow/apply/apply.go, cli/internal/workflow/apply/thineditor.go, cli/internal/inventory/store.go, cli/internal/kubernetes/labels.go, opm-controller/internal/reconcile/moduleinstance.go, opm-controller/internal/apply/manager.go -->

### How the owner is decided

<!-- `spec.owner` takes `cli` or `controller` and has no default in the CRD. `opm instance apply` and `opm module apply` write `spec.owner: cli` when they create a ModuleInstance and never rewrite an existing owner. A ModuleInstance created any other way (kubectl, a GitOps tool) without the field is controller-managed: the controller and the CLI both treat absent, empty and `controller` the same, and only an explicit `cli` makes the CLI the executor. `opm instance list` shows each instance's owner in its OWNER column. Check against: opm-controller/api/v1alpha1/moduleinstance_types.go, cli/internal/inventory/ownership.go (ResolveOwnership, DisplayOwner), cli/internal/workflow/apply/apply.go (WriteInstanceRecord), cli/internal/cmd/module/apply.go, cli/internal/workflow/query/list.go -->

### A CLI-managed instance

<!-- The CLI is the whole reconciler, once, each time you run it: it renders through the kernel, applies with server-side apply as `opm-cli`, prunes objects the new render dropped (unless `--no-prune`), and records the inventory, the instance uuid and the last-applied digests on the ModuleInstance's status. It needs the CRDs (`opm controller install --crds-only`) but no controller. Before applying it checks that the ModuleInstance CRD exists and has `spec.owner` and `status.inventory`, that the cluster's controller, if any, is not newer than the CLI, and that you may patch `moduleinstances/status` in the namespace. It picks the platform in order: `--platform`, the cluster Platform, then a platform generated from the render's own dependency pins (the instance package's `cue.mod/module.cue`, the module's for `opm module apply`), and prints which one it used. An apply never creates a cluster Platform; only `opm controller install` seeds one. Under `--skip-unprovided` it records the provider-fulfilled contracts it skipped on the ModuleInstance as the annotation `module-instance.opmodel.dev/skipped-contracts` (`<component>=<fqn>` pairs), cleared by the next apply that skips nothing. Rendered objects carry `app.kubernetes.io/managed-by: opm-cli`. Nothing runs between invocations, so changes made to live objects stay until the next apply; `opm instance diff` shows them. Check against: cli/internal/workflow/apply/apply.go (RunClusterGates, GateStatusRBAC call, WriteInstanceRecord), cli/internal/inventory/gates.go, cli/internal/cmd/instance/apply.go, cli/internal/platform/resolve.go, cli/internal/inventory/cr.go (AnnotationSkippedContracts), cli/internal/workflow/render/env.go, opm-controller/internal/reconcile/moduleinstance.go (handleCLIOwned) -->

### A controller-managed instance

<!-- The controller adds its `opmodel.dev/cleanup` finalizer, fetches `spec.module.path` at `spec.module.version` from the registry, renders against the cluster Platform, applies as `opm-controller`, prunes only when `spec.prune` is true, reports drift as the `Drifted` condition, and reports failures on `Ready` with reasons such as `ResolutionFailed`, `RenderFailed` and `SkewRefused`. Rendered objects carry `app.kubernetes.io/managed-by: opm-controller`. Against it, `opm instance apply` writes only `spec.module` and `spec.values`, restates the existing `spec.owner`, waits for the controller's reconcile (`--timeout`, default 5m) and reports the outcome; it refuses a module that resolved from local files, because the controller can only fetch published modules, and it refuses `--skip-unprovided`, because the controller never skips a demand. Verify: whether the controller corrects drift or only reports it. Check against: opm-controller/internal/reconcile/moduleinstance.go, opm-controller/internal/reconcile/resolution.go, opm-controller/internal/status/conditions.go, opm-controller/internal/apply/drift.go, cli/internal/workflow/apply/thineditor.go, cli/internal/inventory/reconcile.go -->

### Deleting depends on the owner

<!-- The two paths differ, and this is where the wrong assumption loses state. Keep it short and link Deletion and pruning and Delete an instance safely. CLI-managed: `opm instance delete` deletes every tracked object and then the ModuleInstance; because the ModuleInstance has no finalizer, `kubectl delete moduleinstance` removes the only inventory and leaves every object running, and `opm instance delete` then reports the instance as not found. Controller-managed: `opm instance delete` refuses unless the controller is running, deletes the ModuleInstance and waits for the finalizer, which deletes the objects only when `spec.prune` is true; `spec.prune` is false unless someone set it and the CLI never sets it, so by default the objects keep running and the CLI says so. Check against: cli/internal/cmd/instance/delete.go, cli/internal/workflow/query/status.go (ResolveInventory), opm-controller/internal/reconcile/moduleinstance.go (handleDeletion, handleCLIOwned), opm-controller/api/v1alpha1/moduleinstance_types.go -->

## Why it is built this way

<!-- Rationale source: the archived CLI and controller integration design. Rewrite without decision numbers and drop every mention of handing an instance over, which was removed. Check against: enhancements/archive/0006/03-decisions.md -->

### Why both actors share one ModuleInstance

<!-- One record of what is deployed, read by both actors, rather than a CLI store beside the controller's. The CLI writes the inventory itself because a cluster with only the CRDs has no controller to write it. It writes only the status fields it can stand behind (inventory, instance uuid, last-applied digests) and never conditions, which belong to the controller. Check against: cli/internal/inventory/record.go, cli/internal/inventory/store.go, cli/internal/workflow/apply/apply.go (WriteInstanceRecord), opm-controller/internal/reconcile/moduleinstance.go (handleCLIOwned) -->

### Why ownership is an explicit field in the spec

<!-- Without a marker, a controller running in the cluster would reconcile a ModuleInstance the CLI created and fight the CLI over the same objects. `spec.suspend` was not reused because pausing and belonging to the CLI are different intents, and status was not used because spec holds what a user asked for while status can be lost in a backup and restore. Check against: opm-controller/api/v1alpha1/moduleinstance_types.go, enhancements/archive/0006/03-decisions.md (the spec.owner decision) -->

### Why the controller adds no finalizer to a CLI-managed instance

<!-- The finalizer's cleanup deletes the objects in the inventory, and for a CLI-managed instance those belong to the CLI. The owner check runs before the controller registers its finalizer, so a CLI-managed ModuleInstance never carries one. The cost is the deletion hazard described above. Check against: opm-controller/internal/reconcile/moduleinstance.go (owner-skip gate comment) -->

### Why the CLI edits a controller-managed instance instead of refusing

<!-- One `opm instance apply` works against either owner, and only what happens underneath changes. The line sits at execution: the CLI may write the spec, never the objects or the status, so two actors never apply the same objects. The refusal of local module files exists because the controller renders only what it can fetch from a registry. Check against: cli/internal/workflow/apply/thineditor.go, cli/internal/inventory/ownership.go -->

### Why the CLI can render without the cluster's platform

<!-- The CLI reads the cluster Platform when it can, so it renders the way the controller would, and falls back to a platform generated from the render's own dependency pins so that someone who cannot read the cluster-scoped Platform can still apply into their own namespace. A cluster without the controller is supported for basic modules; a module whose provider-fulfilled traits have no provider there renders the rest with `--skip-unprovided`. Check against: cli/internal/platform/resolve.go, enhancements/archive/0006/03-decisions.md (the platform-source decisions) -->

## Common mistakes

### No command moves an instance between owners

<!-- Misreading: an instance deployed with the CLI can be given to the controller later with an OPM command. Correct: the owner is set when the ModuleInstance is created, and no CLI command changes it. Do not describe editing `spec.owner` by hand: the CRD does not stop it, but OPM supports no such path and its outcome is untested. Check against: cli/README.md, cli/internal/inventory/ownership.go, opm-controller/config/crd/bases/opmodel.dev_moduleinstances.yaml -->

### A ModuleInstance with no owner is controller-managed

<!-- Misreading: a ModuleInstance applied with kubectl and no `spec.owner` is unmanaged, or belongs to whoever created it. Correct: absent or empty means controller; the controller adds its finalizer and reconciles it. Check against: opm-controller/internal/reconcile/moduleinstance.go, cli/internal/inventory/ownership.go -->

### `ManagedExternally` is not a fault

<!-- Misreading: `Ready=Unknown` with reason `ManagedExternally` means the controller failed on the instance. Correct: the controller is recording that it skipped a CLI-managed instance on purpose; the CLI's own record is `status.inventory` and the last-applied fields, which `opm instance status` reads. Check against: opm-controller/internal/status/conditions.go (MarkManagedExternally), cli/internal/workflow/query/status.go -->

### A CLI-managed instance still needs the CRDs

<!-- Misreading: the CLI path needs nothing installed in the cluster. Correct: the CLI records the instance on a ModuleInstance, so the CRDs must be present (`opm controller install --crds-only`); the controller is optional. Check against: cli/internal/inventory/gates.go (GateCRDPresent, GateCRDFieldFloor), cli/internal/cmd/controller/install.go -->

### `spec.prune` is read by the controller only

<!-- Misreading: `spec.prune` controls pruning for every instance. Correct: the controller reads it both when a new render drops objects and when the ModuleInstance is deleted, so a controller-managed instance with `spec.prune` unset leaves dropped objects running. The CLI never reads it for its own apply; it prunes unless run with `--no-prune`, and reads the field only to report what a controller-managed delete will do. Check against: opm-controller/internal/reconcile/moduleinstance.go, cli/internal/cmd/instance/apply.go, cli/internal/cmd/instance/delete.go, cli/internal/inventory/record.go -->

## What enforces this

<!-- Verify with the author how to badge these rules: they are enforced by the CLI's commands and the controller's reconciler, and the badge vocabulary (cue, kernel, publish, convention) has no entry for either. The rules: `spec.owner` accepts only `cli` or `controller` (the CRD enum, checked by the Kubernetes API server); the controller skips a ModuleInstance with `spec.owner: cli` and adds no finalizer to it; `opm instance apply` writes `cli` on create and never rewrites an owner; against a controller-managed instance the CLI writes only the spec and refuses local module files and `--skip-unprovided`; `opm instance delete` refuses a controller-managed delete while the controller is not running; the CLI refuses to apply when the CRD lacks `spec.owner` or `status.inventory`, or when the cluster's controller is newer than the CLI. Convention, since nothing stops it: never delete a CLI-managed ModuleInstance with kubectl. Check against: opm-controller/config/crd/bases/opmodel.dev_moduleinstances.yaml, opm-controller/internal/reconcile/moduleinstance.go, cli/internal/workflow/apply/apply.go, cli/internal/workflow/apply/thineditor.go, cli/internal/cmd/instance/delete.go, cli/internal/inventory/gates.go, cli/internal/controller/ready.go -->
