# OPM Design Philosophy

> **How OPM combines fine-grained constraints with infinite abstractions through intelligent element composition**

This document explains the core design principles that make OPM uniquely powerful: bounded provider complexity with unbounded abstraction capability, achieved through a three-tier element system.

---

## Table of Contents

- [The Dual Path: Constraints AND Abstractions](#the-dual-path-constraints-and-abstractions)
- [The Three-Tier Element Architecture](#the-three-tier-element-architecture)
- [Finite Implementation, Infinite Abstraction](#finite-implementation-infinite-abstraction)
- [When to Use Each Approach](#when-to-use-each-approach)
- [The Power of Context-Aware Constraints](#the-power-of-context-aware-constraints)
- [Contrast with Other Approaches](#contrast-with-other-approaches)
- [Design Principles in Practice](#design-principles-in-practice)

---

## The Dual Path: Constraints AND Abstractions

**Core Insight**: OPM uniquely provides **both fine-grained constraints and full abstractions** - developers choose the right tool for each use case.

Unlike traditional configuration systems that force a single approach, OPM recognizes that different problems require different solutions:

- **Need direct platform access?** Use primitives with constraints
- **Need stable, reusable patterns?** Use composites as abstractions
- **Need to add specific concerns?** Use constraint modifiers

### The Problem with Single-Path Approaches

**Full Abstractions Only** (Traditional):

- Inevitable drift from upstream platforms
- High maintenance overhead
- Breaking changes when platforms evolve
- Lag behind new features
- Provider must implement every pattern

**Constraints Only** (Pure CUE):

- Powerful validation
- No built-in abstraction model
- Every team rebuilds common patterns
- No shared vocabulary

**OPM's Solution**: Combine both through architectural separation.

---

## The Three-Tier Element Architecture

OPM's element system provides three distinct tiers, each serving a specific purpose:

### 1. Primitives: Direct Platform Access

**Definition**: Minimal, provider-implemented building blocks exposing platform capabilities directly.

**Characteristics**:

- Only tier that requires provider implementation
- Fine-grained constraints on critical values (security, resources)
- Looser validation on peripheral fields (metadata, platform-specific features)
- New platform features available immediately
- Direct access to full platform APIs

**Examples**:

```cue
#Container: #Primitive & {
    schema: {
        image!: string  // Required - critical
        ports?: [string]: {targetPort: uint, protocol?: string}
        securityContext?: {  // Strong constraints when present
            runAsNonRoot?: bool | *true
            readOnlyRootFilesystem?: bool | *true
        }
    }
}
```

**Key Insight**: Primitives implement CUE's principle of "fine-grained constraints over full abstractions" - strong limits on what matters, flexibility everywhere else.

### 2. Constraint Modifiers: Composable Validation Layers

**Definition**: Context-aware constraint layers that add fine-grained validation and defaults to components.

**Characteristics**:

- No provider implementation required
- Add specific concerns (scaling, health, deployment strategy)
- Workload-type-aware defaults and constraints
- Compose independently without coupling
- Pure constraint addition, no primitive modification

**Examples**:

```cue
// Scaling constraint
#Replicas: #Modifier & {
    schema: {count: int | *1}
}

// Health validation constraint
#HealthCheck: #Modifier & {
    schema: {
        liveness?: {httpGet: {path: string, port: uint}}
        readiness?: {httpGet: {path: string, port: uint}}
    }
}

// Context-aware restart constraint
#RestartPolicy: #Modifier & {
    schema: {
        policy: "Always" | "OnFailure" | "Never"

        // Adapts to workload type!
        if #metadata.labels["core.opm.dev/workload-type"] == "stateless" {
            policy: "Always"  // Stateless defaults to Always
        }
        if #metadata.labels["core.opm.dev/workload-type"] == "task" {
            policy: "OnFailure" | "Never" | *"Never"  // Tasks default to Never
        }
    }
}
```

**Key Insight**: Modifiers are intelligent constraint policies, not just configuration additions - they adapt based on component context.

### 3. Composites: Infinite Abstractions

**Definition**: Human-created combinations of primitives and modifiers for any pattern, requiring zero provider work.

**Characteristics**:

- Built from primitives + modifiers (no provider implementation)
- Create stable, reusable abstractions
- Encapsulate organizational practices
- Evolve independently of platform changes
- Fixed workload-type annotations for validation

**Examples**:

```cue
// Common pattern abstraction
#StatelessWorkload: #Composite & {
    composes: [#Container, #Replicas, #HealthCheck, #RestartPolicy, #UpdateStrategy]
    annotations: {"core.opm.dev/workload-type": "stateless"}
}

// Organizational standard abstraction
#CompanyMicroservice: #Composite & {
    composes: [#StatelessWorkload, #Monitoring, #Security, #CompliancePolicy]
    annotations: {"company.com/pattern": "standard-microservice"}
}

// Domain-specific abstraction
#MLTrainingJob: #Composite & {
    composes: [#Container, #GPUResources, #VolumeMount, #JobCompletion]
    annotations: {"core.opm.dev/workload-type": "task"}
}
```

**Key Insight**: Composites enable unlimited abstractions from finite primitives - providers implement once, humans create infinite patterns.

---

## Finite Implementation, Infinite Abstraction

### The Architecture Separation

**What Providers Implement**:

```
Container (1 primitive)
Volume (1 primitive)
NetworkScope (1 primitive)
ConfigMap (1 primitive)
Secret (1 primitive)
---
~15-20 primitives total
```

**What Humans Create**:

```
From Container primitive alone:
- StatelessWorkload (composite)
- StatefulWorkload (composite)
- DaemonWorkload (composite)
- TaskWorkload (composite)
- WebService (composite)
- APIGateway (composite)
- Microservice (composite)
- MLTrainingJob (composite)
- CompanyStandardAPI (composite)
- [unlimited patterns...]
```

### The Key Guarantees

1. **Bounded Provider Complexity**:
   - Implement ~15-20 primitives
   - Support unlimited abstractions
   - No changes needed for new patterns

2. **Unbounded Abstraction Capability**:
   - Create organization-specific patterns
   - Standardize team practices
   - Build domain-specific languages
   - Encapsulate compliance requirements

3. **Stable Platform Contract**:
   - Primitive API is the only provider contract
   - Composites change without breaking providers
   - New abstractions = zero provider work

4. **Platform Agility**:
   - New platform features in primitives immediately
   - Stable abstractions in composites independently
   - No forced breaking changes

---

## When to Use Each Approach

### Use Primitives Directly

**When**:

- Building advanced/custom patterns
- Need platform-specific optimizations
- Require immediate access to new features
- Creating new organizational abstractions

**Example**:

```cue
components: {
    advanced: {
        #Container  // Direct primitive access
        #Volume
        #Replicas

        container: {
            image: "custom:latest"
            // Use new K8s feature immediately
            securityContext: seccompProfile: type: "RuntimeDefault"
        }
    }
}
```

### Use Constraint Modifiers

**When**:

- Adding specific concerns to components
- Need workload-type-aware defaults
- Want composable validation layers
- Enforcing organizational policies

**Example**:

```cue
components: {
    api: {
        #Container
        #Replicas       // Add scaling constraint
        #HealthCheck    // Add health validation
        #RestartPolicy  // Add restart constraint (workload-aware!)

        replicas: count: 3
        healthCheck: liveness: httpGet: {path: "/health", port: 8080}
    }
}
```

### Use Composites (Abstractions)

**When**:

- Using common, repeatable patterns
- Standardizing team/org practices
- Simplifying developer experience
- Creating stable module contracts

**Example**:

```cue
components: {
    web: {
        #StatelessWorkload  // Stable abstraction

        stateless: {
            container: {image: "nginx:latest"}
            replicas: count: 3
        }
    }
}
```

### Mix All Three

**The Power**: Combine approaches in the same component

```cue
components: {
    hybrid: {
        #Microservice  // Composite abstraction (includes #StatelessWorkload + monitoring)

        // Add custom constraint modifier
        #CustomCompliance

        // Override with primitive access when needed
        container: {
            securityContext: {
                runAsUser: 1000  // Specific override
            }
        }
    }
}
```

---

## The Power of Context-Aware Constraints

### Workload-Type Intelligence

OPM's constraint modifiers are **context-aware** - they adapt based on component metadata:

```cue
#RestartPolicy: #Modifier & {
    #metadata: _  // Access component metadata

    restartPolicy: {
        // Constraints adapt to workload type!
        if #metadata.labels["core.opm.dev/workload-type"] == "stateless" {
            policy: "Always"  // Stateless always restart
        }
        if #metadata.labels["core.opm.dev/workload-type"] == "task" {
            policy: "OnFailure" | "Never" | *"Never"  // Tasks don't loop
        }
    }
}

#UpdateStrategy: #Modifier & {
    #metadata: _

    updateStrategy: {
        // Different strategies for different workloads
        if #metadata.labels["core.opm.dev/workload-type"] == "stateless" {
            type: "RollingUpdate" | "Recreate" | *"RollingUpdate"
            rollingUpdate?: {maxUnavailable: int, maxSurge: int}
        }
        if #metadata.labels["core.opm.dev/workload-type"] == "stateful" {
            type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
            rollingUpdate?: {partition: int}  // Different fields!
        }
    }
}
```

### Benefits of Context-Aware Constraints

1. **Type-Specific Defaults**: Right defaults for each workload type
2. **Validation Adaptation**: Constraints match workload capabilities
3. **Error Prevention**: Invalid combinations caught at compile-time
4. **Developer Guidance**: IDE shows only valid options for context

---

## Contrast with Other Approaches

### vs Helm Charts

**Helm**:

- Templates only (single approach)
- No primitive/composite separation
- All patterns equally expensive to maintain
- Provider must support every abstraction
- Runtime errors

**OPM**:

- Primitives (constraints) + Composites (abstractions)
- Clear architectural separation
- Providers implement ~15 primitives once
- Unlimited abstractions with zero provider cost
- Compile-time validation

### vs Pure CUE

**Pure CUE**:

- Powerful constraint system
- No built-in abstraction patterns
- Every team rebuilds common patterns
- No shared element vocabulary

**OPM**:

- CUE's constraint power in primitives/modifiers
- Built-in abstraction patterns via composites
- Reusable element catalog
- Standard vocabulary across teams

### vs Kubernetes Operators

**Operators**:

- Must implement every abstraction (CRDs)
- Each pattern = new controller code
- High implementation cost
- Platform-specific

**OPM**:

- Implement primitives once
- Abstractions = composition (no code)
- Bounded implementation cost
- Platform-portable

### vs Traditional Abstractions (OAM, etc.)

**Traditional**:

- Full abstractions that drift from platforms
- Breaking changes when platforms evolve
- Maintenance overhead

**OPM**:

- Fine-grained constraints (primitives) + stable abstractions (composites)
- Primitives track platforms without breaking
- Composites evolve independently

---

## Design Principles in Practice

### Principle 1: Bounded Provider Surface

**Rule**: Providers implement only primitives (~15-20 elements)

**Benefit**: Fixed complexity, unlimited capability

**Example**:

```shell
Kubernetes Provider implements:
- Container, Volume, ConfigMap, Secret, NetworkScope
- ~15 primitives total
- Supports 1000s of composite abstractions
```

### Principle 2: Smart Constraints Through Optionality

**Rule**: Primitives use strong constraints on critical concerns while allowing flexibility through optional fields

**Benefit**: Safety with adaptability

**Example**:

```cue
#Container: {
    image!: string  // Required - critical
    securityContext?: {  // Optional but constrained when present
        runAsNonRoot?: bool | *true  // Default secure
        allowPrivilegeEscalation?: bool | *false
        capabilities?: drop: [string] | *["ALL"]
    }
    resources?: {  // Optional but validated
        limits?: {cpu?: string, memory?: string}
        requests?: {cpu?: string, memory?: string}
    }
}
```

### Principle 3: New Platform Features Through Elements

**Rule**: New platform capabilities are exposed through the element system - either directly in primitives when applicable, or as modifiers to inform provider transformers

**Benefit**: Type-safe access to new features without breaking abstractions

**Example**:

```cue
// Option 1: Add to primitive directly (core feature)
#Container: {
    securityContext?: {
        seccompProfile?: {type: string, localhostProfile?: string}
    }
}

// Option 2: Create modifier element (cross-cutting concern)
#SeccompProfile: #Modifier & {
    schema: {
        type: "RuntimeDefault" | "Localhost" | "Unconfined"
        localhostProfile?: string
    }
    // Informs Kubernetes provider how to render PodSecurityContext
}
```

### Principle 4: Context-Aware Constraints

**Rule**: Modifiers adapt based on component metadata

**Benefit**: Right defaults, fewer errors

**Example**:

```cue
#RestartPolicy: {
    if #metadata.labels["core.opm.dev/workload-type"] == "task" {
        policy: "OnFailure" | "Never" | *"Never"  // Tasks don't loop
    }
}
```

### Principle 5: Composition Over Implementation

**Rule**: Build abstractions through composition, not provider code

**Benefit**: Unlimited patterns, zero provider cost

**Example**:

```cue
// No provider work needed:
#Microservice: #Composite & {
    composes: [#StatelessWorkload, #Monitoring, #Tracing]
}
```

---

## Summary

OPM's design philosophy delivers the best of all approaches:

1. **Fine-Grained Constraints** (Primitives)
   - Direct platform access
   - Strong validation on critical concerns
   - Flexibility for new features

2. **Composable Constraint Layers** (Modifiers)
   - Context-aware validation
   - Workload-type intelligence
   - Independent composition

3. **Full Abstractions** (Composites)
   - Stable, reusable patterns
   - Organizational standards
   - Unlimited creation

**The Result**: Bounded provider complexity (~15 primitives) enables unbounded abstraction capability (infinite composites), with intelligent constraints (modifiers) adapting to context.

This is not "constraints **or** abstractions" - it's "constraints **and** abstractions through architectural separation."

---

## Related Documentation

- **[Element System Architecture](architecture/element-system.md)** - Deep dive into element implementation
- **[OPM vs Helm](../../opm/docs/opm-vs-helm.md)** - Comparison with template-based approaches
- **[Architecture Overview](../../opm/docs/architecture.md)** - High-level OPM architecture
- **[Element Catalog](https://github.com/open-platform-model/elements/docs/element-catalog.md)** - Available elements
- **[Creating Elements](https://github.com/open-platform-model/elements/docs/creating-elements.md)** - Guide for new elements
