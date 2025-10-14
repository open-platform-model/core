# Element System Architecture

> **Deep dive into OPM's element type system, design patterns, and architectural decisions**

This document explains the architectural foundations of the OPM element system - how elements work internally, why they're designed this way, and the patterns used to implement them.

**Audience**: Core contributors, element authors, platform implementers wanting to understand or extend the element system.

**For element catalog and usage**: See [Element Catalog](https://github.com/open-platform-model/elements/docs/element-catalog.md) in the elements repository.

---

## Table of Contents

- [Element Foundation](#element-foundation)
- [Element Type System](#element-type-system)
- [The Component Pattern for Elements](#the-component-pattern-for-elements)
- [Element Implementation Patterns](#element-implementation-patterns)
- [Component Composition](#component-composition)
- [Component Validation](#component-validation)
- [Design Decisions](#design-decisions)

---

## Element Foundation

### Core Principle

**Everything is an element.** Elements are the atomic building blocks of OPM. Primitive elements (Container, Volume, Network) combine into composite elements (Database, WebService), which compose into complete modules.

### Element Structure

Elements in OPM follow a unified pattern based on the `#Element` foundation defined in [element.cue](../element.cue):

```cue
#Element: {
    name!:               string
    #apiVersion:         string | *"core.opm.dev/v0alpha1"
    #fullyQualifiedName: "\(#apiVersion).\(name)"

    // What kind of element this is
    kind!: #ElementKinds  // "primitive", "modifier", "composite", "custom"

    // Where can element be applied
    target!: ["component"] | ["scope"] | ["component", "scope"]

    // MUST be an OpenAPIv3 compatible schema
    schema!: _

    // Human-readable description
    description?: string

    // Optional labels for categorization
    labels?: #LabelsAnnotationsType

    // Optional annotations for element behavior hints (not used for categorization)
    // Providers can use annotations for decision-making (e.g., workload type selection)
    // Example: {"core.opm.dev/workload-type": "stateless"}
    annotations?: [string]: string
}
```

**Key Fields**:

- **name**: Element identifier (e.g., "Container", "Replicas")
- **kind**: How it composes - `primitive` (standalone), `modifier` (enhances others), `composite` (combines multiple), or `custom` (special handling)
- **target**: Where it applies - `component`, `scope`, or both
- **schema**: OpenAPIv3-compatible schema defining configuration structure
- **labels**: Optional metadata for categorization and filtering (e.g., `{"core.opm.dev/category": "workload"}`)
- **annotations**: Optional behavior hints for providers (e.g., `{"core.opm.dev/workload-type": "stateless"}`)
- **#fullyQualifiedName**: Global unique identifier (e.g., "core.opm.dev/v0alpha1.Container")

---

## Element Type System

### Element Categorization with Labels

OPM uses **labels** for element categorization and filtering instead of a fixed type system. This provides maximum flexibility and extensibility.

**Common Label Patterns**:

```cue
labels: {
    "core.opm.dev/category": "workload"      // Category: workload, data, connectivity, security, observability
    "core.opm.dev/platform": "kubernetes,docker"     // Platform compatibility
    "core.opm.dev/maturity": "stable"         // Maturity level: alpha, beta, stable
    "core.opm.dev/compliance": "pci-dss"      // Compliance framework support
    "custom.example.com/team": "platform"     // Custom organization labels
}
```

**Benefits of Label-Based Categorization**:

1. **Extensibility**: Add new categorization dimensions without schema changes
2. **Filtering**: Query elements by any label combination
3. **Multi-dimensional**: Elements can belong to multiple categories
4. **Custom Labels**: Organizations can add their own categorization schemes
5. **Future-Proof**: New use cases don't require core changes

**Example Usage**:

```cue
// Filter by category
workloadElements: [for name, elem in #CoreElementRegistry if elem.labels["core.opm.dev/category"] == "workload" {elem}]

// Filter by multiple criteria
stableK8sElements: [for name, elem in #CoreElementRegistry
    if elem.labels["core.opm.dev/platform"] == "kubernetes" &&
       elem.labels["core.opm.dev/maturity"] == "stable" {elem}]
```

**Planned Enhancement**: A comprehensive label-based filtering and query system is planned for future releases. See [ROADMAP.md](../../../opm/ROADMAP.md) for details.

### Element Kinds

Elements are categorized by how they compose:

#### 1. Primitive (`kind: "primitive"`)

**Definition**: Basic building blocks that create or represent standalone resources. Cannot be decomposed further.

**Characteristics**:

- Implemented directly by the platform
- Can stand alone in a component
- Create platform resources (Deployment, Volume, etc.)
- Have no dependencies on other elements

**Examples**:

- `Container` - Creates containerized workload (category: workload)
- `Volume` - Creates persistent storage (category: data)
- `NetworkScope` - Creates network boundary (category: connectivity)

**Implementation**:

```cue
#Primitive: #Element & {
    kind: "primitive"
}
```

#### 2. Modifier (`kind: "modifier"`)

**Definition**: Elements that enhance primitives or composites without creating separate resources.

**Characteristics**:

- Cannot stand alone - must be used with compatible elements
- Modify the output or behavior of primitives/composites
- Declare which elements they can modify via `modifies` field
- Don't create independent platform resources

**Examples**:

- `Replicas` - Adds scaling to workloads (category: workload)
- `HealthCheck` - Adds health probes to containers (category: workload)
- `Expose` - Adds service exposure to workloads (category: connectivity)

**Implementation**:

```cue
#Modifier: #Element & {
    kind: "modifier"

    // Which elements this can modify
    modifies!: #ElementStringArray
}
```

#### 3. Composite (`kind: "composite"`)

**Definition**: Combinations of primitives and modifiers for common patterns.

**Characteristics**:

- Bundles multiple elements together
- Provides convenience and clear intent
- Can set fixed workload type via annotations for validation
- Maps directly to platform resources
- Tracks which primitives it composes via `composes` field

**Examples**:

- `StatelessWorkload` - Container + Replicas + modifiers (category: workload)
- `StatefulWorkload` - Container + Volume + modifiers (category: workload)
- `SimpleDatabase` - Stateful workload pattern (category: data)

**Implementation**:

```cue
#Composite: #Element & {
    kind: "composite"

    // Which primitives/elements this composes
    composes!: #ElementArray

    // Recursively extract all primitive elements
    #primitiveElements: list.FlattenN([
        for element in composes {
            if element.kind == "primitive" {[element.#fullyQualifiedName]}
            if element.kind == "composite" {element.#primitiveElements}
            if element.kind != "primitive" && element.kind != "composite" {[]}
        },
    ], -1)

    // Composites should declare workload type via annotations if applicable
    annotations?: [string]: string
}
```

#### 4. Custom (`kind: "custom"`)

**Definition**: Platform-specific extensions with special handling outside OPM spec.

**Use Case**: Last resort for capabilities that don't fit the standard element model.

**Implementation**:

```cue
#Custom: #Element & {
    kind: "custom"
}
```

---

## Element Annotations System

### Purpose

Element annotations provide behavior hints to providers without being used for categorization or filtering. The `"core.opm.dev/workload-type"` annotation ensures each component has exactly one workload type, preventing ambiguous or conflicting workload definitions.

### Annotations vs Labels

- **Labels** (`labels?: [string]: string`): For categorization and filtering at OPM level
  - Example: `{"core.opm.dev/category": "workload"}`
  - Used by OPM core for element organization and queries

- **Annotations** (`annotations?: [string]: string`): For behavior hints at provider level
  - Example: `{"core.opm.dev/workload-type": "stateless"}`
  - Providers interpret annotations for decision-making (e.g., transformer selection)
  - Kubernetes-style pattern for extensibility

### Workload Type Annotation

**Annotation Key**: `"core.opm.dev/workload-type"`

**Valid Values**:

- `"stateless"` - Deployment-like workloads
- `"stateful"` - StatefulSet-like workloads
- `"daemon"` - DaemonSet-like workloads
- `"task"` - Job-like workloads
- `"scheduled-task"` - CronJob-like workloads
- `"function"` - Serverless functions
- *Omit annotation* - For non-workload components (e.g., config-only)

### How It Works

1. **Elements declare annotations**: Elements can include annotations map with workload type
2. **Components derive workloadType**: Components automatically extract workloadType from `"core.opm.dev/workload-type"` annotation
3. **Validation enforces uniqueness**: Components validate that all workload-type annotations have the same value

### Examples

**✅ Flexible WorkloadType** (Container primitive):

```cue
#ContainerElement: {
    annotations?: {
        "core.opm.dev/workload-type"?: "stateless" | "stateful" | "daemon" | "task" | "scheduled-task"
        ...
    }
}
```

**✅ Fixed WorkloadType** (StatelessWorkload composite):

```cue
#StatelessWorkloadElement: {
    annotations: {
        "core.opm.dev/workload-type": "stateless"  // Always stateless
    }
}
```

**❌ Invalid** (Conflicting workload types):

```cue
myComponent: #Component & {
    #StatelessWorkload  // annotations: {"core.opm.dev/workload-type": "stateless"}
    #StatefulWorkload   // annotations: {"core.opm.dev/workload-type": "stateful"} - CONFLICT!
}
```

### Benefits

1. **Kubernetes-aligned**: Same pattern as K8s annotations
2. **Provider flexibility**: Providers interpret annotations as needed
3. **Extensible**: Easy to add new annotations (scheduling hints, resource patterns, etc.)
4. **Clear separation**: Labels for categorization (OPM-level), annotations for hints (provider-level)
5. **Type Safety**: Components validate single workload type
6. **Better Validation**: Catch errors at compile-time

---

## The Component Pattern for Elements

### Problem

CUE requires structural compatibility for composition. Simply embedding `#Element` in multiple places creates type conflicts.

### Solution: #Component

Elements use `#Component` as their base, which provides the `#elements` map for element registration:

```cue
#Component: {
    #elements: #ElementMap
    ...  // Critical: enables CUE composition without type conflicts
}
```

Every element definition uses this pattern:

```cue
#Container: #Component & {
    #elements: Container: #Primitive & {
        name: "Container"
        description: "Single container primitive"
        target: ["component"]
        labels: {"core.opm.dev/category": "workload"}
        schema: #ContainerSpec
    }

    container: #ContainerSpec  // Field name MUST be camelCase of element name
}
```

**CRITICAL**: The configuration field name MUST be the camelCase version of the element name (computed via `strings.ToCamel(element.name)`). This enables automatic schema validation in `component.cue`.

### Why This Works

1. **Automatic Element Registration**: `#elements` field contains element metadata
2. **CUE Composition**: `...` allows unification with other `#Component` instances
3. **Type Safety**: Each element has its own configuration field (`container`, `replicas`, etc.)
4. **Registry Integration**: Components can extract all `#elements` for validation and transformation
5. **Automatic Schema Validation**: `component.cue` merges element schemas using `(elem.#nameCamel): elem.schema` pattern

### Usage in Components

```cue
myComponent: #Component & {
    #Container  // Adds Container element to #elements
    #Replicas   // Adds Replicas element to #elements
    #HealthCheck  // Adds HealthCheck element to #elements

    // Component automatically has:
    // #elements: {
    //     Container: #Primitive & {...}
    //     Replicas: #Modifier & {...}
    //     HealthCheck: #Modifier & {...}
    // }
}
```

---

## Element Implementation Patterns

### Primitive Element Pattern

Primitives create standalone resources:

```cue
// Primitive element - Creates containerized workload
#Container: #Component & {
    #elements: Container: #Primitive & {
        name: "Container"
        description: "Base container definition"
        target: ["component"]
        workloadType: "stateless" | "stateful" | "daemon Set" | "task" | "scheduled-task"
        labels: {"core.opm.dev/category": "workload"}
        schema: #ContainerSpec
    }

    container: #ContainerSpec
}

// Primitive element - Creates storage (map-based)
#Volume: #Component & {
    #elements: Volume: #Primitive & {
        name: "Volume"
        description: "Volume storage primitive"
        target: ["component"]
        labels: {"core.opm.dev/category": "data"}
        schema: #VolumeSpec
    }

    volume: [string]: #VolumeSpec
}
```

### Modifier Element Pattern

Modifiers enhance primitives/composites:

```cue
// Modifier element - Adds scaling
#Replicas: #Component & {
    #elements: Replicas: #Modifier & {
        name: "Replicas"
        description: "Scale workload instances"
        target: ["component"]
        modifies: []  // Compatible with Container and scalable composites
        labels: {"core.opm.dev/category": "workload"}
        schema: #ReplicasSpec
    }

    replicas: #ReplicasSpec
}
```

### Composite Element Pattern

Composites combine multiple elements:

```cue
// Composite element - Container + modifiers for stateless workloads
#StatelessWorkload: #Component & {
    #elements: StatelessWorkload: #Composite & {
        name: "StatelessWorkload"
        description: "Horizontally scalable containerized workload"
        target: ["component"]
        annotations: {
            "core.opm.dev/workload-type": "stateless"  // Fixed workload type
        }
        composes: [
            #ContainerElement,
            #ReplicasElement,
            #RestartPolicyElement,
            #UpdateStrategyElement,
            #HealthCheckElement,
            #SidecarContainersElement,
            #InitContainersElement
        ]
        labels: {"core.opm.dev/category": "workload"}
        schema: #StatelessSpec
    }

    statelessWorkload: #StatelessSpec  // camelCase of "StatelessWorkload"

    // Project fields from statelessWorkload to top level
    container: statelessWorkload.container
    replicas: statelessWorkload.replicas
    // ... other projections
}
```

---

## Component Composition

### Component Structure

Components are element compositions defined in [component.cue](../component.cue):

```cue
#Component: {
    #kind:       "Component"
    #apiVersion: "core.opm.dev/v0alpha1"

    #metadata: {
        #id!: string
        name!: string | *#id

        // Workload type automatically derived from element annotations
        workloadType: string | *""
        for _, elem in #elements {
            if elem.annotations != _|_ && elem.annotations[#AnnotationWorkloadType] != _|_ {
                workloadType: elem.annotations[#AnnotationWorkloadType]
            }
        }

        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    #elements: #ElementMap  // All elements in this component

    // Helper: Extract ALL primitive elements recursively
    #primitiveElements: list.FlattenN([
        for _, element in #elements {
            if element.kind == "primitive" {[element.#fullyQualifiedName]}
            if element.kind == "composite" {element.#primitiveElements}
            if element.kind != "primitive" && element.kind != "composite" {[]}
        },
    ], -1)
}
```

### Composition Examples

**Using Composite (Recommended)**:

```cue
web: #Component & {
    #metadata: #id: "web"

    #StatelessWorkload  // Sets annotations: {"core.opm.dev/workload-type": "stateless"}
    #Expose            // Adds service exposure

    statelessWorkload: {  // camelCase of "StatelessWorkload"
        container: {image: "nginx:latest", ports: http: {targetPort: 80}}
        replicas: {count: 3}
    }
    expose: {type: "LoadBalancer"}  // camelCase of "Expose"
}
```

**Using Primitive + Modifiers (Advanced)**:

```cue
custom: #Component & {
    #metadata: #id: "custom"

    #Container   // Primitive - flexible workload type via annotations
    #Replicas    // Modifier
    #HealthCheck // Modifier

    container: {image: "myapp:latest"}
    replicas: {count: 2}
    healthCheck: {liveness: {httpGet: {path: "/health", port: 8080}}}
}
```

---

## Component Validation

Components automatically validate element compatibility, workload type annotation constraints, and element schema conformance.

### Automatic Schema Validation

The `#Component` definition in [component.cue](../component.cue) automatically merges all element schemas for validation:

```cue
#Component: {
    // ... other fields

    // Automatic schema validation via dynamic field merging
    for _, elem in #elements {
        (elem.#nameCamel): elem.schema
    }
}
```

**How It Works**:

1. For each element in `#elements`, CUE creates a field with the camelCase element name
2. That field is constrained to the element's schema
3. When you provide configuration, CUE validates it against the schema automatically

**Example**:

```cue
web: #Component & {
    #StatelessWorkload  // Adds StatelessWorkloadElement to #elements

    // The for loop creates: statelessWorkload: #StatelessSpec
    // Your configuration must satisfy this schema
    statelessWorkload: {
        container: {image: "nginx:latest"}  // Validated against #StatelessSpec
    }
}
```

**This is why element field names MUST be camelCase of element names** - it ensures the schema validation merges correctly with the configuration fields.

### Validation Logic

```cue
#Component: {
    #validation: {
        // Extract primitives and modifiers
        primitives: [
            for name, elem in #elements
            if elem.kind == "primitive" {elem.#fullyQualifiedName}
        ]

        modifiers: [
            for name, elem in #elements
            if elem.kind == "modifier" {
                name: elem.#fullyQualifiedName
                elem: elem
            }
        ]

        // Validate each modifier has a valid target primitive
        modifierValidation: [
            for mod in modifiers {
                valid: or([
                    for primitive in primitives {
                        list.Contains(mod.elem.modifies, primitive)
                    }
                ]) | error("Modifier '\(mod.name)' requires one of \(mod.elem.modifies)")
            }
        ]

        // Validate workload type annotation consistency
        #workloadTypes: [
            for _, elem in #elements
            if elem.annotations != _|_ && elem.annotations[#AnnotationWorkloadType] != _|_
            {elem.annotations[#AnnotationWorkloadType]}
        ]

        // All workload types must be identical
        if len(#workloadTypes) > 1 {
            for wt in #workloadTypes {
                wt == #workloadTypes[0]  // Forces all to be equal
            }
        }
    }
}
```

### Invalid Component Examples

**Example 1: Conflicting Workload Types**:

```cue
invalid: #Component & {
    #StatelessWorkload  // annotations: {"core.opm.dev/workload-type": "stateless"}
    #StatefulWorkload   // annotations: {"core.opm.dev/workload-type": "stateful"} - CONFLICT!
}
```

**Example 2: Modifier Without Compatible Workload**:

```cue
invalid: #Component & {
    #Volume             // Just a resource, no workload
    #SidecarContainers  // ERROR: Requires Container or workload composite
}
```

---

## Design Decisions

### Why Container as Single Workload Primitive?

**Design**: OPM uses `Container` as the only workload primitive, then provides composite elements (StatelessWorkload, StatefulWorkload, etc.) for different patterns.

**Rationale**:

1. **Simplicity**: One primitive to implement in providers
2. **Flexibility**: Composites provide convenience without limiting advanced use
3. **Clear Mapping**: Each composite maps to specific platform resource
4. **Extensibility**: New workload patterns = new composites, not new primitives

### Why Composite Elements?

**Benefits**:

1. **Clear Intent**: `#StatelessWorkload` is more explicit than `#Container + #Replicas`
2. **Direct Platform Mapping**: Certain composites map 1:1 to platform resources (Deployment, StatefulSet)
3. **Type Safety**: Fixed workload type annotation prevents mixing incompatible patterns
4. **Simpler Providers**: Transformers match composites, not combinations of primitives
5. **Better Validation**: Catch configuration errors at compile-time
6. **Reusability**: Modifiers shared across composites
7. **Flexibility Preserved**: Advanced users can still use primitives directly

### Why #Component Pattern for Elements?

**Alternatives Considered**:

1. **Direct #Element embedding**: Fails due to CUE structural compatibility
2. **Element registry separate from definitions**: Requires manual registration
3. **Code generation**: Adds build complexity

**Why #Component Pattern Wins**:

1. **Automatic Registration**: Elements self-register via `#elements` field
2. **CUE Native**: Works with CUE's unification model
3. **Type Safe**: Each element has distinct configuration field
4. **No Boilerplate**: Single pattern for all elements

### Why Annotations Instead of WorkloadType Field?

**Alternatives Considered**:

1. **Direct workloadType field**: Inflexible, hard to extend with new hints
2. **Infer from element combinations**: Ambiguous and error-prone
3. **Separate workload elements per type**: Lots of primitive elements
4. **Provider decides workloadType**: Loses portability

**Why Annotations Win**:

1. **Kubernetes-aligned**: Same pattern as K8s annotations - familiar to users
2. **Extensible**: Easy to add new behavior hints (scheduling, resources, deployment strategies)
3. **Clear separation**: Labels for categorization (OPM-level), annotations for hints (provider-level)
4. **Validated**: CUE enforces single workload-type annotation value per component
5. **Portable**: Workload type annotation travels with component definition
6. **Provider-Friendly**: Providers interpret annotations as needed for decision-making
7. **Future-proof**: Can add new annotations without breaking changes

---

## Related Documentation

- **[Element Catalog](https://github.com/open-platform-model/elements/docs/element-catalog.md)** - Complete list of available elements
- **[Element Patterns](https://github.com/open-platform-model/elements/docs/element-patterns.md)** - Common composition patterns
- **[Creating Elements](https://github.com/open-platform-model/elements/docs/creating-elements.md)** - Guide for adding new elements
- **[Component Model](component-model.md)** - Component architecture (future)
- **[Provider Interface](provider-interface.md)** - Provider contract (future)
- **[Transformer System](transformer-system.md)** - Transformer selection logic (future)

---

**Questions or Suggestions?**

This is architectural documentation for core contributors. For usage questions, see the [Element Catalog](https://github.com/open-platform-model/elements/docs/element-catalog.md).
