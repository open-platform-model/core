# OPM Core Schema Specification

**Status**: Living document. Authored alongside the schema and gated by `task spec:check`.
**Source of truth**: When this document and the `.cue` files disagree, **the schema wins**. File an issue.
**Module**: `opmodel.dev/core@v0`

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
- **Constructs** (§3) — framework types that compose, organize, or carry primitives: `#Component`, `#Blueprint`, `#Module`, `#ModuleRelease`, `#Platform` (with `#ModuleRegistration`). Constructs do not introduce new schema; they unify primitives into structured wholes.
- **Adapters** (§4) — types that translate the model into target runtime form without participating in composition: `#ComponentTransformer`.

The Primitive/Construct split exists because primitives are the unit of *vocabulary* and constructs are the unit of *composition*. A platform team extends the vocabulary by authoring new primitives; an application team uses constructs to assemble them. Conflating the two would force every composition decision through a schema-publishing workflow.

The Adapter category exists because rendering is a *target-specific* concern. Forcing transformers into the composition graph would mean every primitive needs a target-specific arm — an explosion that doesn't compose. Adapters sit beside the model, not inside it.

This v0 of the specification covers the primitives `#Resource` and `#Trait`, the constructs `#Component`, `#Blueprint`, and `#Module`, and the adapter `#ComponentTransformer`. Remaining constructs are documented in `docs/` and will land in this spec as the schema stabilises.

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
        modulePath!: #ModulePathType      // e.g. "opmodel.dev/opm/resources/workload"
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
- `metadata.version` MUST be a SemVer 2.0 string (`#VersionType`), not a MAJOR-only prefix. The published FQN carries the exact patch the catalog stamped at publish time.
- `metadata.fqn` is computed from `modulePath`, `name`, and `version`. Consumers MUST NOT supply `fqn` directly. The computed FQN MUST match `#FQNType` (SemVer-suffixed).
- `spec` MUST be present, MUST have exactly one top-level field, and that field's name MUST equal `camelCase(metadata.name)`. The schema under that field MUST be expressible in OpenAPI v3.

#### Rationale

- **Why `kind` is a fixed string and not implicit from the type.** CUE definitions do not carry type information at runtime. Downstream tools walking a rendered tree need a discriminator to route handlers; `kind` is that discriminator. Removing it would force every consumer to do structural detection, which is brittle.
- **Why `fqn` is computed, not stored.** The fully-qualified name is a function of three other fields. Storing it would allow drift between the stated identity and its parts. Computing it makes the schema the single source of identity truth — an instance of Principle III (Determinism).
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
        modulePath!: #ModulePathType      // e.g. "opmodel.dev/opm/traits/workload"
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
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    #resources:   #ResourceMap
    #traits?:     #TraitMap
    #blueprints?: #BlueprintMap

    // Computed: unification of every attached primitive's spec, closed.
    spec: close({ _allFields })
}
```

Implementation: [`component.cue`](src/component.cue).

#### Constraints

- `kind` MUST be the literal string `"Component"`.
- `#resources` SHOULD contain at least one entry (directly or via an attached `#Blueprint`). A Component composed of only Traits describes modifications to nothing — a category error not currently caught by the schema; it is rejected at downstream render time.
- A `#Trait` MUST only be attached to a Component whose Resources are listed in the Trait's `appliesTo`. Conflict surfaces at CUE unification time.
- Conflicting field definitions between attached primitives MUST fail at definition time. Consumers MUST NOT add post-hoc conflict resolution.
- `spec` is closed (`close(...)`). Consumers MUST NOT add fields to a Component's `spec` beyond what its primitives contribute.
- `metadata.labels` and `metadata.annotations` unify from every attached primitive. Conflicts MUST fail at unification.

#### Rationale

- **Why `spec` is computed via `_allFields` rather than authored.** Authoring `spec` directly would let a Component contradict the schemas its primitives declare. Computing it from the primitives' specs makes the primitives the single source of schema truth: a Component is exactly the sum of what it composes, nothing more, nothing less.
- **Why the spec is hidden behind `#resources` / `#traits` / `#blueprints` rather than flattened at the Component root.** If the primitives' specs flattened into the Component's root, the parent `#Module` definition would have to be opened (`...`) to accept arbitrary fields, which would defeat schema validation at the Module boundary. The hashed-field indirection (`#resources`, etc.) preserves Module-level closedness. This is recorded directly as a comment in [`component.cue:49-50`](src/component.cue) because future contributors hit it the moment they try to simplify the layout.
- **Why labels and annotations unify from primitives rather than being authored.** Same principle as `spec`: the primitives are the source of truth. A Component that contradicted its primitives' labels would be a lie about what's deployed. Per Principle II (Type Safety First), CUE catches the conflict at unification time rather than waiting for a runtime mismatch.
- **Why we don't enforce "at least one Resource" in the schema.** The constraint is true in spirit (a Component with no Resource is undeployable) but CUE cannot ergonomically express "this map is non-empty" without sacrificing the open-map semantics that let platforms add resources at deploy time. The check sits at the render boundary instead. Documented here so future contributors don't reintroduce a schema-level emptiness check that breaks platform composition.

#### See also

