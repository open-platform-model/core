# OPM Core Schema Specification

**Status**: Living document. Authored alongside the schema and gated by `task spec:check`.
**Source of truth**: When this document and the `.cue` files disagree, **the schema wins**. File an issue.
**Module**: `opmodel.dev/core@v2`

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

- **Primitives** (§2) — independently authored, independently versioned schema contracts: `#Resource`, `#Trait`, `#Blueprint` (specified at §3.3, whose section number is retained so existing cross-references keep resolving), `#Secret`. Each carries its own `metadata`, its own contract-keyed identity, and a `spec` schema namespaced under a camelCase form of its name. A primitive is a building block a `#Module` attaches and writes values against, so each carries an `apiVersion` and the additive-only promise that level gates.
- **Constructs** (§3) — framework types that compose, organize, carry, or publish primitives: `#Component`, `#Module`, `#Platform`, `#ModuleInstance`, `#Catalog`. Constructs do not introduce new schema; they unify primitives into structured wholes (`#Component`, `#Module`, `#ModuleInstance`), organize them into platform-resolvable subscriptions (`#Platform`), or package them as a versioned publication artifact (`#Catalog`).
- **Adapters** (§4) — types that translate the model into target runtime form without participating in composition: `#ComponentTransformer`.

The Primitive/Construct split exists because primitives are what a module *attaches and writes against*, and constructs are what *carries* them. A platform team publishes primitives from a catalog on its own release cadence; an application team uses constructs to assemble what a catalog published. The dividing question is not "does this introduce vocabulary?" — under that reading `#Blueprint` sat with the constructs, even though a module names a blueprint and writes values under its `spec` exactly as it does for a resource, and is broken by a change to it exactly as it is. What the split has to track is which definitions carry a **contract key** and the additive-only promise it gates (enhancement 0010 D44), and that is decided by whether a module writes against the thing.

The Adapter category exists because rendering is a *target-specific* concern. Forcing transformers into the composition graph would mean every primitive needs a target-specific arm — an explosion that doesn't compose. Adapters sit beside the model, not inside it. The category is load-bearing in the identity model too: an adapter's inputs are other people's contracts and its output is platform objects, so it carries no `apiVersion` and keys on the build it shipped in rather than on a contract level (§4.1).

`#Catalog` sits under Constructs (rather than as its own category) because it follows the same rule as every other construct: it introduces no new schema vocabulary, it organizes primitives. A `#Catalog` packages a versioned set of `#ComponentTransformer` values under one CUE module path so platforms can subscribe to it. Splitting consumption (`#Module`) from publication (`#Catalog`) gives each artifact one job — but both are constructs, not separate categories.

