# OPM Core Schema Specification

**Status**: Living document. Authored alongside the schema and gated by `task spec:check`.
**Source of truth**: When this document and the `.cue` files disagree, **the schema wins**. File an issue.
**Module**: `opmodel.dev/core@v1`

This specification is the normative reference for the OPM core schema — what each construct is, what constraints it enforces, and why those constraints take the form they do. It is the companion to the schema files (`*.cue`) and to the tutorial-flavoured material in `docs/`. The `.cue` files carry the contract; the `docs/` carry the explanation for newcomers; this specification carries the *rationale* for anyone evolving the schema.

## Conventions

The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

Each construct is described in four parts, in order:

- **Definition** — what the construct is and where it sits in the type system. Prose only.
- **Shape** — the CUE definition, simplified where helpful, with a link to the implementation.
- **Constraints** — observable rules that hold for every valid instance. Implementation-detail rules (such as a particular regex) are noted only when consumers see them.
- **Rationale** — bulleted *why* statements. Each bullet leads with **"Why X."** and anchors in a consequence or class-of-bug the rule prevents. Vacuous rationale ("for flexibility," "for consistency") is rejected at review.

Cross-references use `file.cue:line` against the repository at the tag in [`CHANGELOG.md`](CHANGELOG.md). Cross-references to peer constructs use the section number (e.g. §2.1).

---

## 1. Type System Overview

OPM Core distinguishes three categories of definition:

- **Primitives** (§2) — independently authored, independently versioned schema contracts: `#Resource`, `#Trait`, `#Secret`. Each carries its own `metadata`, its own versioned identity, and a `spec` schema namespaced under a camelCase form of its name.
- **Constructs** (§3) — framework types that compose, organize, carry, or publish primitives: `#Component`, `#Blueprint`, `#Module`, `#Platform`, `#ModuleInstance`, `#Catalog`. Constructs do not introduce new schema; they unify primitives into structured wholes (`#Component`, `#Module`, `#ModuleInstance`), organize them into platform-resolvable subscriptions (`#Platform`), or package them as a versioned publication artifact (`#Catalog`).
- **Adapters** (§4) — types that translate the model into target runtime form without participating in composition: `#ComponentTransformer`.

The Primitive/Construct split exists because primitives are the unit of *vocabulary* and constructs are the unit of *composition*. A platform team extends the vocabulary by authoring new primitives; an application team uses constructs to assemble them. Conflating the two would force every composition decision through a schema-publishing workflow.

The Adapter category exists because rendering is a *target-specific* concern. Forcing transformers into the composition graph would mean every primitive needs a target-specific arm — an explosion that doesn't compose. Adapters sit beside the model, not inside it.

`#Catalog` sits under Constructs (rather than as its own category) because it follows the same rule as every other construct: it introduces no new schema vocabulary, it organizes primitives. A `#Catalog` packages a versioned set of `#ComponentTransformer` values under one CUE module path so platforms can subscribe to it. Splitting consumption (`#Module`) from publication (`#Catalog`) gives each artifact one job — but both are constructs, not separate categories.

This v0 of the specification covers the primitives `#Resource` and `#Trait`, the constructs `#Component`, `#Blueprint`, `#Module`, `#Platform`, `#ModuleInstance`, and `#Catalog`, and the adapter `#ComponentTransformer`. Remaining constructs are documented in `docs/` and will land in this spec as the schema stabilises.

---

## 2. Primitives

### 2.1 `#Resource`

#### Definition

A `#Resource` represents a fundamental, deployable entity that must exist in the runtime environment. Resources are the *nouns* of OPM. Each Resource is standalone and has its own lifecycle: it can exist independently without requiring other definitions to make sense.

Examples: `Container`, `Volume`, `ConfigMap`, `Secret`.

#### Shape

```cue
#Resource: {
    kind: "Resource"

    metadata: {
        name!:       #NameType            // kebab-case
        modulePath!: #PackagePathType     // e.g. "opmodel.dev/opm/resources/workload"
        version!:    #VersionType         // SemVer 2.0, e.g. "1.4.0"
        fqn:         "\(modulePath)/\(name)@\(version)"

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // MUST be OpenAPIv3-compatible, namespaced under camelCase(name).
    spec!: (strings.ToCamel(metadata.#definitionName)): _
}
```

Implementation: [`resource.cue`](src/resource.cue).

#### Constraints

- `kind` MUST be the literal string `"Resource"`. Downstream tools dispatch on this field.
- `metadata.name` MUST be kebab-case (`#NameType` regex, max 63 runes) and MUST be unique within its `modulePath`.
- `metadata.modulePath` MUST be a `#PackagePathType` — a package path inside a module, carrying no `@vN` major suffix. A value carrying one MUST be rejected. This is the type `#ModulePathType` carried before enhancement 0010 D1, so no primitive value shipped by any catalog changes.
- `metadata.version` MUST be a SemVer 2.0 string (`#VersionType`), not a MAJOR-only prefix. The published FQN carries the exact patch the catalog stamped at publish time.
- `metadata.fqn` is computed from `modulePath`, `name`, and `version`. Consumers MUST NOT supply `fqn` directly. The computed FQN MUST match `#FQNType` (SemVer-suffixed).
- `spec` MUST be present, MUST have exactly one top-level field, and that field's name MUST equal `camelCase(metadata.name)`. The schema under that field MUST be expressible in OpenAPI v3.

#### Rationale

