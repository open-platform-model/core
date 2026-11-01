# OPM core schema

The pure CUE schema published as `opmodel.dev/core@v2`. It defines the types that every OPM artifact is written against: what an application is, what a catalog publishes, and how a platform admits catalogs.

## Language

### Primitives

**Primitive**:
An independently authored and versioned schema contract that a `#Module` attaches and writes values against. `#Resource`, `#Trait` and `#Blueprint` are primitives; each carries a contract key and an `apiVersion`.
_Avoid_: Building block, definition (when you mean one of the three)

**#Resource**:
A primitive for a deployable entity that must exist at runtime and has its own lifecycle, such as a container or a volume. The nouns of OPM.
_Avoid_: Object, kind, K8s resource

**#Trait**:
A primitive that modifies the behavior or surface of a `#Component` without being a deployable thing itself, and names the `#Resource` kinds it applies to in `appliesTo`. The adjectives of OPM.
_Avoid_: Feature, capability, policy, mixin

**#Blueprint**:
A primitive that composes `#Resource` and `#Trait` values into one higher-level abstraction that a `#Component` attaches as a single unit.
_Avoid_: Template, pattern, preset

**Contract key**:
The `path/name@vN` key (a contract FQN) under which a primitive is published and matched; it moves with the primitive's own `apiVersion`, never with a catalog release.
_Avoid_: FQN (unqualified), id, name

**Fulfilment**:
The field on a `#Resource` or `#Trait` that says where the implementation of the contract comes from: `"catalog"` (default) or `"provider"`. A provider-fulfilled contract admits exactly one provider on a platform.
_Avoid_: Implementation source, backend

### Constructs

**Construct**:
A framework type that composes, organizes, carries or publishes primitives without introducing new schema: `#Component`, `#Module`, `#Platform`, `#ModuleInstance`, `#Catalog`.
_Avoid_: Primitive (for these)

**#Component**:
The smallest deployable unit a `#Module` ships. It unifies the primitives attached to it into one closed `spec`.
_Avoid_: Service, workload, microservice

**#Module**:
The portable, versioned application blueprint: a set of `#components` plus a `#config` schema. It describes what an application is and carries no concrete values.
_Avoid_: Package, app, chart, release

**#ModuleInstance**:
A `#Module` paired with the values that satisfy its `#config`, plus instance identity (name, namespace, uuid, cluster domain). It is what a runtime renders. Renamed from `#ModuleRelease`.
_Avoid_: Release, deployment, ModuleRelease

**#Catalog**:
The construct a catalog package exports to publish its primitives and transformers as one versioned artifact. It states the contracts it defines and the contracts it implements.
_Avoid_: Registry, repository, library

**#Platform**:
A path-keyed registry of catalog entries that states which catalogs a platform admits, and derives the composed transformers and the contract inventory from them.
_Avoid_: Environment, cluster, target

**#CatalogEntry**:
One slot of a `#Platform` registry. It admits a catalog by embedding the imported catalog value whole.
_Avoid_: Subscription, catalog reference

**#ContractInventory**:
The report a `#Platform` derives about which contracts its enabled catalogs define, which transformers require them, and which are unfulfilled, over-subscribed or colliding. It reports and never refuses.
_Avoid_: Contract registry, manifest

### Adapters and gates

**Adapter**:
A type that translates the model into target runtime form without taking part in composition. The only adapter is `#ComponentTransformer`; it carries no `apiVersion`.
_Avoid_: Plugin, driver

**#ComponentTransformer**:
An adapter that turns a matched `#Component` into platform objects (for example Kubernetes manifests). It names the contract keys a component must carry, and its `#transform` function produces the output.
_Avoid_: Renderer, provider, generator

**Implementation key**:
The `path/name@semver` key (an impl FQN) of a transformer; it names the build the transformer shipped in.
_Avoid_: FQN (unqualified), contract key

**Publish gate**:
A definition that a publishing tool unifies an artifact against, so that CUE's own error is the diagnostic. The gates are `#TraitOptionalGate`, `#IdentityPackage` and `#CatalogMemberFQNGate`; none is part of an artifact.
_Avoid_: Validator, linter, check

**#IdentityPackage**:
The shape of an artifact's committed `identity/identity.cue`: its complete module path and its SemVer. All other identity derives from these two values.
_Avoid_: Version file, manifest

### Naming and layering

**Name types**:
The three name types transcribe the Kubernetes validators: `#NameType` (DNS label), `#ObjectNameType` (DNS subdomain) and `#ServiceNameType` (RFC 1035 label). A primitive that renders a dot-restricted kind declares which one a component name must satisfy.
_Avoid_: Slug, identifier

**Layering contract**:
The rule set for which authoring layer (primitive schema, blueprint, module `#config`, module `#components`, transformer) may write bounds, narrowing, defaults or concrete data onto a component field. CUE cannot enforce it; catalogs and publish tools do.
_Avoid_: Override order, precedence rules