This v0 of the specification covers the primitives `#Resource`, `#Trait` and `#Blueprint`, the constructs `#Component`, `#Module`, `#Platform`, `#ModuleInstance`, and `#Catalog`, and the adapter `#ComponentTransformer`. Remaining constructs are documented in `docs/` and will land in this spec as the schema stabilises.

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
        name!:           #NameType         // kebab-case
        modulePath!:     #PackagePathType  // e.g. "opmodel.dev/catalogs/opm/resources"
        apiVersion!:     #APIVersionType   // contract level, e.g. "v1beta1"
        catalogVersion!: #VersionType      // SemVer 2.0 of the build it shipped in, e.g. "1.4.0"

        // Authored by the declaring catalog, not derived here.
        // e.g. "opmodel.dev/catalogs/opm/resources/container@v1beta1"
        fqn!: #ContractFQNType

        description?: string
        labels?:      #LabelsAnnotationsType   // categorisation only; never unified upward
        annotations?: #LabelsAnnotationsType
    }

    // The matching identity a transformer selects on. Unified WHOLESALE into
    // every #Component that attaches this Resource.
    // e.g. {"opm.opmodel.dev/workload-type": "stateless"}
    matchLabels?: #LabelsAnnotationsType

    // Where this contract's implementation is expected to come from.
    // "catalog" = the declaring catalog implements it (today's behaviour).
    // "provider" = it deliberately ships none; exactly one transformer in
    // the platform must require this contract.
    fulfilment: *"catalog" | "provider"

    // MUST be OpenAPIv3-compatible, namespaced under camelCase(name).
    spec!: (strings.ToCamel(metadata.#definitionName)): _
}
```

Implementation: [`resource.cue`](src/resource.cue).

#### Constraints

- `kind` MUST be the literal string `"Resource"`. Downstream tools dispatch on this field.
- `metadata.name` MUST be kebab-case (`#NameType` regex, max 63 runes) and MUST be unique within its `modulePath`.
- `metadata.modulePath` MUST be a `#PackagePathType` — a package path inside a module, carrying no `@vN` major suffix. A value carrying one MUST be rejected. This is the type `#ModulePathType` carried before enhancement 0010 D1, so no primitive value shipped by any catalog changes.
- `metadata.apiVersion` MUST be an `#APIVersionType` — `vN`, `vNalphaM` or `vNbetaM`. It is this Resource's own **contract level** and the only version component of its key. A catalog release MUST NOT move it; a breaking change to this Resource's `spec` MUST.
- `metadata.catalogVersion` MUST be a SemVer 2.0 string (`#VersionType`) naming the catalog build the definition shipped in. It is **provenance**: it MUST NOT appear in `metadata.fqn`, and no match compares it.
- `metadata.fqn` MUST be authored by the declaring catalog and MUST match `#ContractFQNType` — the `path/name@vN` form, where `vN` is an `#APIVersionType`. `core` MUST NOT derive it, and MUST NOT refuse a value that disagrees with this Resource's own `modulePath`, `name` or `apiVersion`; that agreement is asserted at publish by `CatalogMemberFQNGate`, not here. (That gate is authored alongside this change and is not yet a definition in `src/`; both land in the same alpha.)
- The authored `fqn` MUST retain its kind segment (`/resources`), so that a Resource and a Trait sharing a name at one `apiVersion` occupy distinct keys.
- `metadata.labels` carries **categorisation** and MUST NOT participate in matching. It MUST NOT be unified upward into a `#Component`.
- `matchLabels` carries this Resource's **matching identity** — the keys a `#ComponentTransformer.requiredLabels` predicate selects on (§4.1). Every key declared here participates in matching; no filter, prefix rule or key list applies.
- A Resource MAY declare a `matchLabels` key as **required** (`"key"!: …`). The requirement MUST survive into every `#Component` that attaches the Resource, and an unanswered key MUST be reported as a missing required field rather than yielding an incomplete value (§3.1).
- `core` MUST NOT name a matching label key. The vocabulary belongs to the catalog that declares it; a catalog MUST be able to introduce a matching key with no change to `core`.
- `matchLabels` MUST NOT be rendered. It MUST NOT reach `#TransformerContext.componentLabels` and MUST NOT appear on any rendered object.
- `fulfilment` MUST be one of `"catalog"` or `"provider"` and MUST default to `"catalog"`. The enum is closed: a third value MUST be rejected. A Resource that does not mention the field is `"catalog"`, and nothing about its behaviour changes.
- `fulfilment: "provider"` means the declaring catalog ships no transformer for this contract, deliberately. A platform MUST carry **exactly one** transformer *requiring* that contract: two MUST be refused, naming both catalog paths and the contract key, with no arbitration between them; zero is an unresolved demand and MUST fail the render (§3.1 of the `contract-fulfilment` capability). A transformer naming the contract among its *optional* demands MUST NOT count as a provider of it.
- That count is enforced at **materialize**, not by this schema. `core` declares the intent; it cannot count transformers across a platform's materialized set. Until the kernel enforces it, `"provider"` is a declaration with no guard — which is strictly better than today, where the concept cannot be declared at all, but it is not the finished state.
- `spec` MUST be present, MUST have exactly one top-level field, and that field's name MUST equal `camelCase(metadata.name)`. The schema under that field MUST be expressible in OpenAPI v3.

#### Rationale

- **Why `kind` is a fixed string and not implicit from the type.** CUE definitions do not carry type information at runtime. Downstream tools walking a rendered tree need a discriminator to route handlers; `kind` is that discriminator. Removing it would force every consumer to do structural detection, which is brittle.
- **Why `fqn` is authored rather than computed, and what replaces the check that lost.** It was computed as `"\(modulePath)/\(name)@\(version)"`, which made a wrong value inexpressible. Enhancement 0010 D21 removes the derivation because the three parts no longer have one source: `fqn`, `modulePath` and `catalogVersion` are all supplied by the catalog's `identity/` package, and deriving one of them here means a release moves them by two edits in two places instead of one. Two alternatives were measured and rejected — dropping `catalogVersion` and authoring only `fqn` lets a catalog on `1.2.0` ship a key naming `1.1.0` at `cue vet -c` exit 0, and deriving `catalogVersion` back out of `fqn` is a CUE cycle. Enforcement therefore **moves** rather than disappearing: `CatalogMemberFQNGate` asserts the agreement at publish. The window in which nothing checks it is real inside this repo and closes in the same alpha; the cost of the trade — a visible, overridable value at the definition site — is the author's, and is accepted for one identity source.
- **Why the key carries `apiVersion` and not `catalogVersion`.** A module's demand and a platform's supply must match on an *equal* key, and under the previous scheme both keys interpolated the catalog build they compiled against. `catalog_opm` declares contracts it ships no transformer for — `backup` is one — so the fulfilling transformer comes from a provider catalog pinned to whichever `catalog_opm` build *it* compiled against. Equal keys were then reachable only by rebuilding both sides in lockstep, and every `catalog_opm` release broke `backup` until that happened. Keying the demand on the contract's own level (enhancement 0010 D4) makes the key survive a release of the catalog that declares it, which is the only thing that decouples the two release cadences. Subscription breadth cannot substitute: subscribing to every `catalogs/opm` build supplies every build's own transformers, and `backup` has none in any of them.
- **Why the level follows the Kubernetes ladder rather than a bare major.** `vNalphaM | vNbetaM | vN` lets the additive-only promise bind at beta and GA and stay off at alpha (enhancement 0010 D34), so a contract can state that it promises nothing yet without leaving the versioning scheme. A bare `vN` would force either a promise on every contract from its first day or no promise anywhere. `#APIVersionGated` reads that off the string; nothing compares two levels, so no ordering enters the schema.
- **Why a primitive's path is `#PackagePathType` and not the `#ModulePathType` an artifact declares.** Enhancement 0010 D1 makes `#ModulePathType` an artifact's *complete* CUE module path, `@vN` included, so that `#Module` and `#Catalog` can be addressed by reading one field. A primitive inherits nothing useful from that suffix: it is a package *inside* a module, and its major is structurally redundant — a `@vN` module publishes only `vN.*` tags, so a primitive already stating its catalog's build version has already stated its catalog's major. It is also not a path anyone writes, since a consumer imports `opmodel.dev/catalogs/opm/resources` with no suffix and CUE resolves the major from `cue.mod`'s `deps`. An earlier revision of D1 widened one shared type for both; every field typed with it then inherited a major with no referent, and D20 (merged into D1) split it in two instead.
- **Why `catalogVersion` is kept at all, once it is out of the key.** It is the provenance both ends of a match read, and it is what lets a diagnostic say "this platform's provider was built against `1.0.0`; this module needs `1.3.0`" when two shapes are compatible but the provider lags. Dropping it would leave a contract stating what it promises and nothing about where it came from. It stays exact SemVer rather than a major prefix for the reason enhancement 0001 D5 first lifted it there — a major-only build stamp lets two divergent definitions coexist under one bucket — and that concern now lands on `#ComponentTransformer` (§4.1), which still keys on it.
- **Why the field was renamed from `version`.** Once a primitive carries two versions, an unqualified `version` names neither: a reader has to know which of the contract level and the build it means, at every site that reads it. `catalogVersion` says which. `moduleVersion` was rejected on collision — "module" already denotes three things in OPM (`#Module`, the CUE module, the module path), so on a primitive it reads as the version of the `#Module`, which is a different field on a different construct.
- **Why matching has its own field instead of riding on `metadata.labels`.** The two were one field, and the upward union that implied *cannot be built*. Measured against the real catalog (enhancement 0010, experiment 04): a full union fails on `resource.opmodel.dev/category`, which takes `workload` on Container, `storage` on Volumes and `config` on ConfigMaps — the spec's own sentence ("conflicts MUST fail at unification") guarantees it on the first real component, and `catalog_opm` fails at its `StatefulWorkload` blueprint fragment before reaching a module at all. So a filter is a precondition rather than a refinement, and every filtered union must **iterate**; CUE refuses to iterate a struct holding an unset required field (`missing required field in for comprehension`), so each filter forced dropping `!` from the container's workload type — degrading "the author must pick" from a required field into an incomplete value. Separating the fields removes the filter and all three of its costs at once: the structs unify wholesale so the `!` survives, categorisation labels never meet structurally rather than meeting behind a filter that agrees not to look, and a genuine disagreement becomes a meaningful conflict (`conflicting values "daemon" and "stateful"`) instead of an artifact of unrelated labels sharing a namespace. It also removes an asymmetry that already existed: `#ComponentTransformer` declared its matching *demand* in a dedicated field (§4.1) while only the component side declared matching *supply* inside `metadata.labels`. See enhancement 0010 D36.
- **Why `core` names no matching key.** The constant `core` used to export for it — `LabelWorkloadType`, holding `"core.opmodel.dev/workload-type"` — is **deleted**; the vocabulary is owned by the catalog that declares it, under the name `opm.opmodel.dev/workload-type` for `catalog_opm`. Measured 2026-08-01, the constant had **zero readers** across `catalog_opm`, `catalog_kubernetes`, `library`, `cli`, `opm-operator` and `modules` — every one of them wrote the literal string — so naming it here bought nothing and cost a `core` release for any catalog wanting a new matching key. A prefix filter over `metadata.labels` was the alternative that keeps working, and it keeps ownership in `core` by construction: it silently drops any key outside the namespace `core` blesses. With a dedicated field there is no namespace to bless.
- **Why a contract declares where its fulfilment comes from, rather than the platform inferring it.** `catalog_opm` declares contracts it ships no transformer for — `backup` is one — and today that is indistinguishable from having forgotten to write the transformer. Both cases render successfully and produce nothing, because a bucket that exists but disqualifies every candidate records nothing at all. Naming the intent is what lets the kernel tell the two apart, and it is the smaller half of the fix: the other half is that an unmet demand must fail (§3.1). **Deriving it was the obvious alternative and is not computable** — the owning catalog cannot be read off an FQN, since the kind-segment count is not fixed (`…/opm/resources` against `…/opm/blueprints/workload`), and it is fragile in principle: a catalog later adding a transformer would silently change the contract's character. **Detecting competing providers by predicate equality** was measured to have no false positives today (21 transformers in `catalog_opm`, 21 distinct predicates) and rejected for false-*negatives* on the real case — a k8up transformer requiring `backup` + `schedule` and a Velero transformer requiring `backup` alone are two providers of one contract, and their predicates differ. See enhancement 0010 D32.
- **Why a closed enum and not a boolean `providedExternally`.** A third fulfilment mode would force a breaking rename of a published field; a closed enum takes a third arm additively. The closedness is the point of the shape, not incidental to it — `fulfilment: "external"` must be a validation failure rather than a value the kernel ignores.
- **Why exactly one provider, with no arbitration between two.** Re-measured 2026-08-01: cross-catalog fulfilment does not exist anywhere in the workspace — 141 self-imports, **zero** foreign, across all three catalogs — so there is nothing to design arbitration against, and "exactly one" costs nothing today. Every candidate mechanism (`prefer` lists, per-contract binding) is purely additive to this decision. Refusing two is what keeps the choice explicit when the first real provider ecosystem appears; silently picking one would make the platform's behaviour depend on catalog load order.
- **Why `matchLabels` is not rendered.** A component's matching identity selects a transformer; it does not describe the objects that transformer emits. Folding it into `#TransformerContext.componentLabels` would publish a catalog's matching vocabulary onto every live object, and the render fold is the wrong place to decide that. The consequence is stated rather than hidden: rendered objects carry `core.opmodel.dev/workload-type` today via that fold and stop carrying it here. An opt-in flag was demonstrated working (experiment 04, `v_render`) and deliberately not taken — it is a four-line struct-level guard, additive whenever the question of where the flag lives is answered.
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
        name!:           #NameType         // kebab-case
        modulePath!:     #PackagePathType  // e.g. "opmodel.dev/catalogs/opm/traits"
        apiVersion!:     #APIVersionType   // contract level, e.g. "v1beta1"
        catalogVersion!: #VersionType      // SemVer 2.0 of the build it shipped in, e.g. "1.0.0"

        // Authored by the declaring catalog, not derived here.
        // e.g. "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"
        fqn!: #ContractFQNType

        description?: string
        labels?:      #LabelsAnnotationsType   // categorisation only; never unified upward
        annotations?: #LabelsAnnotationsType
    }

    // The matching identity a transformer selects on. Unified WHOLESALE into
    // every #Component that attaches this Trait.
    matchLabels?: #LabelsAnnotationsType

    // As #Resource: "catalog" (default) or "provider".
    fulfilment: *"catalog" | "provider"

    // MUST be OpenAPIv3-compatible, namespaced under camelCase(name).
    spec!: (strings.ToCamel(metadata.#definitionName)): _

    // Resources this Trait may modify.
    appliesTo!: [...#Resource]
}
```

Implementation: [`trait.cue`](src/trait.cue).

#### Constraints

- `kind` MUST be the literal string `"Trait"`.
- `metadata.name`, `metadata.modulePath`, `metadata.apiVersion`, `metadata.catalogVersion` and `metadata.fqn` follow the same rules as `#Resource` (§2.1): the key is `#ContractFQNType`, authored by the catalog and terminated by `apiVersion`; `catalogVersion` is SemVer 2.0 provenance that no key interpolates.
- The authored `fqn` MUST retain its kind segment (`/traits`). A Trait and a Resource sharing a name at one `apiVersion` MUST NOT collide.
- `metadata.labels` and `matchLabels` follow the same rules as `#Resource` (§2.1): categorisation stays in `metadata.labels` and is never unified upward; matching lives in `matchLabels`, is unified wholesale into the attaching `#Component`, MAY carry required keys, and is never rendered.
- `fulfilment` follows the same rules as `#Resource` (§2.1) — a closed `*"catalog" | "provider"` enum, enforced at materialize rather than by this schema. `backup` is the contract the field exists for: `catalog_opm` declares the Trait and ships nothing that renders it.
- `spec` MUST be present, MUST have exactly one top-level field, and that field's name MUST equal `camelCase(metadata.name)`. The schema under that field MUST be expressible in OpenAPI v3.
- `appliesTo` MUST list at least one `#Resource`. A Trait that applies to nothing is a category error.
- A Trait attached to a `#Component` whose `#resources` do not include any entry in `appliesTo` MUST fail at CUE unification.

#### Rationale

- **Why `appliesTo` is required and listed.** Traits modify the surface of specific Resources. Without `appliesTo` an author could attach `scaling` to a `Volume` and produce nonsense; with it, the mismatch surfaces at unification time rather than render time. The list shape lets a single Trait apply to a family of related Resources (e.g. `scaling` applies to `Container` and `Job`) without forcing N Trait copies.
- **Why Traits repeat the primitive-metadata shape (`name` + `modulePath` + `apiVersion` + `catalogVersion` + authored `fqn`, plus optional `description` / `labels` / `annotations`) rather than sharing a parent definition with `#Resource` and `#Blueprint`.** Both are vocabulary primitives that catalogs version and publish, and the kernel matcher walks both via the same key-shaped lookup, so the shape must agree — but it is repeated, not inherited. A single parent naming three kinds is what admitted `#ComponentTransformer` as a fourth, and a shape named after three things that admits a fourth hands every future field to that fourth for free: `apiVersion` is the field that actually landed there, and `fulfilment` and `matchLabels` each had to be kept off transformers by hand. Enhancement 0010 D44 buys structural exclusion for the price of repeating four field lines. See §4.1 for the adapter's own shape.
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

        // Descriptive. NOT unified from the attached primitives, and nothing
        // matches on them. These are the labels that reach rendered output.
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    #resources:   #ResourceMap
    #traits?:     #TraitMap
    #blueprints?: #BlueprintMap

    // Trait demands this component can do without: a marker SET keyed by the
    // same contract FQN #traits is keyed by. No `false` — absence is the only
    // spelling of "required". Resources have no counterpart, deliberately.
    #optionalTraits?: [#ContractFQNType]: true

    // This component's matching identity: the wholesale unification of every
    // attached primitive's matchLabels. The comprehension iterates the
    // attachment MAPS and embeds each labels struct whole — it never iterates
    // the labels, which is what lets a required key survive.
    matchLabels: {
        for _, resource in #resources {
            if resource.matchLabels != _|_ { resource.matchLabels }
        }
        if #traits != _|_ {
            for _, trait in #traits {
                if trait.matchLabels != _|_ { trait.matchLabels }
            }
        }
        if #blueprints != _|_ {
            for _, blueprint in #blueprints {
                if blueprint.matchLabels != _|_ { blueprint.matchLabels }
            }
        }
    }

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
- `metadata.labels` and `metadata.annotations` are **descriptive** and MUST NOT be unified from the attached primitives. Nothing selects on them.
- `matchLabels` MUST be the unification of the `matchLabels` of every attached Resource, Trait and Blueprint, with no filter, no key prefix rule and no key list. Two primitives declaring disjoint keys MUST combine; two primitives declaring one key with different values MUST fail with a conflicting-values error naming that key.
- A required `matchLabels` key contributed by a primitive MUST survive into the Component as required. A Component that attaches such a primitive without answering the key MUST report a **missing required field**, not an incomplete value.
- A Component **fragment** — a wrapper a catalog ships that attaches primitives — MUST NOT declare `matchLabels` of its own. A Component's matching identity MUST be exactly the unification of what it attaches.
- `matchLabels` MUST NOT be rendered: it MUST NOT reach `#TransformerContext.componentLabels`, and no rendered object MUST carry its keys.
- Every resource a Component declares is a **required demand**. A demanded resource FQN that no transformer in the platform supplies MUST fail the render, naming the unresolved FQN. A Component whose resource set is only partly satisfied MUST NOT render output for the satisfied part.
- A Component MUST NOT have a demand-side optionality marker for resources. There is no field to declare one.
- A trait demand is **required by default**. A Component MAY mark a trait demand optional by naming its contract FQN in `#optionalTraits`; that key MUST also be a key of `#traits`. An unhandled trait *without* the marker MUST fail the render, naming the trait; only the marked case MUST degrade to a warning that continues.
- `#optionalTraits` values MUST be the literal `true`. There is exactly one spelling of "optional" and no spelling of "required" other than absence.
- Enforcement of the three rules above is the kernel's — a schema cannot see which transformers a platform materialized. `core` states the demand; the render decides whether it was met.

