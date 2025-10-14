# Module Architecture

> **Technical Reference**: Deep dive into OPM's three-layer module architecture
> **Audience**: Core contributors, platform implementers, advanced users
> **Related**: [Concepts: Modules](../../../opm/docs/concepts/modules.md), [Values Guide](../../../opm/docs/guides/platform-team/configuring-values.md)

## Overview

The Module architecture is the cornerstone of OPM's separation of concerns. It defines how applications flow from developer intent to platform policy to user deployment through three distinct layers: **ModuleDefinition**, **Module**, and **ModuleRelease**.

**Key Innovation**: CUE's constraint refinement (not override inheritance) enables each layer to progressively refine configurations without violating parent contracts.

## Three-Layer Architecture

### Design Philosophy

Traditional systems use override inheritance (child values replace parent values). OPM uses **CUE constraint refinement**: each layer adds constraints that narrow possibilities, never violate parent rules.

```shell
Developer: "replicas must be uint"
Platform:  "replicas must be uint AND defaults to 3"
User:      "replicas is 5" (satisfies both constraints)
```

### Layer Responsibilities

| Layer | Owner | Purpose | Values Role |
|-------|-------|---------|-------------|
| **ModuleDefinition** | Developer | Portable blueprint | Schema/constraints only |
| **Module** | Platform | Curated with policies | Add defaults, refine constraints |
| **ModuleRelease** | End User | Deployed instance | Provide concrete values |

---

## ModuleDefinition

### Purpose

Defines the **application contract**: what components exist, what values are configurable, what constraints apply. Platform-agnostic and reusable across environments.

### Structure

```cue
#ModuleDefinition: {
    #metadata: {
        name!:    string
        version!: string
        description?: string
    }

    // Application components
    components: [ID=string]: #Component & {#metadata: #id: ID}

    // Developer-defined scopes (optional)
    scopes?: [ID=string]: #Scope & {#metadata: #id: ID}

    // Configuration schema - CONSTRAINTS ONLY
    values: {
        // No defaults! Platform adds them.
        ...
    }
}
```

### Values: Schema/Constraints Only

**Critical**: ModuleDefinition.values defines the **contract**, not defaults.

**Must be OpenAPIv3 compliant**: No CUE templating (for/if statements) allowed in ModuleDefinition.values.

```cue
// ✅ Correct - Define constraints
values: {
    replicas: uint                          // Type constraint
    domain!: string                         // Required field
    environment: "dev" | "staging" | "prod" // Enum constraint
    port: >0 & <65536                       // Range constraint
}

// ❌ Incorrect - Don't add defaults
values: {
    replicas: uint | *3  // Platform's job, not developer's
}

// ❌ Incorrect - Don't use templating
values: {
    for name, comp in components {
        "\(name)Image": string  // Not allowed in Definition
    }
}
```

**Rationale**:

- Developers define what's configurable and valid
- Platform teams decide defaults for their environment
- OpenAPIv3 compliance ensures portability and tooling compatibility

### Example

```cue
#MyAppDefinition: #ModuleDefinition & {
    #metadata: {
        name:    "web-application"
        version: "1.0.0"
    }

    components: {
        web: #StatelessWorkload & {
            statelessWorkload: {
                container: {
                    image: values.image
                    ports: http: {targetPort: values.port}
                }
                replicas: count: values.replicas
            }
        }
    }

    values: {
        image!:   string  // Required - no default possible
        port:     >0 & <65536
        replicas: uint
    }
}
```

---

## Module

### Purpose

Platform-curated version of a ModuleDefinition. Platform teams:

- Add sensible defaults
- Refine constraints (regex patterns, tighter ranges)
- Add platform-specific components (monitoring, logging)
- Add immutable PlatformScopes (security policies)

### Structure

```cue
#Module: {
    #metadata: {
        name:     string
        version?: string
    }

    // Reference to base definition
    moduleDefinition: #ModuleDefinition

    // Platform adds components (optional)
    components?: [ID=string]: #Component

    // Platform adds scopes (optional)
    scopes?: [ID=string]: #Scope

    // CUE constraint refinement
    values: moduleDefinition.values & {
        // Platform refines constraints, adds defaults
        ...
    }

    // Computed: all components (definition + platform)
    #allComponents: {...}

    // Computed: all scopes (definition + platform)
    #allScopes: {...}
}
```

