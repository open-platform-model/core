---
title: "The application model and the platform model"
description: "Why OPM is named a platform model while it models applications today, and what each model covers."
type: explanation
weight: 29
---

Open Platform Model (OPM) names two models. The application model describes an application and what it needs from a cluster. OPM has it today, as modules, components and instances. The platform model would describe the platform an application runs on, and [Where OPM is going](/docs/start/vision/) describes the vision for it. OPM models a platform only as far as rendering needs: the catalogs it admits and the contracts they serve. OPM does not model a cluster's controllers, its APIs or the services it offers to teams.

This page assumes you have read [What OPM is](/docs/start/what-is-opm/). It explains what each model covers, what exists of each today, and why OPM started with the application. The parts of the application model are explained on [Modules and instances](/docs/concepts/modules-and-instances/) and [Components and blueprints](/docs/concepts/components-and-blueprints/), and the platform's catalogs on [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/). OPM's terms are defined in the [Glossary](/docs/reference/glossary/).

## How it works

The application model and the platform, as far as OPM models it, meet at one point: the render. The module names the resources and traits its components need. The platform admits the catalogs whose transformers turn those resources and traits into Kubernetes objects. An instance brings one module to one platform.

{{< opm/what-opm-models >}}

### The application model

The application model describes what an application is, apart from any cluster. It is made of these definitions:

