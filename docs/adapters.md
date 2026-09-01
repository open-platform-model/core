# OPM Adapters

Adapters are the translation layer between the OPM application model and a concrete target runtime. They describe what a target supports and how Components render into target-specific resources.

Adapters consume [Constructs](constructs.md) and [Primitives](primitives.md), but live outside the composition hierarchy — they do not appear inside a Module's `#components` or as part of a Module's portable definition. They are wired into the runtime (CLI, operator, compile pipeline) at deploy time.

See [Definition Types](definition-types.md) for the full taxonomy.

---

## ComponentTransformer

A **ComponentTransformer** converts an OPM Component into a single platform-specific resource (e.g., a Kubernetes Deployment, Service, or PersistentVolumeClaim). Each ComponentTransformer produces exactly one output resource — a Component that needs multiple platform resources is matched by multiple ComponentTransformers.

ComponentTransformers use a multi-dimensional matching system: required labels, required Resources, and required Traits must **all** be present on a Component for the transformer to match. The compile pipeline computes matches across all ComponentTransformers in the active registry, then invokes each matched transformer's `#transform` to produce its output.

`#ComponentTransformer` is the sole transformer primitive at the Component layer. Module-scope transformation (planned) is handled by a separate `#ModuleTransformer` adapter; both are members of `#TransformerMap`.

### What ComponentTransformer Infers

- "This converts a Component into **one platform-specific resource**"
- "This matches Components by **labels and definition FQNs**"
- "This produces a **single, concrete** runtime resource"

### ComponentTransformer Structure

```cue
#ComponentTransformer: {
    // NO apiVersion. A transformer is an ADAPTER, not a primitive: its inputs
    // are other people's contracts and its output is platform objects, so
    // "this transformer's contract level" has no referent. `metadata` is
    // closed, so declaring one is `field not allowed`.
    kind: "ComponentTransformer"

    metadata: {
        name!:           #NameType         // e.g., "deployment-transformer"
        modulePath!:     #PackagePathType  // e.g., "opmodel.dev/catalogs/opm/transformers"
        catalogVersion!: #VersionType      // SemVer of the build it shipped in

        // Authored by the declaring catalog. An IMPLEMENTATION key — keyed on
        // the build, not on a contract level.
        fqn!:         #ImplFQNType  // e.g., ".../transformers/deployment@1.0.0"
        description!: string
        labels?:      #LabelsAnnotationsType   // categorization, not matching
        annotations?: #LabelsAnnotationsType
    }

    // Matching criteria — ALL must be satisfied. Labels are selected against
    // #Component.matchLabels, never against metadata.labels.
    requiredLabels?:    #LabelsAnnotationsType         // Component must carry these
    requiredResources?: [#ContractFQNType]: #Resource  // Component must include these
    requiredTraits?:    [#ContractFQNType]: #Trait     // Component must include these

    // Optional definitions — used if present, defaults applied otherwise.
    optionalLabels?:    #LabelsAnnotationsType
    optionalResources?: [#ContractFQNType]: #Resource
    optionalTraits?:    [#ContractFQNType]: #Trait

    // The transform function — the context projects itself from the two
    // inputs; the runtime fills only #context.#runtimeName (0019 D12).
    #transform: {
        #moduleInstance: _                    // fully concrete #ModuleInstance
        #component:      _                    // matched Component
        #context:        #TransformerContext  // computed from the two inputs above
        output:          {...} | [...{...}]   // one resource, or a list of resources
    }
}

// TransformerMap is the union surface for all transformer adapters
// (today: #ComponentTransformer; future: #ModuleTransformer).
#TransformerMap: [#ImplFQNType]: #ComponentTransformer
```

### TransformerContext

The `#TransformerContext` a `#transform` body reads is a projection of the other two inputs (enhancement 0019 D12): the two metadata blocks compute from `#moduleInstance` and `#component` at the `#transform` site, and the runtime supplies only `#runtimeName`. It carries:

- `#moduleInstanceMetadata` — name, namespace, fqn, version, uuid, labels, annotations, projected from `#moduleInstance` (version through the instance's module metadata).
- `#componentMetadata` — name, labels, annotations, projected from the matched Component. The name is the component's own `metadata.name`, never the `#components`-map key it sat under.
- `#runtimeName` — identity of the runtime executing the transform (e.g., `"opm-cli"` for the CLI, `"opm-controller"` for the operator). Stamped onto every rendered resource as `app.kubernetes.io/managed-by`. The one field the runtime fills.
- Computed `labels` / `annotations` — final maps merged from module, component, and controller layers, ready to apply to the output.

Runtimes must populate `#runtimeName` and nothing else; CUE evaluation fails if it is missing (see SPEC.md § 4.1, including the transitional fill rule for staged runtimes).

### Matching Flow

```text
Component
├── matchLabels:       {"opm.opmodel.dev/workload-type": "stateless"}
│                      └─ unified from the attached primitives' matchLabels
├── #resources:        {"...container@v1": ...}
└── #traits:           {"...scaling@v1": ..., "...expose@v1": ...}

                              ▼ pipeline checks each ComponentTransformer:

DeploymentTransformer (#ComponentTransformer)
├── requiredLabels:    {"opm.opmodel.dev/workload-type": "stateless"}  ✓
├── requiredResources: {"...container@v1": ...}                          ✓
└── requiredTraits:    {}                                                ✓
                                                              → MATCH (emits Deployment)

ServiceTransformer (#ComponentTransformer)
├── requiredLabels:    {}                                                ✓
├── requiredResources: {}                                                ✓
└── requiredTraits:    {"...expose@v1": ...}                             ✓
                                                              → MATCH (emits Service)
```

A single Component may match multiple ComponentTransformers — each contributes a different runtime resource.

**CUE schema**: [`../src/transformer.cue`](../src/transformer.cue)

---

## Platform

> **Planned** — not present in `core/v1alpha2` yet.

A **Platform** models a deployment target as a single, composable construct. It carries the target's identity (`metadata`, `type`) and a path-keyed `#registry` of catalog entries; each entry embeds its imported catalog whole and derives its `version` and `#transformers` from it (enhancement 0019 D5).

`#Platform` retires the older `#Provider` shape: instead of a static `#providers` list, matching consumes the Platform's derived `#composedTransformers` fold directly. There is no reverse index on the platform (enhancement 0019 D17); the render build's matching glue derives its own contract-to-transformer buckets from `#composedTransformers`.

Platform integration lands incrementally via the kernel-redesign slices (see [`library/enhancements/001-kernel-redesign-around-platform/`](../../library/enhancements/001-kernel-redesign-around-platform/)) and the catalog enhancement (see [`catalog/enhancements/014-platform-construct/`](../../catalog/enhancements/014-platform-construct/)). This document will be expanded once the construct ships in the kernel.