- **Why `kind` is a fixed string and not implicit from the type.** CUE definitions do not carry type information at runtime. Downstream tools walking a rendered tree need a discriminator to route handlers; `kind` is that discriminator. Removing it would force every consumer to do structural detection, which is brittle.
- **Why `fqn` is computed, not stored.** The fully-qualified name is a function of three other fields. Storing it would allow drift between the stated identity and its parts. Computing it makes the schema the single source of identity truth — an instance of Principle III (Determinism).
- **Why a primitive's path is `#PackagePathType` and not the `#ModulePathType` an artifact declares.** Enhancement 0010 D1 makes `#ModulePathType` an artifact's *complete* CUE module path, `@vN` included, so that `#Module` and `#Catalog` can be addressed by reading one field. A primitive inherits nothing useful from that suffix: it is a package *inside* a module, and its major is structurally redundant — a `@vN` module publishes only `vN.*` tags, so a primitive already stating its catalog's build version has already stated its catalog's major. It is also not a path anyone writes, since a consumer imports `opmodel.dev/catalogs/opm/resources` with no suffix and CUE resolves the major from `cue.mod`'s `deps`. An earlier revision of D1 widened one shared type for both; every field typed with it then inherited a major with no referent, and D20 (merged into D1) split it in two instead.
- **Why `version` is exact SemVer, not a MAJOR-only prefix.** Two builds of the same primitive at adjacent versions (e.g. `1.0.0` and `1.0.1`) must occupy distinct keys so the kernel matcher can compare definitions deterministically. The previous MAJOR-only scheme collapsed every patch into one bucket and let two divergent definitions at the same `@v1` silently coexist — the worst failure mode for a vocabulary. Catalog-monolithic SemVer (every primitive's version equals the publishing catalog's version) keeps version churn coordinated; consumer-pin churn is mitigated by always-on unification at match time (byte-identical bodies unify across SemVers, and platform subscriptions express SemVer ranges that span many versions). See enhancement 0001 D5 and D18.
- **Why `spec` is namespaced under the definition's camelCase name.** When multiple primitives unify into a `#Component` (§3.1), their `spec` fields merge. Namespacing under the definition name prevents field-name collisions — two primitives both defining `port` would clash at the root but coexist under `container.port` and `service.port`. This pushes naming collisions to *definition time* (caught by CUE unification) rather than *deployment time* (silent merge).
- **Why we don't allow free-form CUE inside `spec`.** OpenAPI v3 is the contract surface for non-CUE consumers — Kubernetes CRDs, web UIs, kubectl plugins. CUE templating (`for`, `if`, comprehensions) would tie the schema to a CUE evaluator and exclude every consumer that uses the schema through generated bindings. Per Principle II (Type Safety First), this constraint is in the schema rather than relying on downstream rejection.

#### See also