### Values: Constraint Refinement

Platform teams **refine** Definition constraints using CUE unification:

```cue
// Definition provided
values: {
    domain!: string
    port: >0 & <65536
}

// Module refines
values: {
    domain: string & =~".*\\.myplatform\\.com$"  // Add regex
    port:   >0 & <65536 | *8080                  // Add default
    region: string | *"us-west"                   // New field
}
```

**Capabilities**:

1. **Add defaults**: `replicas: uint | *3`
2. **Refine with regex**: `domain: string & =~"pattern"`
3. **Narrow ranges**: `port: >8000 & <9000` (within Definition's `>0 & <65536`)
4. **Add new fields**: For platform components/scopes
5. **Template values**: Use for/if statements to generate values dynamically

### Templating Values

**Unlike ModuleDefinition**, Module.values does NOT need to be OpenAPIv3 compliant. Platform teams can use CUE templating (for/if statements) to dynamically generate values:

```cue
// ModuleDefinition provides components
components: {
    api: {...}
    web: {...}
    worker: {...}
}

// Module templates image values from components
values: {
    for name, comp in moduleDefinition.components {
        "\(name)Image": string | *"registry.platform.com/\(name):latest"
    }

    // Results in:
    // apiImage: string | *"registry.platform.com/api:latest"
    // webImage: string | *"registry.platform.com/web:latest"
    // workerImage: string | *"registry.platform.com/worker:latest"
}
```

**Important**: Templating makes fields concrete at the Module layer. This gives platform teams control over generated defaults while still allowing user overrides at ModuleRelease.

```cue
// Conditional templating
values: {
    if len(moduleDefinition.components) > 1 {
        loadBalancerEnabled: bool | *true
    }

    for name, comp in moduleDefinition.components
    if comp.#elements["core.opm.dev/v1alpha1.StatefulWorkload"] != _|_ {
        "\(name)StorageSize": string | *"10Gi"
    }
}
```

### Platform Components

Platform can add infrastructure components:

```cue
_module: #Module & {
    moduleDefinition: _myAppDef

    // Add monitoring
    components: {
        monitoring: #DaemonWorkload & {
            daemonWorkload: container: {
                image: "prometheus:latest"
            }
        }
    }

    values: {
        enableMetrics: bool | *true  // New field for platform component
    }
}
```

### Platform Scopes

Platform adds **immutable** governance policies:

```cue
scopes: {
    security: #Scope & {
        #metadata: {immutable: true}
        #elements: {NetworkScope: #NetworkScopeElement}
        networkScope: networkPolicy: externalCommunication: false
        appliesTo: "*"
    }
}
```

Users cannot override immutable scopes (enforced platform policy).

---

## ModuleRelease

### Purpose

Deployed instance of a Module. End users provide concrete values satisfying Module's refined constraints.

### Structure

```cue
#ModuleRelease: {
    #metadata: {
        name!:    string
        version?: string
    }

    // Reference to platform module
    module: #Module

    // Provider for transformation
    provider: #Provider

    // User provides concrete values
    values: module.values & {
        ...
    }
}
```

### Values: Concrete Implementation

Users see Module's refined constraints (NOT Definition's original constraints):

```cue
// Module provides
values: {
    domain: string & =~".*\\.myplatform\\.com$"
    port:   >0 & <65536 | *8080
    region: string | *"us-west"
}

// User provides concrete values
values: {
    domain: "myapp.myplatform.com"  // Satisfies regex
    port:   8080                     // Use default
    region: "eu-west"                // Override default
}
```

**Single-Level Inheritance**: Users only see Module's constraints. Definition's original constraints are hidden (already incorporated into Module).

---

## Value Flow Example

Complete three-layer example:

