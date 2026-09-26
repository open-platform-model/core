---
title: "Identity and names"
description: "How OPM identifies modules and catalog members, and why a name means different things in different places."
type: explanation
sidebar:
  order: 36
---

<!-- Open with OPM as the subject: OPM gives modules, catalogs, contracts, transformers and instances each a fully qualified name in a field called `fqn`, and the field means something different on each. The core claim, stated early: on a module or catalog `fqn` is the module path verbatim; on a resource, trait or blueprint it is a contract key that differs from the member's own `modulePath`. The second half of the page covers names: which spelling each thing takes, and which name ends up on a rendered object. Assumes Modules and instances and Resources and traits; links Versions in OPM for the version inside each key. Check against: core/src/types.cue, core/src/module.cue, core/src/resource.cue, core/SPEC.md 
Kubernetes comparison, only if it helps: weave it into the sentence that introduces the concept, or into How it works, never as a section of its own. Researched candidate: Nearest ideas: an object is identified by apiVersion, kind, namespace and name, plus a UID the API server assigns; a custom resource type is named by group, version and kind. A contract key reads like a group-version-kind: `opmodel.dev/catalogs/opm/traits` plays the group, `scaling` the kind, `v1beta1` the version. Where it stops: Kubernetes converts between versions of one kind, while OPM treats `scaling@v1beta1` and `scaling@v1` as unrelated keys. Second comparison: a ModuleInstance's `metadata.uuid` against a Kubernetes UID. Where it stops: a UID is random and changes when an object is deleted and recreated; an instance uuid is computed from the module's registry path, the instance name and the namespace, so recreating the instance or upgrading its module gives the same uuid. Check against: core/src/types.cue (#ContractFQNType, OPMNamespace), core/src/module_instance.cue -->

## How it works

<!-- One illustrative snippet, not a field table, giving each kind's real `fqn`: module `opmodel.dev/modules/apprise@v3`, equal to its modulePath; catalog `opmodel.dev/catalogs/opm@v4`, equal to its modulePath; trait `opmodel.dev/catalogs/opm/traits/scaling@v1beta1`, whose modulePath is `opmodel.dev/catalogs/opm/traits/v1beta1`; transformer `opmodel.dev/catalogs/opm/transformers/deployment-transformer@<catalog version>`; instance `opmodel.dev/modules/apprise:<instance name>:<namespace>`. Check against: modules/apprise/identity/identity.cue, catalog_opm/opm/identity/identity.cue, catalog_opm/opm/traits/v1beta1/scaling.cue, catalog_opm/opm/transformers/deployment_transformer.cue, core/src/module_instance.cue -->

### Modules and catalogs are named by their path

<!-- `metadata.modulePath` is the complete CUE module path with its major, the same string as `cue.mod`'s `module:` line and an import statement. `metadata.fqn` is that path verbatim and cannot be written by hand; `metadata.registryPath` is the path without the major, the OCI repository the tags live under; `metadata.uuid` is a UUID v5 of `fqn` under one fixed OPM namespace UUID. The path and the version come from one file, `identity/identity.cue`, which holds only `ModulePath` and `Version`. Check against: core/src/module.cue, core/src/catalog.cue, core/src/types.cue (#ArtifactRef, OPMNamespace), core/src/identity_package.cue -->

### Contracts are named by an authored key

<!-- Resources, traits and blueprints carry a `metadata.fqn` of the form `<path>/<name>@<apiVersion>` (#ContractFQNType), written by the catalog and not computed by core. Their `metadata.modulePath` is a different string: the package the member is filed in, `<catalog registryPath>/<kind>/<apiVersion>`, with no major. The kind segment (`/resources`, `/traits`, `/blueprints`) stays in the key so a resource and a trait may share a name. This key is what a module demands, what a transformer requires, and what a catalog lists its members under. Check against: core/src/resource.cue, core/src/trait.cue, core/src/blueprint.cue, core/src/catalog.cue, catalog_opm/opm/traits/v1beta1/scaling.cue -->

### Transformers are named by the build that shipped them

<!-- A transformer's `metadata.fqn` is `<path>/<name>@<semver>` (#ImplFQNType), where the version is the catalog's release; its `modulePath` is `<catalog registryPath>/transformers`. Contract keys and transformer keys are separate types, so one cannot stand where the other belongs. Check against: core/src/transformer.cue, core/src/types.cue (#ImplFQNType, #FQNType), catalog_opm/opm/transformers/deployment_transformer.cue -->

### Instances are named by module lineage, name and namespace

<!-- `#ModuleInstance.metadata.fqn` is `<module registryPath>:<name>:<namespace>` and `uuid` is a UUID v5 of it. Neither the module's version nor its major is an input, so the uuid survives every upgrade, while a different module path, instance name or namespace gives a different uuid. The uuid is stamped on every rendered object as `module-instance.opmodel.dev/uuid`, and the operator will not prune a live object whose label disagrees with the uuid it recorded. Verify: the CLI's own prune path does not compare this label. Check against: core/src/module_instance.cue, core/src/identity_pins.cue, core/src/transformer.cue (moduleLabels), opm-operator/internal/apply/prune.go, cli/internal/inventory/stale.go -->

### Names and their spellings

<!-- A module's `metadata.name` is snake_case (#SnakeNameType) and must equal the last segment of its path, because a module is a CUE package and a package name cannot contain a hyphen. Resource, trait, blueprint and component names, instance names and namespaces are kebab-case DNS labels of up to 63 characters (#NameType). Check against: core/src/types.cue (#SnakeNameType, #NameType), core/src/module.cue (_leaf), core/src/module_instance.cue -->

### Which name reaches a rendered object

<!-- A component sits under a key in `#components`; its `metadata.name` defaults to that key and may differ from it. `metadata.name` is the one that counts: it becomes the `component.opmodel.dev/name` and `app.kubernetes.io/name` labels and the default object name. The rendered object's name is `metadata.resourceName`, which defaults to `<instance name>-<component name>`; an explicit value may be any DNS subdomain up to 253 characters (#ObjectNameType) unless an attached member narrows it (the Expose trait requires a valid Service name, #ServiceNameType; the stateful workload blueprint requires a DNS label). `#names.dns` derives the short, namespace-local and cluster-wide DNS names from `resourceName`. Check against: core/src/component.cue, core/src/module.cue (#components), core/src/transformer.cue (componentLabels, controllerLabels), core/src/types.cue (#ObjectNameType, #ServiceNameType), catalog_opm/opm/traits/v1beta1/expose.cue, catalog_opm/opm/blueprints/v1beta1/stateful_workload.cue, catalog_opm/docs/name-constraints.md -->

## Why it is built this way

### Why a module's path is its identity

<!-- The path used to be a prefix every consumer joined with the name to reach a registry address, a composition repeated in the CLI and the library with nothing to check it against. Making the declared path the address means code holding a module can import it again, and a fetched artifact can be compared with the coordinate it was fetched by. CUE, the OCI registry and an import statement already agree on the spelling. Check against: core/SPEC.md (§3.2 Rationale, "Why `modulePath` is the complete module path and not a bare prefix"), library/opm/internal/loader/registry.go -->

### Why instance identity leaves out the version and the major

<!-- The module uuid answers "which module is this" and has to change with the major. The instance uuid answers "which live objects does this instance own" and has to survive every upgrade. When the instance uuid derived from a module identity that included the version, every release moved the ownership label, and the operator skipped the deletes it should have made while reporting success. Check against: core/SPEC.md (§3.5 Rationale), core/src/module_instance.cue, opm-operator/internal/apply/prune.go -->

### Why instance identity uses the registry path and not the module name

<!-- Module names are not unique: `opmodel.dev/modules/jellyfin` and `example.com/jellyfin` share the name `jellyfin`. Identity built from the name would let an instance of one claim objects left behind by an instance of the other with the same instance name and namespace. A full registry path is unique. Verify: the delete-and-recreate scenario is the realistic case, since two ModuleInstances cannot share a name in one namespace. Check against: core/SPEC.md (§3.5 Rationale, "Why not derive instance identity from the module's `name`"), core/src/identity_pins.cue -->

### Why contract keys are authored and checked at publish

<!-- The catalog's identity file is the single source of its path and version; if core also derived each key, a release would move the same value in two places. The price is that a wrong key passes `cue vet`, so the publish command checks every member's key, filing path and `catalogVersion` against the identity file. Check against: core/SPEC.md (§2.1 Rationale, "Why `fqn` is authored rather than computed", and §5.3), core/src/identity_package.cue (#CatalogMemberFQNGate), cli/internal/publish/catalog_gates.go -->

### Why a module name has one spelling

<!-- There used to be three: a kebab-case name, a derived snake_case copy and the path's last segment, with nothing checking they agreed. A CUE package name is taken from the path's last segment and cannot contain a hyphen, so only one spelling was ever usable, and the schema now requires it. Check against: core/SPEC.md (§3.2 Rationale, "Why `name` is snake_case and the path's leaf must equal it"), core/src/types.cue (#SnakeNameType) -->

### Why the default object name includes the instance name

<!-- With the bare component name, two instances of one module in one namespace would both render a `web` Deployment and overwrite each other. The namespace and uuid stay out: the namespace is already part of the DNS name, and a uuid is unreadable in `kubectl get`. Check against: core/SPEC.md (§3.1 Rationale, "Why the default is `<instance>-<component>`"), core/src/component.cue -->

## Common mistakes

### A contract's `fqn` is not its `modulePath`

<!-- Misreading, carried over from modules: `fqn` equals `modulePath` everywhere. Correct: only on modules and catalogs. The scaling trait's `modulePath` is `…/traits/v1beta1` and its `fqn` is `…/traits/scaling@v1beta1`. Check against: core/src/trait.cue, core/src/catalog.cue, catalog_opm/opm/traits/v1beta1/scaling.cue -->

### The `@v1` on a contract key is a contract level

<!-- Misreading: `…/blueprints/stateless-workload@v1` names a module major. Correct: on a module path `@v1` is an address a registry resolves; on a contract key it is the member's apiVersion, compared for equality. The two never appear in the same field. Check against: core/src/types.cue (the note under #ImplFQNType on the collision with #ModulePathType) -->

### A new module major keeps the same instance

<!-- Misreading: moving a module from `@v2` to `@v3` replaces the instance or orphans its objects. Correct: the module's `fqn` and `uuid` change; the instance's `fqn` and `uuid` do not, so the same ModuleInstance keeps owning its objects. Check against: core/src/module_instance.cue, core/src/identity_pins.cue -->

### `app.kubernetes.io/instance` holds the component name

<!-- Misreading from the Kubernetes recommended labels, where `app.kubernetes.io/instance` names the instance of an application. Correct: on objects OPM renders it carries the component's `metadata.name`, the same value as `app.kubernetes.io/name`; the instance name is in `module-instance.opmodel.dev/name`. Check against: core/src/transformer.cue (componentLabels, controllerLabels) -->

### A component's key and its name can differ

<!-- Misreading: renaming a key under `#components` renames what renders. Correct: `metadata.name` defaults to the key, and where both are set `metadata.name` decides the labels, the default object name and what a transformer sees; the key stays the handle the rest of the module refers to the component by. Real example: in `modules/k8up` the key `manager-cluster-role` carries the name `k8up-manager`. Check against: core/src/module.cue (#components), core/src/transformer.cue (#componentMetadata), modules/k8up/components.cue -->

## What enforces this

<!-- cue: a module's or catalog's `fqn` is derived from `modulePath` and a different value conflicts; `metadata.name` must equal the path's last segment (error names `_leaf`: "conflicting values false and true"); `modulePath` must carry `@vN`; component names, instance names and namespaces are DNS labels; an explicit `resourceName` must be a DNS subdomain and satisfy every attached member's name rule; a catalog stamps each member's `modulePath` and `catalogVersion` and refuses a different authored value ("conflicting values"); contract maps take only contract keys and transformer maps only transformer keys. Check against: core/src/module.cue, core/src/component.cue, core/src/catalog.cue, core/src/types.cue, core/src/identity_pins.cue, core/src/component_names_pins.cue -->

<!-- publish: every catalog member's `fqn`, filing path and `catalogVersion` must agree with the identity file (#CatalogMemberFQNGate, "<definition> (<package>) is off its catalog's key space"); `metadata.modulePath` and `metadata.version` must come from the identity file ("<file> states a modulePath its identity package does not"); `cue.mod`'s `module:` line must equal the declared path ("<path> disagrees with itself about where it lives"); a module's package name must equal `metadata.name` ("<directory>'s package does not bind to its name"); paths under `opmodel.dev` and `community.opmodel.dev` must fit a fixed shape (see Registry Namespaces). Several of these also run in `opm module vet`. Check against: cli/internal/publish/catalog_gates.go, cli/internal/publish/gates.go, cli/internal/publish/vet.go -->

<!-- kernel: a module fetched from a registry whose `metadata.modulePath` or `metadata.version` differs from the coordinate it was fetched by fails with "identity mismatch at path|version"; link Identity mismatch. Check against: library/opm/errors/identity.go, library/opm/internal/loader/registry.go -->

<!-- convention: Verify before badging. Core's specification says a member's name must be unique within its `modulePath`; find whether anything checks it. If nothing does, badge it convention. Check against: core/SPEC.md (§2.1 Constraints), core/src/catalog.cue, cli/internal/publish/catalog_gates.go -->
