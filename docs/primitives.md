# OPM Primitives

Primitives are schema contracts — independently authored building blocks that share the same shape: `metadata` (carrying `name`, `modulePath`, `apiVersion`, `catalogVersion` and an authored `fqn`) plus a `spec` (OpenAPIv3-compatible schema, namespaced under the definition's camelCase name). They are composed into [Constructs](constructs.md).

A primitive carries **two** versions, and they answer different questions. `apiVersion` is the contract's own level (`v1`, `v1beta1`, `v1alpha1`) — the only version component of its key, moved when the primitive's `spec` breaks. `catalogVersion` is the SemVer of the catalog build the definition shipped in — provenance, which no key interpolates. `fqn` is **authored** by the declaring catalog rather than computed here, and `#CatalogMemberFQNGate` checks it against the catalog's identity package at publish. See [SPEC.md §2.1](../SPEC.md) for the normative rules.

A Primitive:

- Defines a reusable `spec` schema
- Is independently authored and versioned
- Is composed into Components or other Primitives (Blueprints)
- Can be reused across multiple Modules

See [Definition Types](definition-types.md) for the full taxonomy.

---

## Resource

A **Resource** represents a fundamental, deployable entity that must exist in the runtime environment. Resources are the "nouns" of OPM — they answer the question "what is being deployed?" A Resource is standalone and has its own lifecycle; it can exist independently without requiring other definitions to make sense. Examples include Container (a running process), Volume (persistent storage), ConfigMap (configuration data), and Secret (sensitive configuration).

Resources are separate from Traits because they represent **existence** rather than behavior. A Component must have at least one Resource because without something that exists, there is nothing to modify (Trait) or compose (Blueprint).

### What Resource Infers

- "This thing **must exist** in the environment"
- "This is the **root** of something deployable"
- "Without this, there is nothing to modify or govern"

### When to Create a Resource

Ask yourself:

- Does this thing need to exist in the runtime for the application to function?
- Can it exist on its own, without depending on another primitive?
- Does it have its own lifecycle (create, update, delete)?

**Examples**: Container, Volume, ConfigMap, Secret, Database, Queue

### Resource Structure

```cue
#Resource: {
    kind: "Resource"

    metadata: {
        name!:           #NameType         // e.g., "container"
        modulePath!:     #PackagePathType  // e.g., "opmodel.dev/catalogs/opm/resources"
        apiVersion!:     #APIVersionType   // contract level, e.g., "v1beta1"
        catalogVersion!: #VersionType      // build provenance, e.g., "1.0.0"

        // Authored by the declaring catalog, not derived here.
        fqn!:         #ContractFQNType  // e.g., ".../resources/container@v1beta1"
        description?: string
        labels?:      #LabelsAnnotationsType   // categorisation only
        annotations?: #LabelsAnnotationsType
    }

    // Matching identity — unified wholesale into every Component that
    // attaches this primitive; what a transformer's requiredLabels selects on.
    matchLabels?: #LabelsAnnotationsType

    // Where this contract's implementation comes from.
    fulfilment: *"catalog" | "provider"

    // OpenAPIv3-compatible schema. The exposed field name is the camelCase
    // form of metadata.name (e.g., name "container" -> spec.container).
    spec!: (strings.ToCamel(metadata.#definitionName)): _
}
```

### Resource Example

```cue
#ContainerResource: core.#Resource & {
    metadata: {
        name:           "container"
        modulePath:     "opmodel.dev/catalogs/opm/resources"
        apiVersion:     "v1beta1"
        catalogVersion: "1.0.0"
        fqn:            "opmodel.dev/catalogs/opm/resources/container@v1beta1"
        description:    "A container definition for workloads"
        // Categorisation only — descriptive, never matched on.
        labels: "resource.opmodel.dev/category": "workload"
    }

    // Matching identity — what a transformer's requiredLabels selects on.
    // The key belongs to the declaring catalog; `core` names none.
    matchLabels: "opm.opmodel.dev/workload-type": "stateless"

    spec: container: {
        image!:           string
        command?:         [...string]
        args?:            [...string]
        env?:             [...{name: string, value: string}]
        ports?:           [...{containerPort: int, protocol?: string}]
        imagePullPolicy?: "Always" | "IfNotPresent" | "Never"
    }
}
```

The Resource's `matchLabels` unify wholesale into any Component that attaches it, and ComponentTransformers select on that field. `metadata.labels` stays where it is written: it carries categorisation, which legitimately differs between the primitives of one Component, so it is neither unified upward nor matched on.

**CUE schema**: [`../src/resource.cue`](../src/resource.cue)

---

## Trait

A **Trait** represents a behavioral characteristic or configuration modifier that attaches to a Resource. Traits are the "adjectives" of OPM — they answer the question "how does this thing behave?" or "how is this thing configured?" A Trait cannot exist in isolation; it requires a Resource to make sense. Examples include Scaling (instance count and autoscaling), HealthCheck (liveness probing), Expose (network reachability), and RestartPolicy (failure response).

Traits describe **modification** rather than existence. They express **preference** — a Trait says "I want this behavior."

### What Trait Infers

- "This **modifies** how something operates"
- "This **requires** a Resource to make sense"
- "This describes **behavior** or **configuration**"

### When to Create a Trait

Ask yourself:

- Does this modify how something else operates?
- Is this a preference/configuration rather than a mandate?
- Can it only make sense when attached to a Resource?

**Examples**: Scaling, HealthCheck, Expose, RestartPolicy, UpdateStrategy

### Trait Structure

```cue
#Trait: {
    kind: "Trait"

    metadata: {
        name!:           #NameType
        modulePath!:     #PackagePathType  // e.g., "opmodel.dev/catalogs/opm/traits"
        apiVersion!:     #APIVersionType   // contract level
        catalogVersion!: #VersionType      // build provenance
        fqn!:            #ContractFQNType  // authored by the declaring catalog
        description?:    string
        labels?:         #LabelsAnnotationsType   // categorisation only
        annotations?:    #LabelsAnnotationsType
    }

    // Matching identity — unified wholesale into every Component that
    // attaches this primitive; what a transformer's requiredLabels selects on.
    matchLabels?: #LabelsAnnotationsType

    fulfilment: *"catalog" | "provider"

    // Whether an unhandled demand for this Trait fails the render or warns.
    // NO DEFAULT in core — the declaring catalog states the posture AS A
    // DEFAULT (`bool | *true` advisory, `bool | *false` load-bearing), and a
    // module overrides it at the attachment site.
    optional: bool

    // Resources this Trait can be applied to (full references).
    appliesTo!: [...#Resource]

    spec!: (strings.ToCamel(metadata.#definitionName)): _
}
```

### Key Difference from Resource

Traits carry an `appliesTo` list that declares which Resources they can modify:

```text
Trait → appliesTo → Resource
```

### Trait Example

```cue
#ScalingTrait: core.#Trait & {
    metadata: {
        name:           "scaling"
        modulePath:     "opmodel.dev/catalogs/opm/traits"
        apiVersion:     "v1beta1"
        catalogVersion: "1.0.0"
        fqn:            "opmodel.dev/catalogs/opm/traits/scaling@v1beta1"
        description:    "Scaling behavior for a workload"
    }

    // Load-bearing: an unhandled scaling demand should fail the render.
    // Stated as a DEFAULT so a module can override it at the attachment site.
    optional: bool | *false

    appliesTo: [#ContainerResource]

    spec: scaling: {
        count: int & >=1 & <=1000 | *1
        auto?: #AutoscalingSpec
    }
}
```

**CUE schema**: [`../src/trait.cue`](../src/trait.cue)

---

## Blueprint

A **Blueprint** represents a reusable pattern that composes Resources and Traits into a higher-level abstraction. Blueprints are the "templates" of OPM — they answer the question "what is the standardized pattern?" A Blueprint simplifies complex configurations by grouping related definitions under a single schema, hiding the complexity of individual primitives from the end user.

Blueprints are used to define standardized workload types (e.g., "StatelessWorkload", "SimpleDatabase") composed from specific Resources (Container, Volume) and Traits (Scaling, Expose).

### What Blueprint Infers

- "This is a **composition** of Resources and Traits"
- "This is a **reusable pattern**"
- "This **simplifies** configuration"

### When to Create a Blueprint

Ask yourself:

- Do you find yourself repeatedly defining the same set of Resources and Traits?
- Do you want to standardize a specific architectural pattern?
- Do you want to expose a simplified schema while managing underlying complexity?

**Examples**: StatelessWorkload, StatefulWorkload, CronJob, SimpleDatabase

### Blueprint Structure

```cue
#Blueprint: {
    kind: "Blueprint"

    metadata: {
        name!:        #NameType
        // Exactly "<catalog registryPath>/blueprints" — one segment per kind,
        // with NO grouping segment beneath it. A blueprint filed deeper is
        // refused at publish by #CatalogMemberFQNGate.
        modulePath!:     #PackagePathType  // e.g., "opmodel.dev/catalogs/opm/blueprints"
        apiVersion!:     #APIVersionType   // contract level
        catalogVersion!: #VersionType      // build provenance
        fqn!:            #ContractFQNType  // authored by the declaring catalog
        description?:    string
        labels?:         #LabelsAnnotationsType   // categorisation only
        annotations?:    #LabelsAnnotationsType
    }

    // NOTE: a Blueprint carries no `fulfilment` field — the definition is
    // closed, so declaring one is `field not allowed`. Nothing can demand a
    // Blueprint, so the field would be unreachable.

    // Matching identity — unified wholesale into every Component that
    // attaches this primitive; what a transformer's requiredLabels selects on.
    matchLabels?: #LabelsAnnotationsType

    composedResources!: [...#Resource]   // required composition
    composedTraits?:    [...#Trait]      // optional composition

    spec!: (strings.ToCamel(metadata.#definitionName)): _
}
```

### Blueprint Example

```cue
#StatelessWorkloadBlueprint: core.#Blueprint & {
    metadata: {
        name:           "stateless-workload"
        modulePath:     "opmodel.dev/catalogs/opm/blueprints"
        apiVersion:     "v1beta1"
        catalogVersion: "1.0.0"
        fqn:            "opmodel.dev/catalogs/opm/blueprints/stateless-workload@v1beta1"
        description:    "A stateless workload pattern"
    }

    composedResources: [#ContainerResource]
    composedTraits:    [#ScalingTrait, #ExposeTrait]

    spec: statelessWorkload: {
        image!:  string
        scaling: { count: int | *1 }
        port?:   int
    }
}
```

**CUE schema**: [`../src/blueprint.cue`](../src/blueprint.cue)