```cue
// 1. Developer: ModuleDefinition (constraints)
_definition: #ModuleDefinition & {
    values: {
        replicas: uint
        domain!:  string
        tier:     "free" | "standard" | "premium"
    }
}

// 2. Platform: Module (add defaults, refine)
_module: #Module & {
    moduleDefinition: _definition
    values: {
        replicas: uint | *3                           // Add default
        domain:   string & =~".*\\.platform\\.com$"  // Refine with regex
        tier:     ("free" | "standard" | "premium") | *"free"
        region:   string | *"us-west"                 // New field
    }
}

// 3. User: ModuleRelease (concrete values)
_release: #ModuleRelease & {
    module: _module
    values: {
        replicas: 5                      // Override default
        domain:   "app.platform.com"     // Satisfies regex
        tier:     "premium"              // Override default
        region:   "us-west"              // Use default
    }
}
```

---

## Implementation Details

### Component Aggregation

```cue
#allComponents: {
    // Definition components
    for id, comp in moduleDefinition.components {
        "\(id)": comp
    }
    // Platform components
    if components != _|_ {
        for id, comp in components {
            "\(id)": comp
        }
    }
}
```

### Scope Aggregation

```cue
#allScopes: {
    // Definition scopes
    if moduleDefinition.scopes != _|_ {
        for id, scope in moduleDefinition.scopes {
            "\(id)": scope
        }
    }
    // Platform scopes
    if scopes != _|_ {
        for id, scope in scopes {
            "\(id)": scope
        }
    }
}
```

### Status Tracking

```cue
#status: {
    totalComponentCount:    len(#allComponents)
    platformComponentCount: len(components)
    platformScopeCount:     len(scopes)
}
```

---

## Key Principles

### 1. Constraint Refinement, Not Override

CUE unification refines (narrows) constraints. Cannot violate parent properties:

```cue
// ✅ Valid refinement
parent: uint
child:  uint | *3  // More specific (adds default)

// ❌ Invalid - conflicts
parent: uint
child:  string  // Type mismatch
```

### 2. OpenAPIv3 Compliance

**ModuleDefinition.values MUST be OpenAPIv3 compliant**:

- No CUE templating (for/if statements)
- Pure schema/constraints only
- Ensures portability and tooling compatibility

**Module.values does NOT need to be OpenAPIv3 compliant**:

- Can use CUE templating (for/if statements)
- Platform teams can dynamically generate values
- Makes fields concrete for their environment

```cue
// ❌ ModuleDefinition - No templating
values: {
    for name, comp in components {
        "\(name)Image": string  // Not allowed
    }
}

// ✅ Module - Templating allowed
values: {
    for name, comp in moduleDefinition.components {
        "\(name)Image": string | *"registry.platform.com/\(name):latest"
    }
}
```

### 3. Single-Level Inheritance

ModuleRelease only sees Module's constraints:

```shell
Definition:  replicas: uint
Module:      replicas: uint | *3
Release:     ↑ sees this (not Definition's original)
```

### 4. Platform Cannot Override Developer Defaults

If Definition has defaults (anti-pattern), Platform cannot override:

```cue
// ❌ Anti-pattern - Definition has default
definition.values: {
    tier: string | *"free"
}

// Platform CANNOT override to "standard"
// Can only refine further (e.g., add regex)
```

**Solution**: Definition provides constraints only.

### 5. Immutability of Platform Scopes

Platform scopes marked `immutable: true` cannot be modified by users. Enforces governance.

---

## Testing

See integration tests:

- [module_values_flow.cue](../../tests/integration/module_values_flow.cue) - Value constraint refinement (6 tests)
- [module_templating.cue](../../tests/integration/module_templating.cue) - Platform value templating with for/if (7 tests)
- [module_composition.cue](../../tests/integration/module_composition.cue) - Component/scope addition (4 tests)
- [application_scenarios.cue](../../tests/integration/application_scenarios.cue) - Complete examples (4 tests)

---

## Related Documentation

- **Concepts**: [Understanding Modules](../../../opm/docs/concepts/modules.md)
- **Guide**: [Creating Modules](../../../opm/docs/guides/developer/creating-modules.md)
- **Guide**: [Curating Modules](../../../opm/docs/guides/platform-team/curating-modules.md)
- **Architecture**: [Component Model](./component.md), [Scope System](./scope.md)
- **Reference**: [module.cue source](../../module.cue)

---

## Changelog

- **2025-10-10**: Refactored to CUE constraint refinement (removed `#unifiedValues`)
- **2025-09-15**: Initial three-layer architecture design
