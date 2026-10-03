---
title: "Modules and instances"
description: "How a module you write becomes an instance running on a cluster."
type: explanation
weight: 30
---

Open Platform Model (OPM) separates what an application is from where it runs. A module is a versioned description of an application, written in CUE and published to an OCI registry. A module instance is one configured copy of that module, with a name, in one namespace. You publish a module once and create an instance for every place you deploy it. OPM's terms, including component and CUE, are defined in the [Glossary](/docs/reference/glossary/).

The instance holds your values, and OPM unifies them with the module's configuration schema. Nothing is substituted into a template. A wrong type in a setting the module uses fails the render, before anything reaches the cluster. A module has no templates at all: its components are data, and the transformers in the platform's catalogs turn them into Kubernetes objects. OPM computes the instance's identity from the module path without its major version, the instance name and the namespace, so the identity survives every upgrade of the module. An instance exists in two forms: the `#ModuleInstance` CUE value that renders, and the `ModuleInstance` custom resource (`opmodel.dev/v1alpha1`) that records it on the cluster.

This page explains what a module and an instance hold, how an instance reaches a cluster, and why OPM splits them this way. The identity formulas are on [Identity and names](/docs/concepts/identity-and-names/), and version numbers on [Versions in OPM](/docs/concepts/versions/). Whether the CLI or the operator manages an instance is on [Who owns an instance](/docs/concepts/who-owns-an-instance/), and deletion is on [Deletion and pruning](/docs/operating/deletion-and-pruning/). The definitions themselves are in the [modules and instances reference](/docs/reference/definitions/modules-and-instances/).

## How it works

A published module, your values, a name and a namespace make an instance. OPM renders the instance against a platform, whose catalogs supply the transformers, and the result is a set of plain Kubernetes objects. The CLI or the operator applies the objects and keeps a record of them on the cluster.

{{< opm/module-to-cluster >}}

### A module is a published package

A module is a CUE module. `opm module init` scaffolds one from a template module in the registry, `opmodel.dev/templates/standard` unless you name another:

```text
my_app/
  cue.mod/module.cue      the CUE module path and pinned dependencies
  identity/identity.cue   ModulePath and Version
  module.cue              metadata, #config and debugValues
  components.cue          #components
```

`#config` is the configuration schema: every setting a deployer can change, with its type and, where it has one, its default. OPM's rule is that a module author writes defaults only in `#config`, each marked with `*`, as in `replicas: int & >=1 | *1`. `#components` maps each component name to a component. `debugValues` is example data the CLI renders the module with while you work on it. It is not a set of defaults.

A module can also set `initValues`: the values a new instance of it starts from. It is optional, and it may leave choices open. `opm instance init` writes it into the `values.cue` of the instance package it creates. A module without `initValues` stays valid, and its instances start from its `debugValues` if they are fully concrete, else from an empty `values: {}`.

The module path carries the major version, as in `example.com/modules/my_app@v0`. The module's `metadata.name` is snake_case and equals the path's last segment, here `my_app`. `opm module publish` pushes the module to the registry under that path, tagged with the full version from `identity/identity.cue`, such as `0.1.0`. `opm module publish` refuses a version the registry already holds.

### An instance binds a module to values, a name and a namespace

A module instance is a small CUE package that imports a module. This is the podinfo example from the CLI repository, which imports a test module. `instance.cue` embeds `#ModuleInstance`, names the instance and sets the module:

```cue
package podinfo

import (
	core "opmodel.dev/core@v2"
	podinfo "testing.opmodel.dev/modules/cli/podinfo@v0"
)

core.#ModuleInstance

metadata: {
	name:      "podinfo"
	namespace: "default"
}

#module: podinfo
```

A sibling `values.cue`, in the same package, holds the values:

```cue
package podinfo

values: {
	replicas: 2
}
```

`#ModuleInstance` takes five main inputs: the module in `#module`, `metadata.name`, `metadata.namespace`, `metadata.clusterDomain` (`cluster.local` unless you set it) and `values`. OPM unifies `values` with the module's `#config`. Values passed with `-f` join the same unification. A later file does not override an earlier one, and two different values for one setting are a conflict.

