# OPM Core Schema Specification

**Status**: Living document. Authored alongside the schema and gated by `task spec:check`.
**Source of truth**: When this document and the `.cue` files disagree, **the schema wins**. File an issue.
**Module**: `opmodel.dev/core@v0`

This specification is the normative reference for the OPM core schema — what each construct is, what constraints it enforces, and why those constraints take the form they do. It is the companion to the schema files (`*.cue`) and to the tutorial-flavoured material in `docs/`. The `.cue` files carry the contract; the `docs/` carry the explanation for newcomers; this specification carries the *rationale* for anyone evolving the schema.

The schema is governed by [`CONSTITUTION.md`](CONSTITUTION.md). References to "Principle N" in this document point to numbered sections of that file.

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

This v0 of the specification covers `#Resource`, `#Component`, and `#Module`. Remaining constructs are documented in `docs/` and will land in this spec as the schema stabilises.

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
        version!:    #MajorVersionType    // e.g. "v1"
        fqn:         "\(modulePath)/\(name)@\(version)"

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // MUST be OpenAPIv3-compatible, namespaced under camelCase(name).
    spec!: (strings.ToCamel(metadata.#definitionName)): _
}
```

Implementation: [`resource.cue`](resource.cue).

#### Constraints

- `kind` MUST be the literal string `"Resource"`. Downstream tools dispatch on this field.
- `metadata.name` MUST be kebab-case (`#NameType` regex, max 63 runes) and MUST be unique within its `modulePath`.
- `metadata.version` MUST be a major version (`vN`), not a semver. Resources version on the compatibility surface, not the implementation revision.
- `metadata.fqn` is computed from `modulePath`, `name`, and `version`. Consumers MUST NOT supply `fqn` directly.
- `spec` MUST be present, MUST have exactly one top-level field, and that field's name MUST equal `camelCase(metadata.name)`. The schema under that field MUST be expressible in OpenAPI v3.

#### Rationale

- **Why `kind` is a fixed string and not implicit from the type.** CUE definitions do not carry type information at runtime. Downstream tools walking a rendered tree need a discriminator to route handlers; `kind` is that discriminator. Removing it would force every consumer to do structural detection, which is brittle.
- **Why `fqn` is computed, not stored.** The fully-qualified name is a function of three other fields. Storing it would allow drift between the stated identity and its parts. Computing it makes the schema the single source of identity truth — an instance of Principle III (Determinism).
- **Why `version` is a major version (`vN`), not semver.** Resources are the *vocabulary* of OPM. Two resources at `v1` and `v2` are distinct contracts that consumers must opt into. A semver patch is a property of the implementation publishing the resource, not of the contract; conflating the two would tie every dependent on the contract to the publisher's release cadence.
- **Why `spec` is namespaced under the definition's camelCase name.** When multiple primitives unify into a `#Component` (§3.1), their `spec` fields merge. Namespacing under the definition name prevents field-name collisions — two primitives both defining `port` would clash at the root but coexist under `container.port` and `service.port`. This pushes naming collisions to *definition time* (caught by CUE unification) rather than *deployment time* (silent merge).
- **Why we don't allow free-form CUE inside `spec`.** OpenAPI v3 is the contract surface for non-CUE consumers — Kubernetes CRDs, web UIs, kubectl plugins. CUE templating (`for`, `if`, comprehensions) would tie the schema to a CUE evaluator and exclude every consumer that uses the schema through generated bindings. Per Principle II (Type Safety First), this constraint is in the schema rather than relying on downstream rejection.

#### See also

- Tutorial: [`docs/primitives.md`](docs/primitives.md) (Resource section)
- Composed by: [`#Component`](#31-component)
- Modified by: `#Trait` (forthcoming section)

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

Implementation: [`component.cue`](component.cue).

#### Constraints

- `kind` MUST be the literal string `"Component"`.
- `#resources` SHOULD contain at least one entry (directly or via an attached `#Blueprint`). A Component composed of only Traits describes modifications to nothing — a category error not currently caught by the schema; it is rejected at downstream render time.
- A `#Trait` MUST only be attached to a Component whose Resources are listed in the Trait's `appliesTo`. Conflict surfaces at CUE unification time.
- Conflicting field definitions between attached primitives MUST fail at definition time. Consumers MUST NOT add post-hoc conflict resolution.
- `spec` is closed (`close(...)`). Consumers MUST NOT add fields to a Component's `spec` beyond what its primitives contribute.
- `metadata.labels` and `metadata.annotations` unify from every attached primitive. Conflicts MUST fail at unification.

#### Rationale

- **Why `spec` is computed via `_allFields` rather than authored.** Authoring `spec` directly would let a Component contradict the schemas its primitives declare. Computing it from the primitives' specs makes the primitives the single source of schema truth: a Component is exactly the sum of what it composes, nothing more, nothing less.
- **Why the spec is hidden behind `#resources` / `#traits` / `#blueprints` rather than flattened at the Component root.** If the primitives' specs flattened into the Component's root, the parent `#Module` definition would have to be opened (`...`) to accept arbitrary fields, which would defeat schema validation at the Module boundary. The hashed-field indirection (`#resources`, etc.) preserves Module-level closedness. This is recorded directly as a comment in [`component.cue:49-50`](component.cue) because future contributors hit it the moment they try to simplify the layout.
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

Implementation: [`module.cue`](module.cue).

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
- **Why FQN collisions in `#defines` surface as CUE bottoms.** Two modules defining the same FQN is the worst failure mode for a registry: silent shadowing means one module's behaviour is hidden by another's. CUE's map-key unification turns the collision into a compile-time bottom — caught at definition time, not at deploy time. This is called out as comment [`module.cue:48`](module.cue) ("FQN collisions across modules surface as CUE bottoms (D3)") because the property is load-bearing for the publication channel.
- **Why `#config` is bare `_` and not a typed schema.** The configuration shape is per-module — every module's contract is different. Constraining `#config` at the core layer would either force a one-size-fits-all schema (too narrow) or accept everything (no value). The OpenAPI-v3 constraint is enforced by the downstream renderer, which has the context to apply it cleanly.
- **Why no CUE templating in `#config`.** The config schema is the module's *public contract*. It travels with the published module via the OCI registry and is read by non-CUE consumers — web UIs rendering forms, kubectl plugins generating prompts, generated bindings in other languages. CUE templating would tie the schema to a CUE evaluator and exclude every one of those consumers. Per Principle I (Contract Stability), the schema must not assume a particular consumer.
- **Why `#components` and `#defines` are separated.** A Module has two surfaces: a *deployment* surface (its `#components` — what gets rendered when this module is released) and a *publication* surface (its `#defines` — primitives this module contributes to the platform's vocabulary). A module may have one without the other: a primitive library is `#defines`-only; a leaf application is `#components`-only. Conflating them would force every Module to commit to both roles and lose the distinction between consuming and publishing.

#### See also

- Tutorial: [`docs/constructs.md`](docs/constructs.md) (Module section)
- Composes: [`#Component`](#31-component), `#Resource` (§2.1), `#Trait` and `#ComponentTransformer` (forthcoming)
- Instantiated by: `#ModuleRelease` (forthcoming)