- Tutorial: [`docs/constructs.md`](docs/constructs.md) (Component section)
- Composes: [`#Resource`](#21-resource), `#Trait` (forthcoming), `#Blueprint` (forthcoming)
- Composed by: [`#Module`](#32-module)

---

### 3.2 `#Module`

#### Definition

A `#Module` is the portable application blueprint — a developer's (or platform team's) description of an application as a graph of Components, optionally publishing additional primitives to the platform's registry. A Module describes *what* an application is; concrete values are supplied separately by `#ModuleRelease` (forthcoming).

A Module is the unit of versioning and distribution. A published Module at `example.com/modules/foo:1.2.3` is immutable.

#### Shape

```cue
#Module: {
    kind: "Module"

    metadata: {
        name!:       #NameType
        modulePath:  metadata.modulePath                                  // bound by the enclosing cue.mod
        version:     metadata.version                                     // bound by the enclosing cue.mod
        fqn:         #ModuleFQNType & "\(modulePath)/\(name):\(version)"  // semver-with-colon
        uuid:        #UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    #components: [Id=string]: #Component & { metadata: { name: string | *Id } }

    // Publication channel — primitives this module exposes to platforms.
    #defines?: {
        resources?:    [FQN=#FQNType]: #Resource             & { metadata: fqn: FQN }
        traits?:       [FQN=#FQNType]: #Trait                & { metadata: fqn: FQN }
        transformers?: [FQN=#FQNType]: #ComponentTransformer & { metadata: fqn: FQN }
    }

    #config: _      // OpenAPI v3 schema; no CUE templating
    debugValues: _  // example values for testing/tooling
}
```

Implementation: [`module.cue`](src/module.cue).

#### Constraints

- `kind` MUST be the literal string `"Module"`.
- `metadata.name` MUST be kebab-case (`#NameType`).
- `metadata.modulePath` and `metadata.version` MUST come from the enclosing CUE module identity (`cue.mod/module.cue`). Consumers MUST NOT override them in-file.
- `metadata.fqn` uses semver-with-colon (`modulePath/name:version`), distinct from `#Resource`'s `@v0` major-version separator. Consumers MUST NOT supply `fqn` directly.
- `metadata.uuid` is computed as `SHA1(OPMNamespace, fqn)`. It is deterministic and stable across evaluations.
- `#components` is required but MAY be empty for a Module that only publishes via `#defines`.
- Each map under `#defines` MUST be keyed by valid `#FQNType` strings. CUE unification binds `value.metadata.fqn` to the map key — a key/value mismatch is a CUE bottom (a compile-time error).
- `#config` MUST be expressible in OpenAPI v3. CUE templating constructs (`for`, `if`, comprehensions) MUST NOT appear. This rule is enforced downstream (the library's render pipeline) rather than at the schema layer.
- `debugValues` SHOULD satisfy `#config` and is validated at runtime by the schema fixture harness.

#### Rationale

- **Why `fqn` uses semver-with-colon while `#Resource` uses `@vN`.** Modules ship at specific versions (`1.2.3`); the consumer pins an exact release and migrates deliberately. Resources version on the contract surface (`v1`, `v2`); the consumer pins a contract major and treats patches as the publisher's concern. Different identity granularity, different separator — the visual distinction prevents confusion when both appear in a config tree.
- **Why `uuid` is computed via `SHA1(OPMNamespace, fqn)` rather than authored or random.** Per Principle III (Determinism), two evaluations of the same `fqn` MUST yield the same identity. A registry, controller, or cluster can dedupe modules by uuid without coordinating an ID allocator. The schema fixture harness in `library/` pins a known uuid as a drift sentinel for the algorithm itself.
- **Why FQN collisions in `#defines` surface as CUE bottoms.** Two modules defining the same FQN is the worst failure mode for a registry: silent shadowing means one module's behaviour is hidden by another's. CUE's map-key unification turns the collision into a compile-time bottom — caught at definition time, not at deploy time. This is called out as comment [`module.cue:48`](src/module.cue) ("FQN collisions across modules surface as CUE bottoms (D3)") because the property is load-bearing for the publication channel.
- **Why `#config` is bare `_` and not a typed schema.** The configuration shape is per-module — every module's contract is different. Constraining `#config` at the core layer would either force a one-size-fits-all schema (too narrow) or accept everything (no value). The OpenAPI-v3 constraint is enforced by the downstream renderer, which has the context to apply it cleanly.
- **Why no CUE templating in `#config`.** The config schema is the module's *public contract*. It travels with the published module via the OCI registry and is read by non-CUE consumers — web UIs rendering forms, kubectl plugins generating prompts, generated bindings in other languages. CUE templating would tie the schema to a CUE evaluator and exclude every one of those consumers. Per Principle I (Contract Stability), the schema must not assume a particular consumer.
- **Why `#components` and `#defines` are separated.** A Module has two surfaces: a *deployment* surface (its `#components` — what gets rendered when this module is released) and a *publication* surface (its `#defines` — primitives this module contributes to the platform's vocabulary). A module may have one without the other: a primitive library is `#defines`-only; a leaf application is `#components`-only. Conflating them would force every Module to commit to both roles and lose the distinction between consuming and publishing.

#### See also

- Tutorial: [`docs/constructs.md`](docs/constructs.md) (Module section)
- Composes: [`#Component`](#31-component), [`#Resource`](#21-resource), [`#Trait`](#22-trait), [`#ComponentTransformer`](#41-componenttransformer)
- Instantiated by: `#ModuleRelease` (forthcoming)

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
        modulePath!: #ModulePathType      // e.g. "opmodel.dev/opm/blueprints/workload"
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
        modulePath!: #ModulePathType
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
        #moduleRelease: _
        #component:     _
        #context:       #TransformerContext

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