You do not have to write the package by hand. `opm instance init` creates one from a published module:

```bash
opm instance init shop opmodel.dev/modules/web_app --namespace shop
```

The command writes three files into `shop/`. `cue.mod/module.cue` gives the package the module path `instance.local/shop@v0` and pins the module, core and the catalogs to exact versions. `instance.cue` imports the module and sets the name and namespace. `values.cue` holds the starting values: the module's `initValues` if it sets them, else its `debugValues` if they are fully concrete, else an empty `values: {}`. The command prints which source it used, and it does not validate the result. Run `opm instance vet` on the package before you deploy it.

The instance's `components` are the module's `#components`, evaluated with your values. OPM adds no component of its own. The instance hands its name, namespace, UUID and cluster domain to the module, and the module passes them to every component as the component's instance identity. That is how each component computes the names of its objects. The default is `<instance>-<component>`, so the podinfo instance's `podinfo` component renders a Deployment and a Service named `podinfo-podinfo`.

### Three ways an instance reaches a cluster

{{< opm/three-ways-to-deploy >}}

1. **The CLI renders and applies it.** `opm instance apply instance.cue` deploys an instance package you wrote. `opm module apply` builds an instance around a module directory, or around a published module you name, so you can try the module without writing an instance. It takes the values from the files you pass with `-f`, or else from the module's `debugValues`. It names the instance after the module, with underscores turned into hyphens and `-debug` appended (`my-app-debug` for `my_app`), unless you pass `--name`. For a new instance, or one the CLI already owns, both commands apply the objects themselves and record them in a `ModuleInstance` resource with `spec.owner: cli`. Against an instance the operator owns, they write the module and values into the resource and wait for the operator to apply them.
1. **The operator reconciles a `ModuleInstance` resource.** You write the resource with kubectl or keep it in Git. It names a published module in `spec.module.path` and `spec.module.version` and carries your values in `spec.values`. The operator fetches the module from the registry, builds the instance with the resource's name and namespace, renders it against the cluster's platform and applies the objects.
1. **The operator renders a `ModulePackage`.** It points at a Flux source in `spec.sourceRef` and at a directory in `spec.path` that holds an authored `instance.cue`. The operator renders it only when it evaluates to a `#ModuleInstance`. A `ModulePackage` records its objects in its own status, not in a `ModuleInstance`.

No command moves an instance between the CLI and the operator. See [Who owns an instance](/docs/concepts/who-owns-an-instance/).

### What a rendered object carries from its instance

Every object an instance renders carries labels that tie it back to the instance and the module. These are the Deployment's labels from `opm instance build` on the podinfo example:

```yaml
metadata:
  labels:
    app.kubernetes.io/instance: podinfo
    app.kubernetes.io/managed-by: opm-cli
    app.kubernetes.io/name: podinfo
    component.opmodel.dev/name: podinfo
    core.opmodel.dev/workload-type: stateless
    module-instance.opmodel.dev/name: podinfo
    module-instance.opmodel.dev/uuid: 1d8fba19-ee5b-5a43-8d31-61de2b564881
    module.opmodel.dev/name: podinfo
    module.opmodel.dev/uuid: 7b5e5fc2-d261-5df3-a363-213e035e86a6
    module.opmodel.dev/version: 0.1.11
  name: podinfo-podinfo
  namespace: default
```

In this example the instance and its component are both named `podinfo`, so several labels show the same name. They differ when the names differ.

`module-instance.opmodel.dev/name` and `module-instance.opmodel.dev/uuid` name the instance. The UUID is the ownership label: before the operator prunes an object, it compares this label with the instance's UUID. `module.opmodel.dev/name`, `module.opmodel.dev/version` and `module.opmodel.dev/uuid` name the module the object came from. `app.kubernetes.io/managed-by` is `opm-cli` when the CLI rendered the object and `opm-controller` when the operator did. How the two UUIDs are computed is on [Identity and names](/docs/concepts/identity-and-names/).

## Why it is built this way

### Why a module and its values are separate