- A module ([`#Module`](/docs/reference/definitions/modules-and-instances/#module)) is a versioned, published description of an application. It holds the configuration schema ([`#config`](/docs/reference/definitions/modules-and-instances/#module)), which lists every setting a deployer can change, and the module's components.
- A component ([`#Component`](/docs/reference/definitions/components/#component)) is one deployable part of the application, usually one workload. It adds no schema of its own. Its `spec` is the unification of the specs of the parts it attaches.
- Those parts are resources ([`#Resource`](/docs/reference/definitions/resources-traits-and-blueprints/#resource)), such as a container or a volume, and traits ([`#Trait`](/docs/reference/definitions/resources-traits-and-blueprints/#trait)), such as scaling or exposure. Blueprints ([`#Blueprint`](/docs/reference/definitions/resources-traits-and-blueprints/#blueprint)) combine resources and traits into one attachable unit. A catalog publishes all three as contracts. A module names them and writes values against them, and does not publish them.
- A module instance ([`#ModuleInstance`](/docs/reference/definitions/modules-and-instances/#moduleinstance)) embeds one module and holds the values, a name and a namespace. The instance is what renders.

A module describes its application in catalog terms, not in Kubernetes objects. It says that a component runs a container and is exposed on a port. Whether that becomes a Deployment, a Service or something else is decided on the platform side. The one exception is the opm catalog's `objects` resource, the escape hatch for objects no abstraction models: each entry in it renders as written.

### The platform, as far as OPM models it today

A platform ([`#Platform`](/docs/reference/definitions/catalogs-and-platforms/#platform)) is a list of catalogs. Its registry, `#registry`, has one entry per catalog module path, such as `opmodel.dev/catalogs/opm@v4`. Each entry imports the catalog itself. The platform module's `cue.mod/module.cue` pins which build of each catalog that is. From the enabled entries, the platform collects every transformer into one set, `#composedTransformers`. Matching reads that set when it decides which objects a component becomes.

The platform also reports a contract inventory, `#contracts`. It lists the contracts the enabled catalogs define and the transformers that require each one. It reports the provider-fulfilled contracts with no provider or with more than one, and the contract keys that collide because more than one enabled registry entry lists them. It also reports pairs of transformers whose match predicates overlap on a shared catalog contract. `opm platform check` prints the inventory.

A platform has a `type` as well. It is a label. Every platform must set it, and rendering does not consult it.

The operator renders against the cluster's platform. The CLI renders against a directory you pass with `--platform`, the cluster's platform, or, when it uses neither, a platform it generates from the render's own catalog pins. [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/) explains each source.

That is the whole platform half today. It decides which transformers, from which catalog builds, may render an instance, and what happens when the instance pins a newer build than the platform does.

### The platform model

OPM has no platform model. No OPM definition describes a cluster's global settings, the controllers and APIs it is built from, or the services it offers to teams.

One mechanism a platform model would build on already works: a module can extend the platform it runs on. A provider module renders a `TransformerRegistration`, with the opm catalog's `transformer-registration` resource, that claims its catalog implements provider-fulfilled contracts, such as the opm catalog's `backup` trait. Once the operator accepts the claim and the provider's instance reports `Ready`, the catalog joins the platform, and every other module on that platform can use the trait. The module supplied a capability, and the platform offers it to everyone else. No published module uses this mechanism today.

> [!NOTE]
> **Direction**
>
> OPM aims to model the platform as well as the application. A platform model would describe a whole platform: its global settings, the controllers and APIs it is built from, and the services it offers to teams. Modules would supply what a platform offers, and other modules would consume it, so each model depends on the other. A platform would be portable: an organisation defines one or more and instantiates each onto infrastructure, Kubernetes first and later clouds such as AWS, GCP or OpenStack. [Where OPM is going](/docs/start/vision/) describes the vision and why the project pursues it.
>
> No enhancement designs the platform model as a whole, or a description of a cluster's controllers or APIs. Several draft enhancements design changes to the platform side, and no work has started on them. Two bear most directly on the platform model.
>
> Enhancement 0026, [Module-Dictated Catalog Versions and the Generated Platform](/enhancements/0026/), changes how a platform admits catalogs. Its design lets a platform admit each catalog with a range of versions. Each module's own pin chooses the version inside that range, and the design refuses a pin outside it.
>
> Enhancement 0027, [Self-Service Kinds from Published Modules](/enhancements/0027/), designs one thing a platform model would describe: the services a platform offers to teams. Its design lets a platform team bind a published module, its major version, an exact release and an update policy in one cluster-wide object. The object is served as a Kubernetes kind that a team creates by supplying values alone.

## Why it is built this way

### Why the application model came first

OPM started with applications for three reasons.

An application model is useful on its own. A team with one cluster and no platform team still gets a typed module and one record of what was deployed. A value of the wrong type fails before anything is applied. None of that waits for a description of the platform.

The application definition is the part that has to last. Clusters, controllers and providers change over the life of an application. The way the application is described should not have to change with them. Settling that boundary first means a platform model, if one is designed, has a stable target.

Any platform model would need a vocabulary for what a platform can do. The contracts that catalogs publish, which modules already name, are one. The platform half OPM has today already uses them: a platform's contract inventory says which of those contracts the platform can render.

### Why the two are separate models

Module authors and platform teams change different things, on different schedules. A module author releases a new version when the application changes. A platform team upgrades a catalog or adds a provider when the platform changes. If either change forced the other, every platform upgrade would wait for module releases, and every module would carry one platform's choices.

{{< opm/two-models-one-boundary >}}

So the application model does not depend on the shape of any platform. A module names catalog contracts and never a platform. Rendering lives in transformers, which a platform admits through its catalogs, and not in the module. A transformer takes contracts other people defined and produces one target's objects, so it belongs to the target. The same module can render on any platform whose catalogs serve the contracts it names.

## Common mistakes

### OPM does not model your whole platform

The name suggests that OPM describes your cluster: its controllers, its APIs and the services it offers. It does not. OPM models applications, and a platform only as far as rendering needs: the catalogs it admits, the version of each, and the contracts they define and require. [What OPM does not do](/docs/start/what-opm-does-not-do/#a-model-of-the-platform-itself) lists what OPM has in place of a platform model, and [Where OPM is going](/docs/start/vision/) describes where the project wants to take it.

### The Platform resource is not the platform model

The operator, and the CLI when it renders against the cluster, read a cluster-scoped `Platform` resource, which must be named `cluster`. Its spec holds three fields:

- `type`, the same label as on `#Platform`, which rendering does not consult
- `registry`, the catalogs the platform subscribes to, each with `enable` and `version`
- `skewPolicy`, which decides what a render does when the instance pins a newer build of core or an OPM catalog than the platform does: `Warn`, the default, renders against the platform's build and reports the skew, and `Refuse` refuses the render

The operator adds the catalogs of active `TransformerRegistration` claims and records the result in `status.registry`. From that it generates a platform module, the same kind of `#Platform` the CLI renders against. Nothing in the resource describes the cluster's controllers, its APIs or the services it offers.

### A provider contract is not a service the platform offers

A provider-fulfilled contract, such as the opm catalog's `backup` trait, looks like a service a platform offers. It is a rendering contract. It says that exactly one catalog on the platform supplies the transformer for the trait. The platform does not describe the backup controller that acts on the rendered objects.

Subscribing to the provider catalog in `spec.registry` installs nothing, and nothing checks that a controller acts on what the catalog renders. A catalog that arrives through a provider module's `TransformerRegistration` joins the platform once that module's instance first reports `Ready`. It stays after that, even if the controller stops.

## What enforces this

Each rule names what refuses a violation. [What enforces a rule](/docs/concepts/what-enforces-a-rule/) explains the four badges.

- `cue`: A registry key is the module path of the catalog its entry imports. A key that disagrees with the import is a conflict that names the entry.
- `cue`: An entry's `version` is read from the imported catalog. An entry that states another version conflicts.
- `kernel`: A render uses the platform's build of every OPM catalog the platform pins. When the instance pins a newer build, the render warns, or refuses with `SkewError` when the skew policy is `Refuse`.
- `kernel`: A provider-fulfilled contract has at most one provider on a platform, counted per registry entry, so two majors of one catalog are two providers. The render refuses more with `OverSubscribedContractsError`. `opm platform check` exits with the validation error code. The operator sets the `Platform`'s `Ready` condition to `False` with reason `OverSubscribedContracts`, and keeps rendering against the last platform it accepted.
- `kernel`: A contract key is listed by the catalog of at most one enabled registry entry, so two majors of one catalog that share keys collide. The render refuses a platform with a collision, with `ContractCollisionsError`, whatever the instance. `opm platform check` exits with the validation error code. The operator sets the `Platform`'s `Ready` condition to `False` with reason `ContractCollisions`, and keeps rendering against the last platform it accepted.
- `cue`: A platform sets `type`.
- `convention`: A platform's `type` names what kind of platform it is. Nothing acts on its value.

Two transformers whose match predicates overlap on a shared catalog contract make `opm platform check` exit with the validation error code, and the operator refuses the platform with reason `ComparablePredicates`. The render does not refuse them. Nothing enforces the platform model, because it does not exist.