- Tutorial: [`docs/primitives.md`](docs/primitives.md) (Resource section)
- Composed by: [`#Component`](#31-component)
- Modified by: [`#Trait`](#22-trait)

---

### 2.2 `#Trait`

#### Definition

A `#Trait` is a primitive that *modifies* a `#Component`'s behavior or surface without being a deployable thing in its own right. Traits are the *adjectives* of OPM. A Trait declares which `#Resource` kinds it can be applied to via `appliesTo`, and contributes a `spec` schema namespaced under a camelCase form of its name.

Examples: `scaling`, `health-check`, `network-expose`.

#### Shape

```cue
#Trait: {
    kind: "Trait"

    metadata: {
        name!:       #NameType            // kebab-case
        modulePath!: #PackagePathType     // e.g. "opmodel.dev/opm/traits/workload"
        version!:    #VersionType         // SemVer 2.0, e.g. "1.0.0"
        fqn:         "\(modulePath)/\(name)@\(version)"

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // MUST be OpenAPIv3-compatible, namespaced under camelCase(name).
    spec!: (strings.ToCamel(metadata.#definitionName)): _

    // Resources this Trait may modify.
    appliesTo!: [...#Resource]
}
```

Implementation: [`trait.cue`](src/trait.cue).

#### Constraints

- `kind` MUST be the literal string `"Trait"`.
- `metadata.name`, `metadata.modulePath`, `metadata.version`, `metadata.fqn` follow the same rules as `#Resource` (§2.1), with `version` as SemVer 2.0.
- `spec` MUST be present, MUST have exactly one top-level field, and that field's name MUST equal `camelCase(metadata.name)`. The schema under that field MUST be expressible in OpenAPI v3.
- `appliesTo` MUST list at least one `#Resource`. A Trait that applies to nothing is a category error.
- A Trait attached to a `#Component` whose `#resources` do not include any entry in `appliesTo` MUST fail at CUE unification.

#### Rationale

- **Why `appliesTo` is required and listed.** Traits modify the surface of specific Resources. Without `appliesTo` an author could attach `scaling` to a `Volume` and produce nonsense; with it, the mismatch surfaces at unification time rather than render time. The list shape lets a single Trait apply to a family of related Resources (e.g. `scaling` applies to `Container` and `Job`) without forcing N Trait copies.
- **Why Traits share the primitive-metadata shape (`name` + `modulePath` + `version` + computed `fqn`, plus optional `description` / `labels` / `annotations`) with `#Resource`.** Both are vocabulary primitives that catalogs version and publish; the kernel matcher walks both via the same FQN-keyed lookup. A divergent metadata shape would force the matcher to special-case each, which would invite drift. Per enhancement 0001 D5, the SemVer-FQN regime applies uniformly to every primitive.
- **Why we don't allow free-form CUE inside `spec`.** Same as `#Resource` (§2.1) — the OpenAPI v3 contract surface is for non-CUE consumers.

#### See also

- Tutorial: [`docs/primitives.md`](docs/primitives.md) (Trait section)
- Modifies: [`#Resource`](#21-resource)
- Composed by: [`#Component`](#31-component)

---

## 3. Constructs

### 3.1 `#Component`

#### Definition

A `#Component` composes primitives — Resources, Traits, and Blueprints — into a single deployable unit. A Component is the smallest unit a `#Module` (§3.2) can ship.

Unlike a primitive, a Component does not introduce new schema. Its `spec` is the CUE unification of every attached primitive's `spec`, flattened into a single closed structure.

#### Shape

```cue
#Component: {
    kind: "Component"

    metadata: {
        name!:        #NameType
        resourceName: *name | #NameType     // defaults to metadata.name; override cascade
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    #resources:   #ResourceMap
    #traits?:     #TraitMap
    #blueprints?: #BlueprintMap

    // Instance context injected by the parent #Module's #components pattern
    // constraint. Hidden — authors never set this directly.
    #instance: #InstanceIdentity

    // Single source of truth for this component's computed names. DNS
    // variants derive from resourceName + #instance.namespace + clusterDomain.
    #names: {
        resourceName: metadata.resourceName
        dns: {
            short: resourceName
            local: "\(resourceName).\(#instance.namespace)"
            fqdn:  "\(resourceName).\(#instance.namespace).svc.\(#instance.clusterDomain)"
        }
    }

    // Computed: unification of every attached primitive's spec, closed.
    spec: close({ _allFields })
}
```

Implementation: [`component.cue`](src/component.cue).

#### Constraints

- `kind` MUST be the literal string `"Component"`.
- `metadata.resourceName` defaults to `metadata.name`. An explicit value wins via the disjunction-default cascade and MUST also satisfy `#NameType`.
- `#instance` is set by the parent `#Module` via its `#components` pattern constraint. Component authors MUST NOT set `#instance` directly; doing so collides with the module wiring and fails CUE unification.
- `#names` is the single source of truth for this component's identity. `#Module.#ctx.components.<id>` is a pure projection of every component's `#names` — there is no separate computation path.
- `#resources` SHOULD contain at least one entry (directly or via an attached `#Blueprint`). A Component composed of only Traits describes modifications to nothing — a category error not currently caught by the schema; it is rejected at downstream render time.
- A `#Trait` MUST only be attached to a Component whose Resources are listed in the Trait's `appliesTo`. Conflict surfaces at CUE unification time.
- Conflicting field definitions between attached primitives MUST fail at definition time. Consumers MUST NOT add post-hoc conflict resolution.
- `spec` is closed (`close(...)`). Consumers MUST NOT add fields to a Component's `spec` beyond what its primitives contribute.
- `metadata.labels` and `metadata.annotations` unify from every attached primitive. Conflicts MUST fail at unification.

#### Rationale

- **Why `spec` is computed via `_allFields` rather than authored.** Authoring `spec` directly would let a Component contradict the schemas its primitives declare. Computing it from the primitives' specs makes the primitives the single source of schema truth: a Component is exactly the sum of what it composes, nothing more, nothing less.
- **Why the spec is hidden behind `#resources` / `#traits` / `#blueprints` rather than flattened at the Component root.** If the primitives' specs flattened into the Component's root, the parent `#Module` definition would have to be opened (`...`) to accept arbitrary fields, which would defeat schema validation at the Module boundary. The hashed-field indirection (`#resources`, etc.) preserves Module-level closedness. This is recorded directly as a comment in [`component.cue:49-50`](src/component.cue) because future contributors hit it the moment they try to simplify the layout.
- **Why labels and annotations unify from primitives rather than being authored.** Same principle as `spec`: the primitives are the source of truth. A Component that contradicted its primitives' labels would be a lie about what's deployed. Per Principle II (Type Safety First), CUE catches the conflict at unification time rather than waiting for a runtime mismatch.
- **Why `resourceName` is a cascade on `metadata`, not a top-level field.** The default case ("the rendered resource shares the component's id") is by far the common one; authors should not have to write it. The override case ("rename the rendered resource without renaming the component") needs to be cheap because real deployments hit it constantly (legacy resource names, multi-instance suffixing). A `*name | #NameType` disjunction-default does both with one line and zero ceremony.
- **Why `#names` lives on the Component and `#ctx.components` is a projection.** Two principles. (1) The component is the thing that owns its identity — the value that ultimately renders is the one that says what its name is. (2) Projection-not-computation means there is only one place to look when reading or debugging a name; the module-level view is a comprehension, not an alternate calculation. See enhancement 0001 D2.
- **Why `#instance` is hidden and module-injected, not author-supplied.** Components are reusable across instances — the same component definition can be embedded in many `#ModuleInstance` values targeting different namespaces. If `#instance` were authored on the component, every instance would have to fork the component just to rewrite identity, which defeats reusability. Module-side injection via the `#components` pattern constraint keeps the instance identity flowing through a single wiring point. See enhancement 0001 D3.
- **Why we don't enforce "at least one Resource" in the schema.** The constraint is true in spirit (a Component with no Resource is undeployable) but CUE cannot ergonomically express "this map is non-empty" without sacrificing the open-map semantics that let platforms add resources at deploy time. The check sits at the render boundary instead. Documented here so future contributors don't reintroduce a schema-level emptiness check that breaks platform composition.

#### See also

- Tutorial: [`docs/constructs.md`](docs/constructs.md) (Component section)
- Composes: [`#Resource`](#21-resource), `#Trait` (forthcoming), `#Blueprint` (forthcoming)
- Composed by: [`#Module`](#32-module)

---

### 3.2 `#Module`

#### Definition

A `#Module` is the portable application blueprint — a developer's (or platform team's) description of an application as a graph of Components, optionally publishing additional primitives to the platform's registry. A Module describes *what* an application is; concrete values are supplied separately by `#ModuleInstance` (forthcoming).

A Module is the unit of versioning and distribution. A published Module at `example.com/modules/foo:1.2.3` is immutable.

#### Shape

```cue
#Module: {
    kind: "Module"

    metadata: {
        name!:          #NameType
        nameSnakeCase:  #SnakeNameType & (#KebabToSnake & {"in": name}).out  // derived: hyphens → underscores
        modulePath!:    #ModulePathType                                      // author-supplied in module.cue
        version!:       #VersionType                                         // author-supplied in module.cue
        fqn:            #ModuleFQNType & "\(modulePath)/\(name):\(version)"   // semver-with-colon
        uuid:           #UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Pattern constraint tightens the key to #NameType and wires the
    // module-level instance into every component.
    #components: [Id=#NameType]: #Component & {
        metadata: name: string | *Id
        #instance: #ctx.instance
    }

    #config:     _   // OpenAPI v3 schema; no CUE templating
    debugValues: _   // example values for testing/tooling

    // Inline runtime context channel. `instance` is set by #ModuleInstance;
    // `components` is a pure CUE projection over every #Component.#names.
    // The trailing `...` keeps the channel open for future siblings.
    #ctx: {
        instance: #InstanceIdentity
        components: { for id, c in #components { (id): c.#names } }
        ...
    }
}
```

Implementation: [`module.cue`](src/module.cue).

#### Constraints

- `kind` MUST be the literal string `"Module"`.
- `metadata.name` MUST be kebab-case (`#NameType`).
- `metadata.nameSnakeCase` is the snake_case projection of `name` (`#KebabToSnake`: hyphens replaced with underscores) and MUST satisfy `#SnakeNameType`. It is derived — consumers MUST NOT supply it directly. It is intended as the CUE-identifier-safe form of the module name (canonical CUE package name and registry-path leaf under the module publishing convention).
- `metadata.modulePath` (`#ModulePathType`) and `metadata.version` (`#VersionType`) are author-supplied: a Module MUST declare them in its own `module.cue`, the same way `#Resource`, `#Trait`, `#Blueprint`, and `#Catalog` declare their identity. Both are required (`!`); a `#Module` value missing either is incomplete and cannot compute `fqn`/`uuid`.
- `metadata.fqn` uses semver-with-colon (`modulePath/name:version`), distinct from `#Resource`'s `@v0` major-version separator. Consumers MUST NOT supply `fqn` directly.
- `metadata.uuid` is computed as `SHA1(OPMNamespace, fqn)`. It is deterministic and stable across evaluations.
- `#components` is required but MAY be empty for a Module that ships only as a configuration shape. Keys MUST satisfy `#NameType`.
- Every entry in `#components` receives `#instance` from `#ctx.instance` via the pattern constraint. The component's `#names` block computes `resourceName` and DNS variants from this injected instance. Authors MUST NOT set `#instance` on a component directly.
- `#ctx.instance` MUST be set by the consuming `#ModuleInstance` (§…). A `#Module` value with `#ctx.instance` left non-concrete is a spec — usable for typing and validation, but not renderable.
- `#ctx.components` is a pure CUE comprehension over `#components`; it cannot be authored independently of the component set. Drift between a component's `#names` and the projection is therefore impossible at the schema layer.
- The top of `#ctx` is open (`...`). Future enhancements MAY add sibling fields (`platform`, `environment`) without invalidating existing module bodies.
- `#config` MUST be expressible in OpenAPI v3. CUE templating constructs (`for`, `if`, comprehensions) MUST NOT appear. This rule is enforced downstream (the library's render pipeline) rather than at the schema layer.
- `debugValues` SHOULD satisfy `#config` and is validated at runtime by the schema fixture harness.

#### Rationale

- **Why `modulePath` / `version` are author-supplied typed-required fields, not self-referential.** Earlier revisions declared them `modulePath: metadata.modulePath` / `version: metadata.version` — a bare-direct self-cycle that resolves to itself, contributing neither a value nor a constraint. CUE never registers a cycle-only field as a permitted member of the *closed* `#Module`, so re-unifying an already-closed published `#Module` into `#ModuleInstance.#module` (the authored-`instance.cue` import path) rejected the concrete `modulePath`/`version` as "field not allowed." The bug was invisible to `cue vet` because a standalone Module is only closed once. Declaring them `!: #ModulePathType` / `!: #VersionType` — the form every sibling identity-bearing construct already uses — makes them genuine permitted fields, fixes the re-unification, and adds real format validation the self-cycle silently skipped.
- **Why `metadata.nameSnakeCase` exists as a derived field.** `#NameType` is kebab-case (RFC 1123 DNS-label), but a CUE package name and a CUE registry-path leaf must be valid CUE identifiers — which forbid hyphens. Authors therefore publish hyphenated-named modules under an underscored path/package (e.g. name `zot-registry-ttl` published at `…/zot_registry_ttl`), and the two forms drift. Deriving the snake_case form in the schema gives every consumer one authoritative, deterministic projection of the name into identifier space, rather than each re-implementing `strings.Replace(name, "-", "_")` and risking divergence. It is a *projection of name*, not an independent field, so it cannot disagree with `name`. The companion module publishing convention (see `enhancements/`) builds the canonical registry path on `modulePath/nameSnakeCase` so an imported module is resolvable from its metadata alone.
- **Why `fqn` uses semver-with-colon while `#Resource` uses `@vN`.** Modules ship at specific versions (`1.2.3`); the consumer pins an exact release and migrates deliberately. Resources version on the contract surface (`v1`, `v2`); the consumer pins a contract major and treats patches as the publisher's concern. Different identity granularity, different separator — the visual distinction prevents confusion when both appear in a config tree.
- **Why `uuid` is computed via `SHA1(OPMNamespace, fqn)` rather than authored or random.** Per Principle III (Determinism), two evaluations of the same `fqn` MUST yield the same identity. A registry, controller, or cluster can dedupe modules by uuid without coordinating an ID allocator. The schema fixture harness in `library/` pins a known uuid as a drift sentinel for the algorithm itself.
- **Why `#config` is bare `_` and not a typed schema.** The configuration shape is per-module — every module's contract is different. Constraining `#config` at the core layer would either force a one-size-fits-all schema (too narrow) or accept everything (no value). The OpenAPI-v3 constraint is enforced by the downstream renderer, which has the context to apply it cleanly.
- **Why no CUE templating in `#config`.** The config schema is the module's *public contract*. It travels with the published module via the OCI registry and is read by non-CUE consumers — web UIs rendering forms, kubectl plugins generating prompts, generated bindings in other languages. CUE templating would tie the schema to a CUE evaluator and exclude every one of those consumers. Per Principle I (Contract Stability), the schema must not assume a particular consumer.
- **Why publication moved out of `#Module`.** The pre-0001 schema overloaded `#Module.#defines` to publish primitives to platforms. That conflated two roles — a leaf application has no publication intent; a catalog has no `#components` to render. Enhancement 0001 split the roles: `#Module` is the consumer artifact (only `#components` + `#config` + `debugValues` + `#ctx`), and [`#Catalog`](#36-catalog) is the publication artifact. A catalog need not carry application context; a module need not carry vocabulary surface.
- **Why `#ctx` is inline on `#Module` and not a wrapper type.** Modules carry deployment context — instance identity, per-component names, future siblings like platform / environment — through evaluation. Wrapping the module in a separate builder type would force every consumer (renderer, validator, debug tool) to unwrap before reading the module. An inline `#ctx` slot keeps the module a single value with a context channel exposed alongside the components map. The open top (`...`) reserves room for additive siblings without breaking existing values. See enhancement 0001 D1.
- **Why `#ctx.components` is a projection, not an authored map.** Every component's `#names` block is the single source of truth for that component's identity. If `#ctx.components` were authored independently it could disagree with the component's own `#names` — exactly the silent-drift failure mode the schema should make impossible. Modeling it as a CUE comprehension makes drift inexpressible: the projection IS the components' names. See enhancement 0001 D2.
- **Why the `#components` pattern injects `#instance` instead of leaving it for `#ModuleInstance`.** A `#ModuleInstance` sets `#module.#ctx.instance` once, at the module level. Without the pattern constraint, every component would have to thread `#instance` from `#ctx.instance` in author code — which is ceremony for the common case and an invitation for typos. The pattern constraint makes the wiring structural: the moment a value enters `#components`, it carries `#instance: #ctx.instance`. See enhancement 0001 D3.

#### See also

- Tutorial: [`docs/constructs.md`](docs/constructs.md) (Module section)
- Composes: [`#Component`](#31-component), [`#Resource`](#21-resource), [`#Trait`](#22-trait), [`#ComponentTransformer`](#41-componenttransformer)
- Instantiated by: `#ModuleInstance` (forthcoming)

---

### 3.3 `#Blueprint`

#### Definition

A `#Blueprint` is a reusable composition of `#Resource` and `#Trait` primitives into a higher-level abstraction that a `#Component` can attach as a single unit. Blueprints are versioned and shipped by catalogs alongside the primitives they compose.

Examples: `stateless-workload`, `stateful-workload`, `cronjob`.

#### Shape

```cue
#Blueprint: {
    kind: "Blueprint"

    metadata: {
        name!:       #NameType            // kebab-case
        modulePath!: #PackagePathType     // e.g. "opmodel.dev/opm/blueprints/workload"
        version!:    #VersionType         // SemVer 2.0, e.g. "1.0.0"
        fqn:         "\(modulePath)/\(name)@\(version)"

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    composedResources!: [...#Resource]
    composedTraits?:    [...#Trait]

    // MUST be OpenAPIv3-compatible, namespaced under camelCase(name).
    spec!: (strings.ToCamel(metadata.#definitionName)): _
}
```

Implementation: [`blueprint.cue`](src/blueprint.cue).

#### Constraints

- `kind` MUST be the literal string `"Blueprint"`.
- `metadata` follows the primitive-metadata shape (`name` + `modulePath` + `version` + computed `fqn`, plus optional `description` / `labels` / `annotations`) (same rules as `#Resource` and `#Trait`), with `version` as SemVer 2.0.
- `composedResources` MUST list at least one `#Resource`. A Blueprint that composes nothing is a category error.
- `composedTraits` is optional. A Trait listed here MUST have a `#Resource` from `composedResources` in its `appliesTo`, otherwise unification fails.
- `spec` MUST be present, MUST have exactly one top-level field, and that field's name MUST equal `camelCase(metadata.name)`. The schema under that field MUST be expressible in OpenAPI v3.

#### Rationale

- **Why Blueprints share the primitive-metadata shape with `#Resource` and `#Trait`.** Blueprints are shipped by catalogs, FQN-keyed, and version in lockstep with the primitives they compose (enhancement 0001 D21). A divergent metadata shape would force every catalog tool to special-case Blueprints. The shared FQN regex and identical metadata layout keep every primitive-shaped artifact discoverable through the same machinery.
- **Why Blueprints sit under Constructs and not Primitives.** A Blueprint adds no new vocabulary — its `spec` is the composition of fields its underlying Resources and Traits already declare. It is composition packaged for reuse, not a new noun. The categorical line is "does this introduce schema vocabulary?" — Resources and Traits do; Blueprints do not.
- **Why `composedResources` is required and listed, while `composedTraits` is optional.** A Blueprint with no Resource composes nothing renderable. Traits modify Resources, so a Resource-only Blueprint (`headless-workload`-style) is meaningful; a Trait-only Blueprint is the same category error as a Trait with empty `appliesTo`.

#### See also

- Tutorial: [`docs/constructs.md`](docs/constructs.md) (Blueprint section)
- Composes: [`#Resource`](#21-resource), [`#Trait`](#22-trait)
- Attached by: [`#Component`](#31-component)

---

### 3.4 `#Platform`

#### Definition

A `#Platform` is a path-keyed registry of *subscriptions* to catalogs plus the kernel-filled materialization slots the matcher uses at compile time. Authors write the subscription map; the kernel's `Materialize` step resolves every subscription against the OCI registry, indexes the transformers it pulls into `#composedTransformers`, and computes a `#matchers` reverse index from primitive FQN to candidate transformer.

A `#Platform` value is therefore a *spec* (what to pull, what to allow / deny) plus a place for the kernel to write its materialization output. The match-time evaluation runs against the materialized twin, not the raw spec.

#### Shape

```cue
#Platform: {
    kind: "Platform"

    metadata: {
        name!:        #NameType
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    type!: string

    // Path-keyed: map key is the catalog's CUE module path.
    // Exactly one subscription per path (CUE map semantics).
    #registry: [Path=#ModulePathType]: #Subscription

    // Kernel-filled after Materialize. Both optional because the
    // CUE-level value is a spec; the kernel populates them on the
    // materialized twin.
    #composedTransformers?: #TransformerMap
    #matchers?: {
        resources: [#FQNType]: [...#ComponentTransformer]
        traits:    [#FQNType]: [...#ComponentTransformer]
    }
}

#Subscription: {
    enable:  bool | *true
    filter?: #SubscriptionFilter
}

#SubscriptionFilter: {
    range?: string             // SemVer constraint expression
    allow?: [...#VersionType]
    deny?:  [...#VersionType]
}
```

Implementation: [`platform.cue`](src/platform.cue).

#### Constraints

- `kind` MUST be the literal string `"Platform"`.
- `metadata.name` MUST be kebab-case (`#NameType`).
- `type` MUST be present. The value is informational at this stage — the matcher does not consult it.
- `#registry` keys MUST be `#ModulePathType` strings (the catalog package's CUE module path). Since enhancement 0010 D1 that type carries a terminal `@vN`, so a key names one major of one catalog (`"opmodel.dev/catalogs/opm@v1"`) and a platform MAY subscribe to two majors of the same catalog as two distinct entries. One subscription per key is enforced by CUE map semantics; multi-channel-per-key is intentionally not expressible.
- `#Subscription.enable` defaults to `true`. When `false`, the kernel SHOULD skip materialization for that path; primitives owned by the path do not surface on the platform.
- `#SubscriptionFilter.range`, when present, MUST be a SemVer constraint expression parseable Go-side (the kernel uses Masterminds/semver). An unparseable expression surfaces as a structured `MaterializeError` against the offending subscription path.
- Filter resolution order: `range` restricts the candidate set, `allow` force-includes specific SemVers, `deny` force-excludes them. The final survivor set is materialized.
- `#composedTransformers` and `#matchers` are kernel-filled output slots. Authors MUST NOT supply them; doing so would let an author override what the registry actually published. Both are optional at the CUE level because the spec value carries them empty.

#### Rationale

- **Why subscriptions instead of inline module registrations.** The pre-0001 design forced a platform to embed concrete `#Module` values keyed by an arbitrary author-chosen `Id`. That meant: (a) the platform spec bundled the entire transitive content of every catalog it consumed, not just the intent to consume it; (b) multi-tenant platforms couldn't express "pull a SemVer range from this catalog, force-include this fix" without authoring every concrete version inline. Subscriptions move pull intent into a small declarative shape (path + filter) and let the kernel materialize against the registry. See enhancement 0001 D13.
- **Why the registry map is path-keyed, not Id-keyed.** A catalog has exactly one CUE module path. Keying on path lets CUE's map-uniqueness semantics enforce "one subscription per catalog" structurally — two declarations at the same key unify, divergent declarations fail. Id-keying admitted "two subscriptions for the same catalog under different names" silently, which is meaningless and a common author error.
- **Why `#composedTransformers` and `#matchers` are optional kernel-filled slots, not CUE comprehensions.** Materialize pulls remote artifacts from OCI — it cannot be a pure CUE comprehension over an in-memory `#registry`. Modeling these as optional fields lets the CUE-level spec remain valid without materialization, while the materialized twin (built by the kernel after fetching) carries the populated values. The alternative — making them required — would force every author to construct a "materialized" view in CUE by hand, defeating the purpose. See enhancement 0001 D14.
- **Why `#knownResources` and `#knownTraits` are removed.** Both were eager projections that flattened every catalog's primitives into a flat map on the platform. They duplicated information the matcher could (and now does) reach transitively via each transformer's required/optional maps. Removing them eliminates a sync point that always lagged the materialized transformer set.
- **Why the filter has three independent levers (`range` + `allow` + `deny`).** Real upgrade flows mix continuous and discrete decisions: "track 1.x" is a range; "but pin 1.4.2 because 1.5 has a regression" is an allow; "skip 1.4.0 — it was yanked" is a deny. Modeling all three lets a platform team express the upgrade policy without dropping into imperative escape hatches. The ordered resolution (range → allow → deny) gives deterministic results when the levers overlap.

#### See also

- Tutorial: forthcoming
- Subscribes to: [`#Catalog`](#36-catalog)
- Materialized for: `#Module` matching at compile time

---

### 3.5 `#ModuleInstance`

#### Definition

A `#ModuleInstance` is the concrete deployment instance — a `#Module` paired with the values that satisfy its `#config`, plus the instance-scoped identity (name, namespace, uuid, cluster domain) that flows into every component as `#ctx.instance`. A `#ModuleInstance` is what an operator, CI pipeline, or controller actually renders into platform-specific resources.

Renamed from `#ModuleRelease` (enhancement 0002).

The Module is the contract; the Instance is the instance.

#### Shape

```cue
#ModuleInstance: {
    kind: "ModuleInstance"

    metadata: {
        name!:         #NameType
        namespace!:    #NameType
        clusterDomain: string | *"cluster.local"
        uuid:          #UUIDType & SHA1(OPMNamespace, "<module.uuid>:<name>:<namespace>")
        labels?:       #LabelsAnnotationsType
        annotations?:  #LabelsAnnotationsType
    }

    // The Module to deploy, with its #ctx.instance wired from this Instance's
    // metadata. Every #Component under #module receives the instance identity
    // via the module's #components pattern constraint — so #names, DNS
    // variants, etc. compute automatically per component.
    #module!: #Module & {
        #ctx: instance: {
            name:          metadata.name
            namespace:     metadata.namespace
            uuid:          metadata.uuid
            clusterDomain: metadata.clusterDomain
        }
    }

    // The module's own components, verbatim. Core injects nothing.
    components: { ... }

    values: _   // concrete values satisfying #module.#config
}
```

Implementation: [`module_instance.cue`](src/module_instance.cue).

#### Constraints

- `kind` MUST be the literal string `"ModuleInstance"`.
- `metadata.name` and `metadata.namespace` MUST be kebab-case (`#NameType`).
- `metadata.clusterDomain` MUST be a non-empty string. The default `"cluster.local"` covers the standard Kubernetes case; override per instance when the target cluster runs a non-standard domain.
- `metadata.uuid` is deterministic: `SHA1(OPMNamespace, "<module-uuid>:<name>:<namespace>")`. Two evaluations with the same Module + name + namespace MUST yield the same uuid.
- `#module.#ctx.instance` MUST be set from `metadata.{name, namespace, uuid, clusterDomain}`. The wiring is declared inline in the schema; authors do not call a builder.
- `values` MUST satisfy `#module.#config`. CUE unification enforces this at evaluation time.
- `components` MUST be exactly the module's `#components`. Core MUST NOT synthesise, inject, or reserve any component name; a module whose config carries `#Secret` fields MUST declare its own secrets component against its catalog's secrets resource.

#### Rationale

- **Why `clusterDomain` lives on `#InstanceIdentity` and not buried inside a runtime context type.** A FQDN like `service.namespace.svc.cluster.local` is computed once per instance: every component's `#names.dns.fqdn` consumes it. Putting `clusterDomain` on the instance identity gives one overridable home — an instance on a `cluster.example.com` cluster sets it once, and every component's FQDN follows. Burying it inside a separate runtime-context type would force every consumer to traverse two levels of indirection to read a single string. See enhancement 0001 D4.
- **Why `#ModuleInstance` sets `#ctx.instance` inline and ships no builder.** The pre-0001 sketches considered a separate context-builder type that would take metadata and produce a context value. Two arguments against: (1) the wiring is one struct expression — a builder adds a type and a function call to do what one inline literal does already; (2) builders introduce evaluation order ("call builder before evaluating module") that pure CUE doesn't have. Setting `#ctx.instance` inline keeps the module + instance pair as one CUE value with no procedural dependency. See enhancement 0001 D1.
- **Why `#module.#ctx.instance` is set inside the `#module` unification, not on `#module.#ctx` after the fact.** Unification is associative and commutative — the order in which fields land doesn't matter. Setting it inside the `#module: #Module & {...}` expression makes the wiring textually adjacent to the module reference, so a reader sees both pieces at the same scroll position. The alternative ("set #module first, then patch #module.#ctx.instance") is the same CUE value but harder to read.
- **Why `uuid` is computed deterministically from module + name + namespace.** An instance's identity must be reproducible across evaluations of the same inputs: a controller restarting, a CI pipeline retrying, a kubectl apply re-running. Random or author-supplied uuids drift between runs and force every consumer to track a separate "is this the same instance?" signal. The SHA1-of-FQN form derives the answer from the inputs themselves. Same principle as `#Module.metadata.uuid` (§3.2 rationale).
- **Why core no longer injects an `opm-secrets` component.** Earlier revisions discovered every `#Secret` in the resolved config and synthesised a component carrying a secrets resource, so that modules got Secret objects for free. That required core to name the resource's FQN, and transformer matching is exact-FQN: a catalog stamps its own version into every FQN it publishes (`…/resources/secrets@1.0.0-alpha.2`), a value core cannot know and must not guess. The hardcoded constant went stale the moment the catalogs moved to the `@v1` line, and the synthesised component then matched no transformer at all — turning a convenience into a hard render failure for every secret-bearing module. Discovery itself was never the problem and stays available: catalogs re-export `#AutoSecrets`, so a module writes one component and keeps the ergonomics without core guessing at another package's identity.

#### See also

- Tutorial: [`docs/constructs.md`](docs/constructs.md) (ModuleInstance section, forthcoming)
- Instantiates: [`#Module`](#32-module)
- Sets context for: every [`#Component`](#31-component) under `#module.#components`

---

### 3.6 `#Catalog`

#### Definition

A `#Catalog` is the construct a catalog package exports to publish its primitives — primarily its `#ComponentTransformer` set — into a versioned, registry-resolvable artifact. It collapses what used to be a `#Module.#defines` block plus author-discipline conventions into one typed value with schema-enforced lockstep on transformer metadata.

A `#Catalog` introduces no new vocabulary itself — like every other construct (§3), it organizes primitives into a structured whole. Where `#Module` carries a set of components to render, `#Catalog` carries a set of transformers to publish. Both are constructs; their difference is which artifact they ship.

The catalog's identity is its `metadata.modulePath` + SemVer `metadata.version`. The kernel reads only `#Catalog.metadata` and `#Catalog.#transformers` at materialize time — there is no package walk, no auto-discovery.

#### Shape

```cue
#Catalog: {
    kind: "Catalog"

    M=metadata: {
        modulePath!:  #ModulePathType
        version!:     #VersionType | *"0.0.0-dev"   // source-tree default
        fqn:          "\(modulePath)@\(version)"
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Every entry's metadata.modulePath is stamped to
    //   "<catalog modulePath>/transformers"
    // and metadata.version is stamped to the catalog's version.
    // Pattern enforced by the schema, not by author discipline.
    #transformers: [#FQNType]: #ComponentTransformer & {
        metadata: {
            modulePath: "\(M.modulePath)/transformers"
            version:    M.version
        }
    }
}
```

Implementation: [`catalog.cue`](src/catalog.cue).

#### Constraints

- `kind` MUST be the literal string `"Catalog"`.
- `metadata.modulePath` MUST be the catalog package's CUE module path (e.g. `opmodel.dev/catalogs/opm`). The publish task is the source of truth for this value at publish time.
- `metadata.version` defaults to `"0.0.0-dev"` in a source tree so `cue vet` is cheap during development. At publish time it MUST be overwritten with a concrete SemVer via a `version_override.cue` file in the sibling `identity/` subpackage; OCI artifacts ship fully concrete.
- `metadata.fqn` is computed from `modulePath` and `version`; consumers MUST NOT supply it.
- Every entry in `#transformers` MUST be keyed by a valid `#FQNType` (SemVer-suffixed primitive FQN). The pattern constraint on `#transformers` stamps every entry's `metadata.modulePath` to `"<catalog modulePath>/transformers"` and every entry's `metadata.version` to the catalog's version. An author who writes a divergent value for either field MUST get a `cue vet` failure with "conflicting values" — not a silent override.
- The pattern does NOT stamp `metadata.fqn` — fqn derives in the transformer's metadata from `modulePath/name/version`, and the map key already carries the transformer's own fqn by construction. Stamping it would be a no-op or a conflict.
- Resources, Traits, and Blueprints are NOT enumerated in `#Catalog`. They surface transitively via each transformer's `requiredResources` / `requiredTraits` maps and via standard CUE imports for direct references.

#### Rationale

- **Why a single `#Catalog` construct instead of a `#Module.#defines` block.** The pre-0001 design overloaded `#Module` to act as both a consumer artifact (declares components) and a publisher artifact (defines primitives). A catalog has no `#components` to render — it only publishes vocabulary. Collapsing both responsibilities into one type forced every catalog to ship the consumer surface (and vice versa). Splitting them gives `#Module` one role (consume) and `#Catalog` one role (publish). Both remain constructs — they organize primitives, they don't introduce schema vocabulary. See enhancement 0001 D19.
- **Why the `M=metadata` field-label alias.** The pattern constraint on `#transformers` needs to reach the outer catalog's `modulePath` and `version` from inside the nested `metadata: { ... }` block of every entry. A bare `metadata.modulePath` reference inside the entry's own metadata walks to the closest parent field named `metadata` — the inner field itself — and self-embeds into a non-concrete interpolation. CUE's value-alias form (`metadata: M={...}`) does not carry across the nested constraint boundary; only the field-label alias form does. Experiment 09 in the enhancement validated both sound forms (hidden-mirror + label-alias); the label-alias is chosen here for inline locality. See enhancement 0001 D25.
- **Why the pattern stamps `modulePath` + `version` but not `fqn`.** Stamping `modulePath` and `version` replaces the prior author-discipline rule ("every transformer's metadata must match the catalog's version") with a structural guarantee that `cue vet` enforces. The transformer's `metadata.fqn` derives in its own definition from those three fields, so stamping it would either be redundant (matches) or produce a conflict (author-supplied fqn diverges). Experiment 10 confirmed the asymmetry: a wrong `modulePath` or `version` fails vet loudly; trying to stamp fqn introduces conflicts on round-tripped FQNs.
- **Why catalogs don't enumerate Resources / Traits / Blueprints.** A transformer's `requiredResources` / `requiredTraits` already names every primitive the matcher needs to reach. Adding sibling `#resources` / `#traits` / `#blueprints` maps on `#Catalog` would duplicate that information and invite drift between the enumeration and the transitive set. If introspection demand surfaces later, the sibling maps are an additive extension — not a precondition.
- **Why `#CatalogFQNType` exists despite overlapping `#FQNType`.** A catalog's FQN is `modulePath@version` (no name segment); a primitive's FQN is `modulePath/name@version`. The two regexes are not structurally disjoint — a string like `opmodel.dev/catalogs/opm/transformer@1.0.0` matches both. They are distinguished by usage (which field they appear in), not by the regex alone. Naming the type makes the intent clear at the field site even if the regex doesn't enforce mutual exclusion.

#### See also

- Tutorial: forthcoming
- Publishes: [`#ComponentTransformer`](#41-componenttransformer)
- Consumed by: [`#Platform`](#34-platform) via `#registry` subscriptions

---

## 4. Adapters

### 4.1 `#ComponentTransformer`

#### Definition

A `#ComponentTransformer` translates a matched `#Component` into platform-specific output (e.g. Kubernetes manifests). It declares which primitives a Component must (or may) carry to be a candidate match, plus a `#transform` function that the runtime evaluates with concrete inputs.

Transformers are catalog-versioned. The match algorithm is FQN-keyed: each entry in `requiredResources` / `requiredTraits` names the exact `#FQNType` (SemVer-suffixed) the Component must surface for the transformer to consider it.

#### Shape

```cue
#ComponentTransformer: {
    kind: "ComponentTransformer"

    metadata: {
        name!:       #NameType
        modulePath!: #PackagePathType
        version!:    #VersionType         // SemVer 2.0
        fqn:         "\(modulePath)/\(name)@\(version)"

        description!: string              // required for catalog listings
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    requiredLabels?:    #LabelsAnnotationsType
    optionalLabels?:    #LabelsAnnotationsType
    requiredResources?: [#FQNType]: #Resource
    optionalResources?: [#FQNType]: #Resource
    requiredTraits?:    [#FQNType]: #Trait
    optionalTraits?:    [#FQNType]: #Trait

    readsContext?:  [...string]
    producesKinds?: [...string]

    #transform: {
        #moduleInstance: _
        #component:      _
        #context:        #TransformerContext

        output: {...} | [...{...}]
    }
}
```

Implementation: [`transformer.cue`](src/transformer.cue).

#### Constraints

- `kind` MUST be the literal string `"ComponentTransformer"`.
- `metadata.description` MUST be present and non-empty (it is the description surface for catalog listings and tooling).
- `metadata` follows the primitive-metadata shape (`name` + `modulePath` + `version` + computed `fqn`, plus optional `description` / `labels` / `annotations`) with `version` as SemVer 2.0; the computed `metadata.fqn` MUST match `#FQNType`.
- Every map key under `requiredResources` / `optionalResources` / `requiredTraits` / `optionalTraits` MUST be a valid `#FQNType` string. The map value's `metadata.fqn` MUST equal the key.
- A Transformer matches a Component when: all `requiredLabels` are present on the Component with matching values, every `requiredResources` FQN appears in the Component's `#resources`, and every `requiredTraits` FQN appears in the Component's `#traits`. The kernel matcher additionally unifies the consumer's primitive against the transformer's required slot at the same FQN; divergent definitions surface as a structured error per (component, FQN).
- `#transform.output` MUST be either a single struct (one rendered resource per match) or a list of structs (N rendered resources per match). Other CUE kinds are rejected by the renderer.

#### Rationale

- **Why match is FQN-keyed and always unifies.** Two builds of the same primitive at distinct SemVers are different keys now (enhancement 0001 D5), so a transformer requiring `…@1.0.0` is structurally distinct from one requiring `…@1.0.1`. But within a single FQN, the consumer Component may carry a slightly different definition body (drift, partial override). Always unifying the consumer's primitive against the transformer's required slot ensures that drift surfaces as a structured `UnifyError` per (component, FQN) pair rather than as a render-time mystery. See enhancement 0001 D6.
- **Why labels participate in matching but are inherited from primitives.** Component labels are not authored on the Component itself — they unify upward from every attached `#Resource`, `#Trait`, and `#Blueprint` (§3.1). This means a label-based match (e.g. `requiredLabels: {"core.opmodel.dev/workload-type": "stateless"}`) is a stable structural predicate the catalog can stamp on the primitive once and rely on, not a user-supplied free-text field. Conflating Component labels with author-supplied metadata would invite typos and silent misrouting.
- **Why `#transform.output` may be either a struct or a list.** Most transformers emit one rendered resource per match (`Deployment` per stateless workload, `Service` per network-expose Trait). Some emit a variable number derived from a Component-side map: a `ConfigMapTransformer` emits one `ConfigMap` per entry in a component's `config` map. A single shape would force the variable case into a struct-of-resources contortion; a list-only shape would force the single case into a one-element list. Two shapes is the smallest schema that doesn't lie.
- **Why we don't allow free-form CUE inside the transformer's output.** The renderer dispatches on `cue.Kind` — struct vs list — and never inspects field bodies. This keeps the kernel's render path agnostic to apply-layer conventions: a Kubernetes transformer's output is whatever the apply layer (kubectl, controller, gitops bridge) interprets, not whatever shape the core schema happens to know. Per Principle I (Contract Stability), the core schema must not assume a particular target.

#### See also

- Tutorial: [`docs/adapters.md`](docs/adapters.md) (forthcoming)
- Matches: [`#Component`](#31-component)
- Requires: [`#Resource`](#21-resource), [`#Trait`](#22-trait)
- Discovered via: [`#Catalog`](#36-catalog)