One module is deployed many times, into different namespaces, with different values, and none of those deployments forks it. That works because a component never names its own instance. The module injects the instance's identity into every component when an instance deploys it, so the same component definition serves every instance. OPM makes the split a type boundary, not a file convention: `#Module` leaves the instance's name and namespace open in `#ctx.instance` and carries no deployment values, and `#ModuleInstance` is the only definition that fills them.

### Why the configuration schema stays plain data

`#config` is the module's public contract, and it travels with the published module. Keeping it plain data lets tools that do not run CUE read it, such as a web form, a kubectl plugin or generated code in another language. So `#config` has to stay expressible as OpenAPI v3, with no CUE comprehensions, `for` loops or `if` clauses. Nothing checks this (see [What enforces this](#what-enforces-this)).

### Why a module's starting values are not its example values

`debugValues` and `initValues` answer different questions. `debugValues` is what the author tests with, and it can hold throwaway hostnames, debug log levels or dummy credentials. `initValues` is what the author wants a new deployment to start from. Reusing `debugValues` for both would copy test data into every new instance package, so OPM gives the second purpose its own field.

`initValues` is not unified with `#config`. That keeps every module load from evaluating the schema for a check only `opm instance init` needs, so a stale `initValues` breaks one new package instead of the whole module. It also lets the author leave a choice open. A setting with a default appears in `values.cue` as its default. A choice with no default, such as `"ClusterIP" | "LoadBalancer"`, appears as the choice, and the first `opm instance vet` asks the deployer to pick one. An optional setting is left out.

### Why an instance is one value with no builder

`#ModuleInstance` wires its name, namespace, UUID and cluster domain into the module inline, in the same expression that names the module. Module and instance are therefore a single CUE value. There is no builder to call first and no step that has to run before another. Because the cluster domain sits on the instance, an instance on a cluster with a non-standard domain sets `metadata.clusterDomain` once, and every component's fully qualified DNS name follows.

### Why instance identity ignores the module version

The operator prunes by identity. Before it deletes an object the new render no longer produces, it checks the object's `module-instance.opmodel.dev/uuid` label. It skips an object whose label names a different UUID. Instance identity once moved with every module release. After each upgrade, the old objects' labels no longer matched, so the operator skipped the deletes it should have made, left the objects running and reported success.

Instance identity is now computed from the module path without its major version, the instance name and the namespace. An upgrade to a new version, or to a new major, keeps the same UUID, so pruning keeps working across upgrades.

### Why default object names include the instance name

Two instances of one module can live in one namespace. If objects took the bare component name, both instances would render a Deployment called `web`, and each apply would overwrite the other's. `<instance>-<component>` keeps them apart. The namespace is left out because it is already the object's scope.

## Common mistakes

### `debugValues` are not defaults

`debugValues` looks like a set of defaults, and it is not one. It is example data that `opm module vet`, `opm module build` and `opm module apply` use when you pass no `-f` file. Passing `-f` replaces it entirely. An instance package never reads it, and OPM never falls back to it when an instance leaves a setting out. Defaults are the `*` values inside `#config`.

Nor is `debugValues` always what a new instance starts from. When a module sets `initValues`, `opm instance init` uses those and never reads `debugValues`.

### Values in an instance package are not checked for unknown settings

OPM checks values against `#config` and refuses a setting the schema does not have, with `field not allowed`. It does this for a file you pass with `-f`, for a module's `debugValues` in the `opm module` commands, and for a `ModuleInstance` resource's `spec.values` in the operator. Values written in the instance package itself, in `values.cue` or in a `values` field of `instance.cue`, are not checked that way when the CLI renders the package for an instance it owns, or when the operator renders a `ModulePackage`. A misspelled setting there is ignored, and the render succeeds without it. Run `opm instance build` and read the output when you change a setting there.

### The `ModuleInstance` resource is a record, not the thing that renders

The `ModuleInstance` custom resource is the cluster's record of an instance: its owner, the objects applied for it in `status.inventory`, and its status. For an instance the operator owns, it also carries the desired module path, version and values. What renders is the CUE `#ModuleInstance` value, built from the instance package or, by the operator, from the resource's spec. A resource the CLI owns carries `spec.module` and `spec.values` too, but the operator does not act on them while `spec.owner` is `cli`.