#### Rationale

- **Why `spec` is computed via `_allFields` rather than authored.** Authoring `spec` directly would let a Component contradict the schemas its primitives declare. Computing it from the primitives' specs makes the primitives the single source of schema truth: a Component is exactly the sum of what it composes, nothing more, nothing less.
- **Why the spec is hidden behind `#resources` / `#traits` / `#blueprints` rather than flattened at the Component root.** If the primitives' specs flattened into the Component's root, the parent `#Module` definition would have to be opened (`...`) to accept arbitrary fields, which would defeat schema validation at the Module boundary. The hashed-field indirection (`#resources`, etc.) preserves Module-level closedness. This is recorded directly as a comment in [`component.cue:49-50`](src/component.cue) because future contributors hit it the moment they try to simplify the layout.
- **Why matching identity unifies upward but `metadata.labels` does not.** The principle behind the old rule was right — the primitives are the source of truth about what a Component *is*, and a Component contradicting them would be a lie about what is deployed — but it was applied to a field that also carries categorisation, and those two jobs pull in opposite directions: `resource.opmodel.dev/category` is `workload` on Container, `storage` on Volumes and `config` on ConfigMaps, so the union the rule demanded fails on the first real component (§2.1 Rationale). Splitting the jobs lets each take the rule it needs. `matchLabels` unifies wholesale, and a conflict there is a real modelling error worth failing on. `metadata.labels` stops unifying, because two primitives categorised differently is not a disagreement about anything.
- **Why the union is a comprehension over the attachment maps and never over the labels.** Embedding each primitive's `matchLabels` struct whole is what preserves a required key: CUE will not iterate a struct holding an unset required field, so any `for k, v` over the labels — which every *filtered* union needs — forces primitives to drop `!` and degrades "the author must pick a workload type" into an incomplete value that renders. Iterating the maps is safe because the required field sits inside a value, not at the level being iterated. This is the mechanical fact the whole design turns on, and it is why no key list or prefix rule may be reintroduced here as a "small" refinement.
- **Why an unmet demand is an error at all.** It was not. A demanded FQN with no bucket recorded a `MissingFQN` that no production code read, and a bucket that existed but disqualified every candidate recorded *nothing*. So a Component carrying a container and a backup trait, on a platform with no backup provider, matched the deployment transformer, was not `Unmatched`, rendered successfully, and had no backup. Under the contract model that is not an edge case but the routine failure, because a contract's provider is now expected to come from a different catalog on a different release cadence (§2.1). Making the demand required by default is what turns "your backup silently did not exist" into a render that names the trait.
- **Why the trait opt-out is a marker set beside `#traits`, and not any of the three alternatives.** Enhancement 0010 D28 fixes that there is exactly one opt-out, that it lives on the demand side, and that its absence means required; the spelling is this change's, and it is recorded here rather than only in the schema. **Not a field on `#Trait`:** a trait definition is shipped by a catalog and shared by every component that attaches it, so optionality declared there is a supply-side statement about somebody else's component — `optionalTraits` on `#ComponentTransformer` is the supply side, already exists, and this is its demand-side counterpart. **Not a second attachment map** (`#optionalTraits: #TraitMap`, attach-and-mark in one statement, no FQN repeated): catalogs ship component *fragments* that attach traits into `#traits`, and a module author who wants one of those optional cannot move where the fragment put it — a marker is writable beside a fragment, a rival map is not. **Not a list of FQNs:** two fragments unifying into one Component fail on list unification while map keys merge, and a set makes a duplicate marker a no-op rather than an error. The accepted cost is that the FQN is written twice, once to attach and once to mark; a mistyped key marks nothing and leaves the trait required, so the mistake surfaces as the render failure it was trying to avoid rather than as a silent downgrade.
- **Why resources get no optionality marker, and why that asymmetry is real rather than convenient.** A component does not attach a resource it can do without — a resource is a thing that must exist, and a component whose container has no transformer has nothing to deploy. A trait modifies something that renders regardless, so "render it without the advisory behaviour, and say so" is a coherent outcome for a trait and an incoherent one for a resource. Giving resources the marker too was considered and rejected on that ground: it would let a module declare a resource it does not mean, which is the same class of statement as an empty-filter default that resolves to whatever was published last (§3.4).
- **Why the old claim is deleted rather than corrected.** `metadata.labels` was documented as "unified from all attached resources, traits, and blueprints" in both the schema comment and this specification, and **no code anywhere performed that union** — not in this definition, and not in the kernel, which reads `metadata.labels` off the Component value. What made label matching work in practice was catalogs writing the label onto a component *fragment* by hand. That is the thing this change removes: a fragment is a pure wrapper, the label lives on the primitive, and it falls under the primitive's own additive-only promise rather than under a wrapper nobody versions.
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

