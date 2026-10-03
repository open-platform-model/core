---
title: "The application model and the platform model"
description: "Why OPM is named a platform model while it models applications today, and what each model covers."
type: explanation
weight: 29
---

Open Platform Model (OPM) names two models. The application model describes an application and what it needs from a cluster. OPM has it today, as modules, components and instances. The platform model describes the platform an application runs on. OPM models a platform only as far as rendering needs: the catalogs it admits and the contracts they serve. A cluster's controllers, its APIs and the services it offers to teams are outside OPM.

This page assumes you have read [What OPM is](/docs/start/what-is-opm/). It explains what each model covers, what exists of each today, and why OPM started with the application. The parts of the application model are explained on [Modules and instances](/docs/concepts/modules-and-instances/) and [Components and blueprints](/docs/concepts/components-and-blueprints/), and the platform's catalogs on [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/). OPM's terms are defined in the [Glossary](/docs/reference/glossary/).

## How it works

The two models meet at one point: the render. The module names the resources and traits its components need. The platform admits the catalogs whose transformers turn those resources and traits into Kubernetes objects. An instance brings one module to one platform.

{{< opm/what-opm-models >}}

### The application model

The application model describes what an application is, apart from any cluster. It is made of four definitions.

- A module ([`#Module`](/docs/reference/definitions/modules-and-instances/#module)) is a versioned, published description of an application. It holds the configuration schema ([`#config`](/docs/reference/definitions/modules-and-instances/#module)), every setting a deployer can change, and the module's components.
- A component ([`#Component`](/docs/reference/definitions/components/#component)) is one deployable part of the application, usually one workload. It adds no schema of its own. Its `spec` is the unification of the specs of the parts it attaches.
- Those parts are resources ([`#Resource`](/docs/reference/definitions/resources-traits-and-blueprints/#resource)), such as a container or a volume; traits ([`#Trait`](/docs/reference/definitions/resources-traits-and-blueprints/#trait)), such as scaling or exposure; and blueprints ([`#Blueprint`](/docs/reference/definitions/resources-traits-and-blueprints/#blueprint)), which combine resources and traits into one attachable unit. A catalog publishes them as contracts. A module names them and writes values against them, but never defines them.
- A module instance ([`#ModuleInstance`](/docs/reference/definitions/modules-and-instances/#moduleinstance)) embeds one module and holds the values, a name and a namespace. The instance is what renders.

The application model never names a Kubernetes object. A module says that a component runs a container and is exposed on a port. Whether that becomes a Deployment, a Service or something else is decided on the platform side.

### The platform, as far as OPM models it today

A platform ([`#Platform`](/docs/reference/definitions/catalogs-and-platforms/#platform)) is a list of catalogs. Its registry, `#registry`, has one entry per catalog module path, such as `opmodel.dev/catalogs/opm@v4`, and each entry imports the catalog itself. The platform module's `cue.mod/module.cue` pins which build of each catalog that is. From the enabled entries, the platform collects every transformer into one set, `#composedTransformers`. Matching reads that set when it decides which objects a component becomes.

The platform also reports a contract inventory, `#contracts`. It lists the contracts the enabled catalogs define, the transformers that require each one, the provider-fulfilled contracts with no provider or with more than one, and the contract keys that collide because more than one enabled catalog lists them. `opm platform check` prints the inventory.

A platform has a `type` as well. It is a label, and nothing in OPM reads it.

The operator renders against the cluster's platform. The CLI renders against a directory you pass with `--platform`, the cluster's platform, or, when it uses neither, a platform it generates from the render's own catalog pins. [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/) explains each source.

That is the whole platform half today. It answers one question: which transformers, from which catalog builds, may render this instance.

### The platform model

OPM has no platform model. No OPM definition describes a cluster's global settings, the controllers and APIs it is built from, or the services it offers to teams.

> [!NOTE]
> **Direction**
>
> The platform model is meant to describe a whole platform: its global settings, the controllers and APIs it is built from, and the services it offers to teams. No enhancement designs it. Two draft enhancements design changes to the platform side, and no work has started on either.
>
> Enhancement 0026, [Module-Dictated Catalog Versions and the Generated Platform](/enhancements/0026/), changes how a platform admits catalogs. Its design lets a platform admit each catalog with a range of versions and lets each module's own pin choose the version inside that range. A pin outside the range is refused.
>
> Enhancement 0027, [Self-Service Kinds from Published Modules](/enhancements/0027/), covers one part of the platform model: the services a platform offers to teams. Its design lets a platform team bind a published module, its major version, an exact release and an update policy in one cluster-wide object, served as a Kubernetes kind that a team creates by supplying values alone.

## Why it is built this way

### Why the application model came first

OPM started with applications for three reasons.

An application model is useful on its own. A team with one cluster and no platform team still gets a typed module, values that fail on a wrong type before anything is applied, and one record of what was deployed. A platform model with no applications to serve has nothing to describe.

The application definition is the part that has to last. Clusters, controllers and providers change over the life of an application. The way the application is described should not have to change with them. Settling that boundary first gives a platform model a stable target to describe.

A platform model needs a vocabulary for what a platform can do, and the application model supplies it. The resources and traits that modules name are the terms a platform's capabilities are stated in. The platform half OPM has today already uses them: a platform's contract inventory says which of those contracts the platform can render.

### Why the two are separate models

Module authors and platform teams change different things, on different schedules. A module author releases a new version when the application changes. A platform team upgrades a catalog or adds a provider when the platform changes. If either change forced the other, every platform upgrade would wait for module releases, and every module would carry one platform's choices.

{{< opm/two-models-one-boundary >}}

So the application model does not depend on the shape of any platform. A module names catalog contracts, never a platform and never a Kubernetes object. Rendering lives in transformers, which a platform admits through its catalogs, and not in the module. A transformer takes contracts other people defined and produces one target's objects, so it belongs to the target. The same module renders on any platform whose catalogs serve the contracts it names.

## Common mistakes

### OPM does not model your whole platform

The name suggests that OPM describes your cluster: its controllers, its APIs and the services it offers. It does not. OPM models applications, and a platform only as far as rendering needs: the catalogs it admits, the build of each, and the contracts they define and require. [What OPM does not do](/docs/start/what-opm-does-not-do/#a-model-of-the-platform-itself) lists what OPM has in place of a platform model.

### The Platform resource is not the platform model

The operator reads a cluster-scoped `Platform` resource, which must be named `cluster`. Its spec holds three fields:

- `type`, the same label as on `#Platform`, which nothing reads
- `registry`, the catalogs the platform subscribes to, each with `enable` and `version`
- `skewPolicy`, which decides what happens when a module pins a newer build of core or a catalog than the platform does: `Warn` renders against the platform's build and reports the skew, and `Refuse` refuses the render

The operator adds the catalogs of active `TransformerRegistration` claims and records the result in `status.registry`. From that it generates a platform module, the same kind of `#Platform` the CLI renders against. Nothing in the resource describes the cluster's controllers, its APIs or the services it offers.

### A provider contract is not a service the platform offers

A provider-fulfilled contract, such as the opm catalog's `backup` trait, looks like a service a platform offers. It is a rendering contract. It says that exactly one catalog on the platform supplies the transformer for the trait. The platform does not describe the backup controller that acts on the rendered objects. Admitting the provider catalog installs nothing, and nothing in OPM checks that the controller runs.

## What enforces this

Each rule names what refuses a violation. [What enforces a rule](/docs/concepts/what-enforces-a-rule/) explains the four badges.

- `cue`: A registry key is the module path of the catalog its entry imports. A key that disagrees with the import is a conflict that names the entry.
- `cue`: An entry's `version` is read from the imported catalog, so the build a render uses is the one the platform module's `cue.mod/module.cue` pins. An entry that states another version conflicts.
- `kernel`: A provider-fulfilled contract has at most one provider on a platform, counted per registry entry, so two majors of one catalog are two providers. The render refuses more with `OverSubscribedContractsError`. `opm platform check` exits with the validation error code, and the operator sets the `Platform`'s `Ready` condition to `False` with reason `OverSubscribedContracts`.
- `kernel`: A contract key is listed by at most one enabled catalog. The render refuses a platform with a collision, with `ContractCollisionsError`, whatever the instance. `opm platform check` exits with the validation error code, and the operator sets the `Platform`'s `Ready` condition to `False` with reason `ContractCollisions`.
- `convention`: A platform's `type` names what kind of platform it is. Nothing reads or checks it.

Nothing enforces the platform model, because it does not exist.