### Local modules reach the cluster only through the CLI

The CLI can render a module that is not published. The instance package keeps its usual import of the module, and a `cue.mod/local-module.cue` file in the package redirects that import to a directory on disk. This is CUE's own local module file, available from CUE v0.17:

```cue
deps: "opmodel.dev/modules/web_app@v1": replaceWith: "../web_app"
```

A relative path is resolved from the package's root. The CLI's render commands honour the file and warn that a local replacement is in effect. An instance the CLI applies this way carries the annotation `module-instance.opmodel.dev/source: local` on its `ModuleInstance` resource. CUE never publishes `local-module.cue`, and `opm module publish` refuses a module that carries one unless you pass `--skip-override-check`.

The operator never renders a local module. `spec.module` holds a registry path and a version, and nothing else. A `ModulePackage` whose instance package carries `local-module.cue` replacements is refused, because the operator does not enable local replacements. `opm instance apply` and `opm module apply` refuse to send a module resolved from local bytes to an instance the operator owns. Publish the module first, then let the operator deploy it.

### `app.kubernetes.io/instance` holds the component name

The Kubernetes recommended labels use `app.kubernetes.io/instance` for the name of an application's installation. OPM sets it, like `app.kubernetes.io/name`, to the component's name. The instance name is on `module-instance.opmodel.dev/name`. To select every object of one instance, select on that label:

```bash
kubectl get deployments,services -n default -l module-instance.opmodel.dev/name=podinfo
```

### Upgrading the module keeps the same instance

Moving an instance to a new version of its module keeps its UUID, even across a new major path such as `@v1` to `@v2`. The ownership label on the live objects still matches. Renaming the instance or moving it to another namespace does not: OPM treats that as a different instance, with a different UUID.

### Deleting the record does not always delete the workloads

For an instance the operator owns, deleting the `ModuleInstance` resource leaves the workloads running unless `spec.prune` is `true`. The field's default is `false`, and the CLI never writes it. An instance the CLI owns has no finalizer, so `kubectl delete` on its resource removes the only record of what was applied, and the objects stay. Read [Deletion and pruning](/docs/operating/deletion-and-pruning/) before you delete an instance.

## What enforces this

Each rule names what refuses a violation. [What enforces a rule](/docs/concepts/what-enforces-a-rule/) explains the four badges.

- `cue`: A module's `metadata.modulePath` ends in a major version, `@vN` (`#ModulePathType`).
- `cue`: A module's `metadata.name` is snake_case and equals the last segment of its module path (`#SnakeNameType` and the hidden `_leaf` check).
- `publish`: The version's major agrees with the module path's major. `opm module publish` refuses a mismatch, and `opm module vet` runs the same identity check.
- `publish`: A version is published once. `opm module publish` refuses a version the registry already holds.
- `cue`: A value a component reads has the type `#config` gives it. Unification inside `#ModuleInstance` refuses a wrong type there.
- `kernel`: Values from a `-f` file, a module's `debugValues` and a `ModuleInstance` resource's `spec.values` have no setting `#config` lacks. The render refuses one with `field not allowed`, in the CLI's vet, build, diff and apply commands and in the operator's reconcile.
- `cue`: An instance's name and namespace are DNS labels (`#NameType`).
- `cue`: Every component receives the instance's identity. A component that sets `#instance` to a different identity conflicts with the module's wiring.
- `convention`: A module author writes defaults only inside `#config`, never on component fields. Nothing checks it.
- `cue`: A module's top-level fields are the ones `#Module` declares. A misspelled field, such as `initValuez`, fails with `field not allowed`, and so does `initValues` against a core release older than the one that added it.
- `convention`: A module's `initValues` satisfy its `#config`. Nothing checks this when the module loads or when `opm instance init` runs; a mismatch surfaces at the first `opm instance vet` of the new package.
- `convention`: `#config` stays expressible as OpenAPI v3, with no comprehensions. Core's specification says the render pipeline enforces this, but no check exists.