A Module is the unit of versioning and distribution. A published Module at `example.com/modules/foo@v1`, tagged `1.2.3`, is immutable.

#### Shape

```cue
#Module: {
    kind: "Module"

    metadata: {
        name!:        #SnakeNameType   // snake_case; the leaf of modulePath
        modulePath!:  #ModulePathType  // complete CUE module path, @vN included
        version!:     #VersionType     // author-supplied in module.cue

        _ref: #ArtifactRef & {"modulePath": modulePath}   // the one decomposition

        fqn:          #ModulePathType & modulePath   // the module path, verbatim
        registryPath: _ref.registryPath              // major stripped
        uuid:         #UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)

        // The path's leaf is the module's name. Hidden — a check, not a value.
        _leaf: strings.HasSuffix(_ref.registryPath, "/"+name)
        _leaf: true

        // No versionMajor field, and no assertion that version's major equals
        // the path's — deliberately absent (see Constraints).

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
- `metadata.name` MUST be snake_case (`#SnakeNameType`). A kebab-case module name MUST be rejected. `metadata.nameSnakeCase` no longer exists — with `name` already in the constrained form there is no projection left to make.
- `metadata.modulePath` MUST be the Module's **complete** CUE module path, `@vN` suffix included (`#ModulePathType`) — the same string `cue.mod/module.cue`'s `module:` field, the registry coordinate and an `import` statement carry. A path with no major MUST be rejected.
- `metadata.modulePath` and `metadata.version` (`#VersionType`) are author-supplied: a Module MUST declare them in its own `module.cue`, the same way `#Resource`, `#Trait`, `#Blueprint`, and `#Catalog` declare their identity. Both are required (`!`); a `#Module` value missing either is incomplete and cannot compute `fqn`/`uuid`.
- `metadata.registryPath` MUST be `modulePath` with the major stripped, sourced from `#ArtifactRef`. It MUST be typed `#PackagePathType`, so a value still carrying a major is refused. Because it is derived rather than authored, a supplied module path conflicts with the computed value before that type is reached — the type states the intent at the field and is the backstop, not the trigger. It is stable across a major bump.
- `metadata.registryPath` MUST end in `/` followed by `metadata.name`. This is enforced by a hidden constraint on `metadata`; a name disagreeing with the path's leaf MUST fail unification, naming `_leaf`. Only the **leaf** is constrained — hyphens remain legal in every other segment.
- `metadata.fqn` MUST equal `modulePath` and MUST be typed `#ModulePathType`. It MUST NOT interpolate `name` or `version`. Consumers MUST NOT supply `fqn` directly.
- `metadata.uuid` is computed as `SHA1(OPMNamespace, fqn)`. It is deterministic and stable across evaluations. Because `fqn` is the module path, `uuid` MUST be unchanged when only `version` changes and MUST change when the path's major changes: **module artifact identity distinguishes majors and nothing finer.** The complementary half — that instance identity is reached by neither the version nor the major — is stated at [`#ModuleInstance`](#35-moduleinstance).
- `metadata.version` MUST NOT be an input to `fqn` or to `uuid`. It remains the source of the `module.opmodel.dev/version` label and is read by the deploying `#ModuleInstance`.
- `metadata` MUST NOT assert that `version`'s major agrees with `modulePath`'s, and MUST NOT expose a `versionMajor` field. A Module declaring `modulePath: "…/postgres@v2"` with `version: "3.0.0"` MUST validate. This is an **accepting** behaviour specified deliberately, not an omission — see Rationale.
- `#components` is required but MAY be empty for a Module that ships only as a configuration shape. Keys MUST satisfy `#NameType`.
- Every entry in `#components` receives `#instance` from `#ctx.instance` via the pattern constraint. The component's `#names` block computes `resourceName` and DNS variants from this injected instance. Authors MUST NOT set `#instance` on a component directly.
- `#ctx.instance` MUST be set by the consuming `#ModuleInstance` (§…). A `#Module` value with `#ctx.instance` left non-concrete is a spec — usable for typing and validation, but not renderable.
- `#ctx.components` is a pure CUE comprehension over `#components`; it cannot be authored independently of the component set. Drift between a component's `#names` and the projection is therefore impossible at the schema layer.
- The top of `#ctx` is open (`...`). Future enhancements MAY add sibling fields (`platform`, `environment`) without invalidating existing module bodies.
- `#config` MUST be expressible in OpenAPI v3. CUE templating constructs (`for`, `if`, comprehensions) MUST NOT appear. This rule is enforced downstream (the library's render pipeline) rather than at the schema layer.
- `debugValues` SHOULD satisfy `#config` and is validated at runtime by the schema fixture harness.

#### Rationale

- **Why `modulePath` / `version` are author-supplied typed-required fields, not self-referential.** Earlier revisions declared them `modulePath: metadata.modulePath` / `version: metadata.version` — a bare-direct self-cycle that resolves to itself, contributing neither a value nor a constraint. CUE never registers a cycle-only field as a permitted member of the *closed* `#Module`, so re-unifying an already-closed published `#Module` into `#ModuleInstance.#module` (the authored-`instance.cue` import path) rejected the concrete `modulePath`/`version` as "field not allowed." The bug was invisible to `cue vet` because a standalone Module is only closed once. Declaring them `!: #ModulePathType` / `!: #VersionType` — the form every sibling identity-bearing construct already uses — makes them genuine permitted fields, fixes the re-unification, and adds real format validation the self-cycle silently skipped.
- **Why `modulePath` is the complete module path and not a bare prefix.** It used to be a prefix that every consumer recombined with `name` to reach a registry address, and that composition was duplicated across `cli` and `library` with no single definition to check any of them against. Making the declared path the address means it is *recoverable by reading one field*: code holding a decoded module can re-import it, and a fetched artifact can be compared against the coordinate it was fetched by. The `@vN` is part of that string rather than a separate field because CUE, the OCI registry and an `import` statement already agree on exactly this spelling — inventing a fourth is what created the drift. See enhancement 0010 D1.
- **Why `name` is snake_case and the path's leaf must equal it.** There used to be three spellings of one name: kebab `name`, a derived `nameSnakeCase`, and the path's leaf — a third, independently authored value that was *supposed* to equal one of the other two with nothing saying which or checking either. A module is a CUE package, a CUE package name is inferred from its path leaf, and package names cannot contain hyphens; so exactly one of those spellings was ever usable, and the schema now names it. Collapsing to one spelling deletes the derived `nameSnakeCase` field and the kebab-to-snake helper behind it, and turns the leaf agreement into a constraint expressible over a single field. Constraining only the leaf, and not the whole path, is what keeps `github.com/open-platform-model/...` expressible. See enhancement 0010 D8.
- **Why `fqn` is a field rather than a recombination, and why the version left it.** The old `fqn` interpolated `version`, so `SHA1(OPMNamespace, fqn)` moved on every release — and `#ModuleInstance.metadata.uuid` derived from it, which put a moving value in the `module-instance.opmodel.dev/uuid` ownership label. The operator skips deleting any live object whose owner label disagrees with the instance UUID it recorded, so every upgrade silently orphaned whatever the new render stopped emitting *and reported success*. Making `fqn` the path fixes the cause rather than the symptom: identity that names the artifact stops tracking the release. The formula over it is untouched, so every module's UUID moves exactly once — which is what makes this a breaking change and why the fleet republishes once.
- **Why `registryPath` is exposed rather than recomputed at each use.** It is the major-free identity of the module *lineage*, and it has two independent callers: `#ModuleInstance` derives its own `fqn` from it (so instance identity survives a major bump), and it is the OCI repository every address-composition site in `cli` and `library` collapses into. Computing it once in `#ArtifactRef` and naming it here is what makes "nothing is recombined" checkable rather than implied. Substituting a full module path fails structurally instead of silently yielding a third identity — as a conflict against the derived value, since `registryPath` is computed rather than authored. The `#PackagePathType` on it declares the intent at the field site; it cannot fire alone, because the split's left half is `@`-free by construction.
- **Why `core` does not assert that `version`'s major matches the path's.** The relation is asserted in the artifact's own `identity/identity.cue`, where both values are written — so a failure names the file the author has open. Re-deriving it here would test the same relation over the same two values one hop downstream, and `core` cannot reach the identity package's own `VersionMajor` to compare against: it cannot import a consumer's package. The exposure this accepts is real and bounded: a module whose identity package is absent or non-conformant carries no consumer-runnable major check, which enhancement 0011's publish gates (D8/D12/D21) close instead. This is written down because the constraint's *absence* is a decision (0010 D45, transposing D43 from `#Catalog`) — restoring it should read as a change, not as a fix.
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
        name!:           #NameType         // kebab-case
        modulePath!:     #PackagePathType  // e.g. "opmodel.dev/catalogs/opm/blueprints/workload"
        apiVersion!:     #APIVersionType   // contract level, e.g. "v1beta1"
        catalogVersion!: #VersionType      // SemVer 2.0 of the build it shipped in, e.g. "1.0.0"

        // Authored by the declaring catalog, not derived here.
        // e.g. ".../blueprints/workload/stateless-workload@v1beta1"
        fqn!: #ContractFQNType

        description?: string
        labels?:      #LabelsAnnotationsType   // categorisation only; never unified upward
        annotations?: #LabelsAnnotationsType
    }

    // The matching identity a transformer selects on. Unified WHOLESALE into
    // every #Component that attaches this Blueprint — typically where the
    // workload-type key its composed Resource declares becomes concrete.
    matchLabels?: #LabelsAnnotationsType

    composedResources!: [...#Resource]
    composedTraits?:    [...#Trait]

    // MUST be OpenAPIv3-compatible, namespaced under camelCase(name).
    spec!: (strings.ToCamel(metadata.#definitionName)): _
}
```

Implementation: [`blueprint.cue`](src/blueprint.cue).

#### Constraints

- `kind` MUST be the literal string `"Blueprint"`.
- `metadata` follows the primitive-metadata shape (`name` + `modulePath` + `apiVersion` + `catalogVersion` + authored `fqn`, plus optional `description` / `labels` / `annotations`), under the same rules as `#Resource` (§2.1) and `#Trait` (§2.2): the key is a `#ContractFQNType` terminated by `apiVersion`, and `catalogVersion` is SemVer 2.0 provenance.
- The authored `fqn` MUST retain its kind segment (`/blueprints`, plus any grouping segments the catalog uses beneath it).
- `metadata.labels` and `matchLabels` follow the same rules as `#Resource` (§2.1). A Blueprint is where a required matching key declared by a composed Resource is typically **answered**: attaching the Blueprint is what completes the component's matching identity.
- `#Blueprint` MUST NOT carry a `fulfilment` field. A `#ComponentTransformer` declares `requiredResources` and `requiredTraits` and has no blueprint equivalent, so nothing can demand a Blueprint and the field would be unreachable. Declaring it MUST fail with a **field-not-allowed** error — the definition is closed, so the exclusion is structural rather than a field nothing reads. A Blueprint's fulfilment is that of the contracts it composes, each of which declares its own.
- `composedResources` MUST list at least one `#Resource`. A Blueprint that composes nothing is a category error.
- `composedTraits` is optional. A Trait listed here MUST have a `#Resource` from `composedResources` in its `appliesTo`, otherwise unification fails.
- `spec` MUST be present, MUST have exactly one top-level field, and that field's name MUST equal `camelCase(metadata.name)`. The schema under that field MUST be expressible in OpenAPI v3.

#### Rationale

- **Why Blueprints repeat the primitive-metadata shape of `#Resource` and `#Trait`.** Blueprints are shipped by catalogs, key-addressed, and version in lockstep with the primitives they compose (enhancement 0001 D21). A divergent metadata shape would force every catalog tool to special-case Blueprints. The shape is repeated rather than inherited from a shared parent, for the reason given at §2.2.
- **Why Blueprints are classified as primitives, having previously sat under Constructs.** The old line was "does this introduce schema vocabulary?", and by it a Blueprint is not a primitive: its `spec` is the composition of fields its Resources and Traits already declare. Enhancement 0010 D44 replaces that line with the one the identity model actually turns on — *is this a building block a module attaches, whose `spec` is a surface modules write against?* A Blueprint is: a module names it, writes values under it, and is broken by a change to it exactly as it is by a change to a Resource. That is what earns the contract key and the additive-only promise the key gates, and neither follows from introducing vocabulary. Nothing else follows from the reclassification — the exclusion of `fulfilment` stands on its own structural ground (no transformer can demand a Blueprint), which makes a Blueprint a primitive that nothing demands rather than a non-primitive.
- **Why `composedResources` is required and listed, while `composedTraits` is optional.** A Blueprint with no Resource composes nothing renderable. Traits modify Resources, so a Resource-only Blueprint (`headless-workload`-style) is meaningful; a Trait-only Blueprint is the same category error as a Trait with empty `appliesTo`.

#### See also

- Tutorial: [`docs/constructs.md`](docs/constructs.md) (Blueprint section)
- Composes: [`#Resource`](#21-resource), [`#Trait`](#22-trait)
- Attached by: [`#Component`](#31-component)

---

### 3.4 `#Platform`

#### Definition

A `#Platform` is a path-keyed registry of *subscriptions* to catalogs plus the kernel-filled materialization slots the matcher uses at compile time. Authors write the subscription map; each subscription names one catalog build, and the kernel's `Materialize` step pulls exactly that build, indexes the transformers it carries into `#composedTransformers`, and computes a `#matchers` reverse index from primitive FQN to candidate transformer.

A `#Platform` value is therefore a *spec* (which catalog builds to pull) plus a place for the kernel to write its materialization output. The match-time evaluation runs against the materialized twin, not the raw spec.

There is no resolution step: the platform file **is** the resolution. Nothing in a subscription requires a query against a registry to determine which build was selected.

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
        resources: [#ContractFQNType]: [...#ComponentTransformer]
        traits:    [#ContractFQNType]: [...#ComponentTransformer]
    }
}

#Subscription: {
    enable:   bool | *true
    version!: #VersionType     // the single build this subscription materializes
}
```

Implementation: [`platform.cue`](src/platform.cue).

#### Constraints

- `kind` MUST be the literal string `"Platform"`.
- `metadata.name` MUST be kebab-case (`#NameType`).
- `type` MUST be present. The value is informational at this stage — the matcher does not consult it.
- `#registry` keys MUST be `#ModulePathType` strings (the catalog package's CUE module path). Since enhancement 0010 D1 that type carries a terminal `@vN`, so a key names one major of one catalog (`"opmodel.dev/catalogs/opm@v1"`) and a platform MAY subscribe to two majors of the same catalog as two distinct entries. One subscription per key is enforced by CUE map semantics; multi-channel-per-key is intentionally not expressible.
- `#Subscription.enable` defaults to `true`. When `false`, the kernel SHOULD skip materialization for that path; primitives owned by the path do not surface on the platform.
- `#Subscription.version` MUST be present and MUST be a SemVer 2.0 string (`#VersionType`). It names the **single** catalog build the subscription materializes. A subscription with no `version` MUST report a missing required field; it MUST NOT fall back to the highest published build.
- A prerelease build MUST be selectable by naming it in `version` (e.g. `"1.0.0-alpha.2"`). There MUST be no opt-in flag for prereleases and no maturity inference from the string.
- Selection MUST NOT require a resolution step against a registry: the declared value is the selected value. Publishing a newer build MUST NOT move an existing platform's selection, and no lockfile is consulted.
- The subscription filter (the definition formerly named `SubscriptionFilter`, reached through `#Subscription.filter`) is **removed** in `v2.0.0-alpha.4`, together with `range`, `allow`, `deny`, the prerelease flag and the highest-published default. A subscription declaring `filter` MUST be rejected as a field not allowed.
- A `#Platform` MUST NOT be able to express two builds of one catalog. CUE map semantics collapse two subscriptions under one path to one key. Two builds of one catalog is two platforms.
- `#composedTransformers` and `#matchers` are kernel-filled output slots. Authors MUST NOT supply them; doing so would let an author override what the registry actually published. Both are optional at the CUE level because the spec value carries them empty.

#### Rationale

- **Why subscriptions instead of inline module registrations.** The pre-0001 design forced a platform to embed concrete `#Module` values keyed by an arbitrary author-chosen `Id`, so the platform spec bundled the entire transitive content of every catalog it consumed rather than the intent to consume it. Subscriptions move pull intent into a small declarative shape (path + build) and let the kernel materialize against the registry. See enhancement 0001 D13.
- **Why the registry map is path-keyed, not Id-keyed.** A catalog has exactly one CUE module path. Keying on path lets CUE's map-uniqueness semantics enforce "one subscription per catalog" structurally — two declarations at the same key unify, divergent declarations fail. Id-keying admitted "two subscriptions for the same catalog under different names" silently, which is meaningless and a common author error.
- **Why `#composedTransformers` and `#matchers` are optional kernel-filled slots, not CUE comprehensions.** Materialize pulls remote artifacts from OCI — it cannot be a pure CUE comprehension over an in-memory `#registry`. Modeling these as optional fields lets the CUE-level spec remain valid without materialization, while the materialized twin (built by the kernel after fetching) carries the populated values. The alternative — making them required — would force every author to construct a "materialized" view in CUE by hand, defeating the purpose. See enhancement 0001 D14.
- **Why `#knownResources` and `#knownTraits` are removed.** Both were eager projections that flattened every catalog's primitives into a flat map on the platform. They duplicated information the matcher could (and now does) reach transitively via each transformer's required/optional maps. Removing them eliminates a sync point that always lagged the materialized transformer set.
- **Why a subscription names one build, and why the filter that used to select it is gone.** The filter's empty-filter default resolved to the highest SemVer published for the path, and that default *is* a float: it moves on the next catalog release whether or not a constraint was written. Ranges without a lockfile is the one combination that cannot be made reproducible, and every ecosystem shipping ranges ships a lock beside them; OPM shipped ranges and recorded its resolution in an in-memory map whose only non-test consumer was an integration harness and whose own doc comment told callers they MUST NOT branch on it. Collapsing to a scalar makes catalog selection a pure function of committed source: **git-identical inputs materialize identical catalog bytes** on any day, from any machine, with no lockfile, because the platform file is the resolution. The breadth the filter bought was load-bearing only under the *old* build-keyed contracts, where a platform had to cover the authorship history of its installed fleet; enhancement 0010 D4 moved the contract key off the build and took that requirement with it. See enhancement 0010 D37.
- **Why the field is a scalar and not a one-element list.** Widening back to multi-build becomes a breaking rename rather than a list relaxation, and that cost is recorded here rather than discovered later — because every use of breadth collapses on inspection. *Union coverage* (build `1.0.0` ships transformers A and B, build `1.2.0` ships A only, listing both yields `A@1.2.0` + `B@1.0.0`) is the one case breadth uniquely served, and it describes a catalog that made a breaking change without saying so: the dropped transformer must fail the render loudly, and the fix belongs to the catalog author. *Gradual migration* does not structurally exist — under D4 a module demands resources and traits and never a transformer, so no module can stay on the old build. *Two API versions of one contract* ship side by side in a single build; that is what contract keys are for (§2.1). *Testing a new build beside the old* is two platforms, already expressible, naming both behaviours. Newest-wins tie-breaking was defensible and rejected: it makes listing two builds indistinguishable from listing one in every case except the dropped-transformer catalog bug — silent arbitration bought to serve the one scenario that should fail loudly.
- **Why not ranges plus a lockfile, which is strictly more expressive.** It is more machinery for the same guarantee, and the asymmetry decides it: reintroducing `range` alongside a recorded resolution takes nothing away from a platform that already names its build, while an established floating default cannot be withdrawn cheaply once platforms depend on it. The expressive answer stays available; the float does not.
- **Why a catalog upgrade is now a manual edit, and why that is not a regression.** For platforms that live in git and reconcile continuously, an upgrade that appears in a diff and gets reviewed is the correct interaction — the alternative is a version that changes because someone else published. Automating the bump is enhancement 0004's subject, and it is additive to this shape.
- **Why a prerelease needs no flag.** The filter inferred maturity from the version string and gated prereleases behind an opt-in, which made "select `1.0.0-alpha.2`" a two-part statement whose second part was about a *class* of builds rather than the one selected. With a scalar there is one statement: the build is selected by being written down. Both mainline catalogs publish `1.0.0-alpha.*` today, so the gate was load-bearing against the fleet's own normal case.

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

        // The module's MAJOR-FREE registry path, this name, this namespace.
        fqn:           "\(#moduleMetadata.registryPath):\(name):\(namespace)"
        uuid:          #UUIDType & SHA1(OPMNamespace, fqn)

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
- `metadata.fqn` MUST be `"\(#moduleMetadata.registryPath):\(name):\(namespace)"`. It MUST derive from the deployed module's **major-free** `registryPath` and MUST NOT derive from the module's `fqn`, `uuid`, `version`, or major. Supplying a full module path in the registry-path position MUST be refused — as a conflict against the derived `registryPath` — rather than yielding a third identity.
- `metadata.uuid` MUST be `SHA1(OPMNamespace, fqn)` over the instance's own `fqn`. It MUST NOT interpolate the module's `uuid`. Two evaluations with the same module registry path + name + namespace MUST yield the same uuid.
- **Instance identity MUST survive every upgrade of the module it deploys.** For one `{module registry path, name, namespace}` triple, `metadata.uuid` MUST NOT change when the module's `version` changes, and MUST NOT change when the module path's **major** changes — even though `#Module.metadata.uuid` does change across that major bump (§3.2). This is the second half of the invariant whose first half is stated at [`#Module`](#32-module): artifact identity distinguishes majors and nothing finer; instance identity is reached by neither the version nor the major.
- **Instance identity MUST still separate modules and namespaces.** `metadata.uuid` MUST differ for two modules whose registry paths differ, and MUST differ for one module deployed under two instance names or into two namespaces. Without this the survival rule above is satisfiable by an identity that has stopped distinguishing anything.
- `metadata.labels["module-instance.opmodel.dev/uuid"]` MUST carry `metadata.uuid`. This is the **ownership** label: the operator's prune step skips deleting any live object whose owner label disagrees with the instance UUID it recorded, so a UUID that moves on upgrade orphans whatever the new render stopped emitting — without erroring, and while reporting success.
- `#module.#ctx.instance` MUST be set from `metadata.{name, namespace, uuid, clusterDomain}`. The wiring is declared inline in the schema; authors do not call a builder.
- `values` MUST satisfy `#module.#config`. CUE unification enforces this at evaluation time.
- `components` MUST be exactly the module's `#components`. Core MUST NOT synthesise, inject, or reserve any component name; a module whose config carries `#Secret` fields MUST declare its own secrets component against its catalog's secrets resource.

#### Rationale

- **Why `clusterDomain` lives on `#InstanceIdentity` and not buried inside a runtime context type.** A FQDN like `service.namespace.svc.cluster.local` is computed once per instance: every component's `#names.dns.fqdn` consumes it. Putting `clusterDomain` on the instance identity gives one overridable home — an instance on a `cluster.example.com` cluster sets it once, and every component's FQDN follows. Burying it inside a separate runtime-context type would force every consumer to traverse two levels of indirection to read a single string. See enhancement 0001 D4.
- **Why `#ModuleInstance` sets `#ctx.instance` inline and ships no builder.** The pre-0001 sketches considered a separate context-builder type that would take metadata and produce a context value. Two arguments against: (1) the wiring is one struct expression — a builder adds a type and a function call to do what one inline literal does already; (2) builders introduce evaluation order ("call builder before evaluating module") that pure CUE doesn't have. Setting `#ctx.instance` inline keeps the module + instance pair as one CUE value with no procedural dependency. See enhancement 0001 D1.
- **Why `#module.#ctx.instance` is set inside the `#module` unification, not on `#module.#ctx` after the fact.** Unification is associative and commutative — the order in which fields land doesn't matter. Setting it inside the `#module: #Module & {...}` expression makes the wiring textually adjacent to the module reference, so a reader sees both pieces at the same scroll position. The alternative ("set #module first, then patch #module.#ctx.instance") is the same CUE value but harder to read.
- **Why `uuid` is computed deterministically from module + name + namespace.** An instance's identity must be reproducible across evaluations of the same inputs: a controller restarting, a CI pipeline retrying, a kubectl apply re-running. Random or author-supplied uuids drift between runs and force every consumer to track a separate "is this the same instance?" signal. The SHA1-of-FQN form derives the answer from the inputs themselves. Same principle as `#Module.metadata.uuid` (§3.2 rationale).
- **Why instance identity derives from the module's `registryPath` and not from its `fqn` or `uuid`.** The two values answer different questions, and deriving one from the other forced them to agree when they must not. `module.uuid` is *artifact* identity — `@v2` and `@v3` are distinct modules under both CUE and Go semantics, so it has to move across a major. `instance.uuid` is *ownership* identity, the value the prune step compares against a live object's owner label, so it has to survive every upgrade of the same deployment including a major bump. While `instance.uuid` interpolated `module.uuid`, and `module.uuid` hashed an FQN containing the version, ownership identity moved on **every release**: the operator then skipped each delete it should have performed, left the objects running, and reported success. Stripping the major on the way in is what makes the two move independently.
- **Why not derive instance identity from the module's `name`.** It collides. `opmodel.dev/modules/jellyfin` and `example.com/jellyfin` both carry `name: "jellyfin"`, so two unrelated modules deployed under the same instance name into the same namespace would share an ownership identity — and each render would then claim the other's objects. A full registry path is unique by construction, which is the property the label needs.
- **Why `fqn` is a named field rather than an interpolation inlined into `uuid`.** The derivation is the whole contract here: which module fields reach ownership identity, and which deliberately do not. Inlined inside the hash it was a string literal nobody reviewed; as a field it is one line to read, it mirrors `#Module`'s own `fqn → uuid` shape, and a change to what identity depends on shows up as a change to a named value.
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

The catalog's identity is its `metadata.modulePath` — the complete CUE module path, `@vN` included — and its `metadata.fqn` is that path verbatim. The SemVer `metadata.version` is the catalog's *build*: it keys the transformers and stamps every member's provenance, but it is not part of the catalog's identity. The kernel reads only `#Catalog.metadata` and `#Catalog.#transformers` at materialize time — there is no package walk, no auto-discovery.

#### Shape

```cue
#Catalog: {
    kind: "Catalog"

    M=metadata: {
        modulePath!:  #ModulePathType   // complete module path, @vN included
        version!:     #VersionType      // no default — unset is incomplete
        fqn:          #ModulePathType & modulePath   // the module path, verbatim

        _ref: #ArtifactRef & {"modulePath": modulePath}   // the one decomposition

        // No assertion that version's major agrees with the path's — see
        // Constraints; the same deliberate absence #Module carries.

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Every entry's metadata.modulePath is stamped to
    //   "<catalog registryPath>/transformers"     // major split out, NOT re-appended
    // and metadata.catalogVersion is stamped to the catalog's version.
    // Pattern enforced by the schema, not by author discipline.
    #transformers: [#ImplFQNType]: #ComponentTransformer & {
        metadata: {
            modulePath:     "\(M._ref.registryPath)/transformers"
            catalogVersion: M.version
        }
    }
}
```

Implementation: [`catalog.cue`](src/catalog.cue).

#### Constraints

- `kind` MUST be the literal string `"Catalog"`.
- `metadata.modulePath` MUST be the catalog package's **complete** CUE module path, `@vN` suffix included (e.g. `opmodel.dev/catalogs/opm@v1`). It MUST be the same string `cue.mod/module.cue`'s `module:` field and the registry coordinate carry. A path with no major MUST be rejected. It is sourced from the sibling `identity/` subpackage.
- `metadata.version` MUST be a concrete `#VersionType` and MUST have **no default**. A `#Catalog` evaluated with `version` unset MUST report an incomplete value naming the field. The former `*"0.0.0-dev"` default is removed.
- `metadata.fqn` MUST equal `modulePath` and MUST be typed `#ModulePathType`. It MUST NOT interpolate `version`. Consumers MUST NOT supply it.
- `metadata` MUST NOT assert that `version`'s major agrees with `modulePath`'s. A `#Catalog` declaring `modulePath: "…/opm@v1"` with `version: "2.0.0"` MUST validate. As with [`#Module`](#32-module), this is an **accepting** behaviour specified deliberately — see Rationale.
- Every entry in `#transformers` MUST be keyed by the transformer's own `metadata.fqn`, and the key is typed `#ImplFQNType`, so a contract-shaped key MUST be rejected. The pattern constraint on `#transformers` stamps every entry's `metadata.modulePath` to `"<catalog registryPath>/transformers"` — the **major-free** path — and every entry's `metadata.catalogVersion` to the catalog's version. The major MUST NOT be re-appended: a transformer declares a `#PackagePathType`, which admits no `@vN`. An author who writes a divergent value for either field MUST get a `cue vet` failure with "conflicting values" — not a silent override.
- The pattern does NOT stamp `metadata.fqn`. Under enhancement 0010 D21 an `fqn` is authored at the definition site rather than derived, so there is no value for `#Catalog` to compute; the map key already carries the transformer's own `fqn`, and the agreement between the two is asserted at publish by `CatalogMemberFQNGate` rather than here.
- Resources, Traits, and Blueprints are NOT enumerated in `#Catalog`. They surface transitively via each transformer's `requiredResources` / `requiredTraits` maps and via standard CUE imports for direct references.

#### Rationale

- **Why a single `#Catalog` construct instead of a `#Module.#defines` block.** The pre-0001 design overloaded `#Module` to act as both a consumer artifact (declares components) and a publisher artifact (defines primitives). A catalog has no `#components` to render — it only publishes vocabulary. Collapsing both responsibilities into one type forced every catalog to ship the consumer surface (and vice versa). Splitting them gives `#Module` one role (consume) and `#Catalog` one role (publish). Both remain constructs — they organize primitives, they don't introduce schema vocabulary. See enhancement 0001 D19.
- **Why the `M=metadata` field-label alias.** The pattern constraint on `#transformers` needs to reach the outer catalog's `modulePath` and `version` from inside the nested `metadata: { ... }` block of every entry. A bare `metadata.modulePath` reference inside the entry's own metadata walks to the closest parent field named `metadata` — the inner field itself — and self-embeds into a non-concrete interpolation. CUE's value-alias form (`metadata: M={...}`) does not carry across the nested constraint boundary; only the field-label alias form does. Experiment 09 in the enhancement validated both sound forms (hidden-mirror + label-alias); the label-alias is chosen here for inline locality. See enhancement 0001 D25.
- **Why the pattern stamps `modulePath` + `catalogVersion` but not `fqn`.** Stamping the two replaces the prior author-discipline rule ("every transformer's metadata must match the catalog's version") with a structural guarantee that `cue vet` enforces. Experiment 10 confirmed the asymmetry: a wrong `modulePath` or build version fails vet loudly; stamping `fqn` introduces conflicts on round-tripped FQNs. Enhancement 0010 D21 then removed the derivation the stamp would have collided with — an `fqn` is now authored, so `#Catalog` has nothing to compute and the stamped `catalogVersion` is what keeps a transformer's authored key honest about the build it shipped in.
- **Why catalogs don't enumerate Resources / Traits / Blueprints.** A transformer's `requiredResources` / `requiredTraits` already names every primitive the matcher needs to reach. Adding sibling `#resources` / `#traits` / `#blueprints` maps on `#Catalog` would duplicate that information and invite drift between the enumeration and the transitive set. If introspection demand surfaces later, the sibling maps are an additive extension — not a precondition.
- **Why a catalog's `fqn` is its module path, and why the dedicated catalog-FQN type retired with it.** The old `fqn` was `modulePath@version`, which meant a catalog's identity moved on every release and its regex was not structurally disjoint from a primitive's `modulePath/name@version` — the two were distinguished by which field they appeared in, not by anything checkable. Making `fqn` the module path removes both problems at once: identity names the artifact rather than the release, and the type is the same `#ModulePathType` a `#Module` carries, so there is one path type per artifact kind instead of one per derivation. The catalog's *build* still has a home — `version` — and it is what keys the transformers.
- **Why the `"0.0.0-dev"` default is gone.** It existed so `cue vet` was cheap in a source tree, and it made a checkout and a published artifact compute different values: the committed tree resolved `Version` to `0.0.0-dev`, so a local render demanded `…/transformers/deployment@0.0.0-dev` while the registry supplied `…/transformers/deployment@1.0.0`. A default that renders successfully while being wrong is worse than no value at all — an unset `version` is now an incomplete value that names the field, and the committed `identity/identity.cue` supplies the real one to checkout and artifact alike. See enhancement 0010 D5/D6.
- **Why the transformer stamp drops the major instead of re-appending it.** The stamp builds a *package* path — `metadata.modulePath` on a `#ComponentTransformer` is a `#PackagePathType`, which admits no `@vN` (§2.1 Rationale). Re-appending the catalog's major would produce a value the transformer's own type rejects, and would key every published member under a suffix no import statement writes.
- **Why `core` does not assert that a catalog's `version` major matches its path's.** Same holding as `#Module` (§3.2), taken first here: the relation is asserted in `identity/identity.cue` where both values are written, and re-deriving it in `core` tests the same relation one hop downstream. The asymmetry that this shape *is* what a consumer evaluates — `materialize` builds the catalog against `#Catalog`, while the identity package is never evaluated as a package by a consumer — is why the exposure is stated rather than assumed: a catalog with a non-conformant identity package carries no consumer-runnable check, and the skew surfaces at platform-subscription selection instead, in a platform author's file about a publisher's mistake. Accepted by enhancement 0010 D43, and closed by 0011's publish gates rather than here.

#### See also

- Tutorial: forthcoming
- Publishes: [`#ComponentTransformer`](#41-componenttransformer)
- Consumed by: [`#Platform`](#34-platform) via `#registry` subscriptions

---

## 4. Adapters

### 4.1 `#ComponentTransformer`

#### Definition

A `#ComponentTransformer` translates a matched `#Component` into platform-specific output (e.g. Kubernetes manifests). It declares which primitives a Component must (or may) carry to be a candidate match, plus a `#transform` function that the runtime evaluates with concrete inputs.

Transformers are catalog-versioned, and a transformer is an **adapter rather than a primitive** (§1): it carries no `apiVersion`, and its own key names the build it shipped in. The match algorithm is key-driven: each entry in `requiredResources` / `requiredTraits` names the exact contract key the Component must surface for the transformer to consider it.

#### Shape

```cue
#ComponentTransformer: {
    kind: "ComponentTransformer"

    metadata: {
        name!:           #NameType
        modulePath!:     #PackagePathType
        catalogVersion!: #VersionType     // SemVer 2.0 of the build it shipped in

        // Authored by the declaring catalog, not derived here. Note the type:
        // an IMPLEMENTATION key, not a contract key.
        // e.g. ".../transformers/deployment-transformer@1.0.0"
        fqn!: #ImplFQNType

        // NO apiVersion. metadata is closed, so declaring one is
        // `field not allowed` rather than a field nothing reads.

        description!: string              // required for catalog listings
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Selected against #Component.matchLabels — never against metadata.labels.
    requiredLabels?:    #LabelsAnnotationsType
    optionalLabels?:    #LabelsAnnotationsType
    requiredResources?: [#ContractFQNType]: #Resource
    optionalResources?: [#ContractFQNType]: #Resource
    requiredTraits?:    [#ContractFQNType]: #Trait
    optionalTraits?:    [#ContractFQNType]: #Trait

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
- `metadata` carries `name` + `modulePath` + `catalogVersion` + an authored `fqn`, plus optional `labels` / `annotations` and a required `description`. It is a shape of its own: no shared parent definition spans it and the primitive-metadata shape of §2.1, §2.2 and §3.3.
- `metadata.fqn` MUST be authored by the declaring catalog and MUST match `#ImplFQNType` — the `path/name@<semver>` form. A contract-shaped key (`…@v1`) MUST be rejected here. As for the primitives, `core` MUST NOT derive the value and MUST NOT check it against `modulePath`, `name` and `catalogVersion`; `CatalogMemberFQNGate` asserts that at publish.
- `metadata.catalogVersion` MUST be a SemVer 2.0 string. Unlike a primitive's, it IS this kind's key component.
- `#ComponentTransformer` MUST NOT carry `metadata.apiVersion`. Declaring one MUST fail with a field-not-allowed error rather than being accepted and ignored.
- `#ComponentTransformer` MUST NOT carry `metadata.#definitionName`. The three primitives retain it because each derives its `spec!` field key from it; a transformer has no `spec`, so nothing read it.
- Every map key under `requiredResources` / `optionalResources` / `requiredTraits` / `optionalTraits` MUST be a `#ContractFQNType` and MUST equal the map value's `metadata.fqn`. A build-shaped key MUST be rejected: a transformer demands contracts, and no `#Resource` or `#Trait` can carry a key in that form.
- A Transformer matches a Component when: all `requiredLabels` are present in the Component's **`matchLabels`** with matching values, every `requiredResources` FQN appears in the Component's `#resources`, and every `requiredTraits` FQN appears in the Component's `#traits`. `requiredLabels` MUST be evaluated against `#Component.matchLabels` (§3.1) and MUST NOT be evaluated against `metadata.labels` on either side. The kernel matcher additionally unifies the consumer's primitive against the transformer's required slot at the same FQN; divergent definitions surface as a structured error per (component, FQN).
- `#transform.output` MUST be either a single struct (one rendered resource per match) or a list of structs (N rendered resources per match). Other CUE kinds are rejected by the renderer.

#### Rationale

- **Why match is key-driven and always unifies.** A transformer names the contracts it demands by key, and two contract levels of one primitive (`…@v1beta1`, `…@v1`) are distinct keys, so a transformer demanding one is structurally distinct from one demanding the other. But within a single key, the consumer Component may carry a slightly different definition body (drift, partial override) — the two sides may even come from different catalog builds, which under enhancement 0010 D4 is now the normal case rather than an error. Always unifying the consumer's primitive against the transformer's required slot ensures that drift surfaces as a structured `UnifyError` per (component, key) pair rather than as a render-time mystery. See enhancement 0001 D6.
- **Why a transformer carries no `apiVersion`, and why that is enforced by closedness rather than by omission.** There is nothing for the field to name: a transformer's inputs are other people's contracts and its output is platform objects, so "this transformer's contract major" has no referent, and no reader would consult it — its own key interpolates `catalogVersion`, and the matcher keys on the contracts it demands. The absence is also load-bearing rather than tidy. A publish gate phrased as "for every member, compare against the last published build shipping this name at this apiVersion" resolves for a transformer the moment it has one, and the additive-only rule then refuses *ordinary* catalog releases — changing rendering logic, dropping an emitted field and narrowing an output type are all routine transformer edits and all violations. That would invert the whole point of keying transformers on the build, which is that a transformer is free to change. Closing the shape makes the field inexpressible, so the exclusion survives the next person adding a field to "the identity shape" without remembering which kinds are primitives.
- **Why the identity shape is repeated rather than inherited from one shared with the primitives.** A parent named after the primitives that also admits transformers hands every future field to transformers for free. That is the actual history of `apiVersion`, and `fulfilment` and `matchLabels` each had to be excluded by hand afterwards. Enhancement 0010 D44 splits the shape instead: the cost is repeating three field lines, and the benefit is that the next field added to primitives cannot reach an adapter by default. A kind-neutral parent naming neither category was available and rejected for reintroducing exactly that straddle under a vaguer name.
- **Why the label predicate reads `matchLabels` and not `metadata.labels`.** A label match must be a stable structural predicate the catalog stamps on a primitive once and relies on — not a free-text field a module author can typo into a silent misroute. `matchLabels` is that field: it unifies upward from every attached primitive (§3.1), it carries nothing but matching keys, and a primitive can declare one of them *required* so the author is forced to answer rather than allowed to omit. `metadata.labels` cannot be it, because it also carries categorisation that legitimately differs between primitives (§2.1 Rationale). The two sides of the match now have the same shape: this transformer declares its demand in a dedicated field, and the component declares its supply in one — an asymmetry that existed from the start, since `requiredLabels` was never `metadata.labels` on the transformer either.
- **Why `#transform.output` may be either a struct or a list.** Most transformers emit one rendered resource per match (`Deployment` per stateless workload, `Service` per network-expose Trait). Some emit a variable number derived from a Component-side map: a `ConfigMapTransformer` emits one `ConfigMap` per entry in a component's `config` map. A single shape would force the variable case into a struct-of-resources contortion; a list-only shape would force the single case into a one-element list. Two shapes is the smallest schema that doesn't lie.
- **Why we don't allow free-form CUE inside the transformer's output.** The renderer dispatches on `cue.Kind` — struct vs list — and never inspects field bodies. This keeps the kernel's render path agnostic to apply-layer conventions: a Kubernetes transformer's output is whatever the apply layer (kubectl, controller, gitops bridge) interprets, not whatever shape the core schema happens to know. Per Principle I (Contract Stability), the core schema must not assume a particular target.

#### See also

- Tutorial: [`docs/adapters.md`](docs/adapters.md) (forthcoming)
- Matches: [`#Component`](#31-component)
- Requires: [`#Resource`](#21-resource), [`#Trait`](#22-trait)
- Discovered via: [`#Catalog`](#36-catalog)

