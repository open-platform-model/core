# Module Architecture

> **Technical Reference**: Deep dive into OPM's two-concept module system
> **Audience**: Core contributors, platform implementers, advanced users
> **Related**: [Component Model](./component.md), [Provider System](./provider.md)

## Overview

The Module architecture defines how applications flow from developer blueprints to deployed instances. OPM uses a **two-concept system** that separates blueprint definition from deployment instantiation.

**Key Innovation**: Transformers and renderers are selected at deployment time, not pre-baked into definitions. This enables flexible platform targeting while maintaining portable application blueprints.

---

## Two-Concept System

### Design Philosophy

OPM separates concerns between application structure (what to deploy) and platform adaptation (how to deploy):

```text
ModuleDefinition (portable blueprint) → Module (platform-specific deployment)
```

### Concept Responsibilities

| Concept | Owner | Purpose | Contains |
|---------|-------|---------|----------|
| **#ModuleDefinition** | Developer | Portable application blueprint | Components, value schema (constraints only) |
| **#Module** | End User/Platform | Deployed instance | Definition reference, transformers, renderer, concrete values |

**No Inheritance Chain**: Module directly references ModuleDefinition. There is no intermediate curation layer.

---

## ModuleDefinition

### Purpose

Defines the **application contract**: what components exist, what values are configurable, what constraints apply. Platform-agnostic and reusable across environments.

### Structure

```cue
#ModuleDefinition: {
    #kind:       "ModuleDefinition"
    #apiVersion: "core.opm.dev/v0"

    #metadata: {
        name!:              string
        version!:           string
        description?:       string
        defaultNamespace?:  string | *"default"
        labels?:            [string]: string
        annotations?:       [string]: string
    }

    // Application components
    components: [ID=string]: #Component & {#metadata: #id: ID}

    // Developer-defined scopes (optional)
    scopes?: [ID=string]: #Scope & {#metadata: #id: ID}

    // Configuration schema - CONSTRAINTS ONLY, NO DEFAULTS
    values: {...}

    // Computed: all scopes
    #allScopes: {...}

    // Computed: all primitive elements across components
    #allPrimitiveElements: [string]

    #status: {
        componentCount: len(components)
        scopeCount:     int
    }
}
```

### Values: Schema/Constraints Only

**Critical**: ModuleDefinition.values defines the **contract**, not defaults or concrete values.

```cue
// ✅ Correct - Define constraints
values: {
    image!:      string                    // Required field
    replicas:    uint                      // Type constraint
    environment: "dev" | "staging" | "prod" // Enum constraint
    port:        >0 & <65536               // Range constraint
}

// ❌ Incorrect - Don't add defaults
values: {
    replicas: uint | *3  // Defaults belong in Module or deployment config
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
- Deployment-time configuration provides defaults and concrete values
- Portability: Same definition works across different platforms and environments

### Example

```cue
webAppDefinition: #ModuleDefinition & {
    #metadata: {
        name:    "web-application"
        version: "1.0.0"
        labels: {
            "app.type": "web"
            team:       "frontend"
        }
    }

    components: {
        frontend: {
            #metadata: {
                name: "frontend"
                labels: {
                    component: "frontend"
                    tier:      "web"
                }
            }

            elements.#StatelessWorkload

            statelessWorkload: {
                container: {
                    name:  "web"
                    image: values.frontend.image
                    ports: {
                        http: {
                            targetPort: 3000
                            protocol:   "TCP"
                        }
                    }
                }
            }
        }

        database: {
            #metadata: {
                name: "database"
                labels: {
                    component: "database"
                    tier:      "data"
                }
            }

            elements.#SimpleDatabase

            simpleDatabase: {
                engine:   "postgres"
                version:  "15"
                persistence: {
                    enabled: true
                    size:    values.database.storageSize
                }
            }
        }
    }

    // Value contract - constraints only
    values: {
        frontend: {
            image!: string  // Required
        }
        database: {
            storageSize!: string  // Required
        }
        environment!: string  // Required
    }
}
```

### Computed Fields

```cue
// #allPrimitiveElements: Extracted from all components
#allPrimitiveElements: [
    "elements.opm.dev/core/v0.Container",
    "elements.opm.dev/core/v0.SimpleDatabase",
    // ... unique list
]
```

---

## Module

### Purpose

Deployed instance of a ModuleDefinition. Users:

- Reference a ModuleDefinition
- Select transformers (from providers)
- Select a renderer
- Provide concrete values
- Get rendered output automatically

### Structure

```cue
#Module: {
    #kind:       "Module"
    #apiVersion: "core.opm.dev/v0"

    #metadata: {
        name!:        string
        namespace:    string | *"default"
        version?:     string
        labels?:      [string]: string
        annotations?: [string]: string
    }

    // Reference to ModuleDefinition
    #moduleDefinition!: #ModuleDefinition

    // Explicit transformer-to-component mapping - REQUIRED
    // Maps transformer FQN to {transformer, components list}
    #transformersToComponents!: [string]: {
        transformer: #Transformer
        components: [...string]  // List of component IDs
    }

    // Renderer selected from catalog - REQUIRED
    #renderer!: #Renderer

    // User provides concrete values
    values: #moduleDefinition.values & {...}

    // Embedded rendering logic - automatically computed
    output: {
        // Single manifest output (e.g., Kubernetes List)
        manifest?: _

        // Multi-file output (e.g., Kustomize)
        files?: [string]: _

        // Rendering metadata
        metadata?: {
            format:      string  // "yaml", "json", etc.
            entrypoint?: string  // Main file for multi-file outputs
        }
    }

    #status: {
        definitionName: #moduleDefinition.#metadata.name
    }
}
```

### Transformer-to-Component Mapping

The `#transformersToComponents` field explicitly maps transformers to the components they should process. This enables flexible, expression-based component selection.

```cue
// Provider offers transformers
kubernetesProvider: #Provider & {
    transformers: {
        "k8s.io/api/apps/v1.Deployment":            #DeploymentTransformer
        "k8s.io/api/apps/v1.StatefulSet":           #StatefulSetTransformer
        "k8s.io/api/core/v1.PersistentVolumeClaim": #PVCTransformer
        // ...
    }
}

// Module creates explicit mapping with expressions
myApp: #Module & {
    #transformersToComponents: {
        "k8s.io/api/apps/v1.Deployment": {
            transformer: kubernetesProvider.transformers["k8s.io/api/apps/v1.Deployment"]
            // Select components using expressions
            components: [
                for id, comp in #moduleDefinition.components
                if comp.#metadata.labels["core.opm.dev/workload-type"] == "stateless" &&
                   list.Contains(comp.#primitiveElements, "elements.opm.dev/core/v0.Container") {
                    id
                },
            ]
        }
        "k8s.io/api/apps/v1.StatefulSet": {
            transformer: kubernetesProvider.transformers["k8s.io/api/apps/v1.StatefulSet"]
            components: [
                for id, comp in #moduleDefinition.components
                if comp.#metadata.labels["core.opm.dev/workload-type"] == "stateful" {
                    id
                },
            ]
        }
        "k8s.io/api/core/v1.PersistentVolumeClaim": {
            transformer: kubernetesProvider.transformers["k8s.io/api/core/v1.PersistentVolumeClaim"]
            components: [
                for id, comp in #moduleDefinition.components
                if list.Contains(comp.#primitiveElements, "elements.opm.dev/core/v0.Volume") {
                    id
                },
            ]
        }
    }
}
```

**Key Benefits**:

1. **Explicit & Inspectable**: Can see exactly which transformers apply to which components
2. **Expression-Based**: Use CUE expressions to dynamically select components
3. **DRY Pattern**: Reference `transformer.#metadata.labels` to avoid duplication
4. **Zero Hardcoding**: Module rendering logic just iterates the explicit mapping
5. **Future-Ready**: Clear path to transformer selectors for automation

**Note**: Due to a CUE limitation, transformers cannot use `if #component.field != _|_` guards before iterating over optional fields. See `BUG_CUE_ITERATION.md` for details. The workaround is to iterate directly without the existence check.

### Renderer Selection

Renderers format transformed resources into output:

```cue
// Catalog provides renderers
catalog: #PlatformCatalog & {
    renderers: {
        "kubernetes-list":      #KubernetesListRenderer
        "kubernetes-kustomize": #KubernetesKustomizeRenderer
        "docker-compose":       #DockerComposeRenderer
    }
}

// Module selects one
myApp: #Module & {
    #renderer: catalog.renderers["kubernetes-list"]
}
```

### Values: Concrete Implementation

Users provide concrete values that satisfy ModuleDefinition constraints:

```cue
// Definition provides
values: {
    frontend: {
        image!: string
    }
    database: {
        storageSize!: string
    }
    environment!: string
}

// Module provides concrete values
values: {
    frontend: {
        image: "myapp-frontend:1.2.3"
    }
    database: {
        storageSize: "20Gi"
    }
    environment: "production"
}
```

### Embedded Rendering

The Module automatically renders output:

1. **Transform**: Applies selected transformers to components based on primitive elements
2. **Render**: Applies selected renderer to transformed resources
3. **Output**: Exposes via `output.manifest`, `output.files`, or both

```text
#Module
  └─> #moduleDefinition.components
        └─> for each component
              └─> for each primitive element
                    └─> #transformers[primitive]
                          └─> transform(component, context)
                                └─> resources
  └─> resources[]
        └─> #renderer.render(resources)
              └─> output.manifest OR output.files
```

### Example

```cue
// End-user creates deployment
productionApp: #Module & {
    #metadata: {
        name:      "web-app-prod"
        namespace: "production"
        labels: {
            environment: "production"
        }
        annotations: {
            "deployed.by": "platform-team"
            "git.commit":  "abc123def"
        }
    }

    // Reference definition from catalog
    #moduleDefinition: catalog.moduleDefinitions["web-application"]

    // Map transformers to components
    #transformersToComponents: {
        "k8s.io/api/apps/v1.Deployment": {
            transformer: kubernetesProvider.transformers["k8s.io/api/apps/v1.Deployment"]
            components: ["frontend"]  // Explicit component IDs
        }
        "k8s.io/api/core/v1.PersistentVolumeClaim": {
            transformer: kubernetesProvider.transformers["k8s.io/api/core/v1.PersistentVolumeClaim"]
            components: ["database"]
        }
    }

    // Select renderer
    #renderer: catalog.renderers["kubernetes-list"]

    // Provide concrete values
    values: {
        frontend: {
            image: "registry.example.com/web-app:v1.2.3"
        }
        database: {
            storageSize: "50Gi"
        }
        environment: "production"
    }

    // output.manifest automatically populated with Kubernetes List
}
```

---

## Platform Catalog

### Structure

The Platform Catalog provides the registry of available definitions, providers, and renderers:

```cue
#PlatformCatalog: {
    #kind:       "PlatformCatalog"
    #apiVersion: "core.opm.dev/v0"

    #metadata: {
        name!:        string
        version!:     string
        description?: string
        labels?:      [string]: string
        annotations?: [string]: string
    }

    // Available providers (with transformers)
    providers!: #ProviderMap

    // Available renderers
    renderers!: #RendererMap

    // Registered module definitions (NO transformers attached here)
    moduleDefinitions: [string]: #ModuleDefinition

    // Available element registry
    #availableElements!: #ElementRegistry

    // Validation and status
    #providerCapabilities: {...}
    #status: {
        elementCount:  int
        providerCount: int
        rendererCount: int
        moduleCount:   int
    }
}
```

**Key Point**: `moduleDefinitions` contains bare ModuleDefinition instances. Transformers and renderers are NOT attached at catalog level.

### Example

```cue
platformCatalog: #PlatformCatalog & {
    #metadata: {
        name:    "example-kubernetes-platform"
        version: "1.0.0"
    }

    #availableElements: elements.#CoreElementRegistry

    providers: {
        kubernetes: kubernetesProvider  // Contains transformers
    }

    renderers: {
        "kubernetes-list":      #KubernetesListRenderer
        "kubernetes-kustomize": #KubernetesKustomizeRenderer
    }

    moduleDefinitions: {
        "web-application": webAppDefinition  // Just the definition
        "blog-app":        blogAppDefinition
        "api-service":     apiServiceDefinition
    }
}
```

---

## Complete Workflow Example

### 1. Developer Creates Definition

```cue
package myapp

import (
    opm "github.com/open-platform-model/core"
    elements "github.com/open-platform-model/elements/core"
)

blogAppDefinition: opm.#ModuleDefinition & {
    #metadata: {
        name:    "blog-app"
        version: "1.0.0"
    }

    components: {
        frontend: {
            elements.#StatelessWorkload
            statelessWorkload: {
                container: {
                    image: values.frontend.image
                    ports: {http: {targetPort: 3000}}
                }
            }
        }

        database: {
            elements.#SimpleDatabase
            simpleDatabase: {
                engine:  "postgres"
                version: "15"
                persistence: {
                    enabled: true
                    size:    values.database.storageSize
                }
            }
        }
    }

    values: {
        frontend: {image!: string}
        database: {storageSize!: string}
        environment!: string
    }
}
```

### 2. Developer Tests Locally

```cue
// Mock transformers for local testing
_mockDeploymentTransformer: opm.#Transformer & {
    #kind:       "Deployment"
    #apiVersion: "k8s.io/api/apps/v1"
    required:    ["elements.opm.dev/core/v0.Container"]
    optional:    []
    transform: {/* simplified logic */}
}

// Local test module
blogAppLocal: opm.#Module & {
    #metadata: {
        name:      "blog-app-test"
        namespace: "development"
    }

    #moduleDefinition: blogAppDefinition

    // Map transformers to components
    #transformersToComponents: {
        "k8s.io/api/apps/v1.Deployment": {
            transformer: _mockDeploymentTransformer
            components: ["frontend"]
        }
        "k8s.io/api/core/v1.PersistentVolumeClaim": {
            transformer: _mockPVCTransformer
            components: ["database"]
        }
    }

    #renderer: opm.#KubernetesListRenderer

    values: {
        frontend: {image: "blog-frontend:dev"}
        database: {storageSize: "5Gi"}
        environment: "development"
    }
}

// Test: cue export . -e blogAppLocal.output
```

### 3. Platform Team Adds to Catalog

```cue
platformCatalog: opm.#PlatformCatalog & {
    #metadata: {
        name:    "platform-catalog"
        version: "1.0.0"
    }

    #availableElements: elements.#CoreElementRegistry

    providers: {
        kubernetes: kubernetesProvider
    }

    renderers: {
        "kubernetes-list": opm.#KubernetesListRenderer
    }

    // Add developer's definition
    moduleDefinitions: {
        "blog-app": blogAppDefinition
    }
}
```

### 4. End User Deploys

```cue
productionBlog: opm.#Module & {
    #metadata: {
        name:      "blog-prod"
        namespace: "production"
    }

    // Reference from catalog
    #moduleDefinition: platformCatalog.moduleDefinitions["blog-app"]

    // Map transformers to components using expressions
    #transformersToComponents: {
        "k8s.io/api/apps/v1.Deployment": {
            transformer: platformCatalog.providers.kubernetes.transformers["k8s.io/api/apps/v1.Deployment"]
            components: [
                for id, comp in #moduleDefinition.components
                if comp.#metadata.labels["core.opm.dev/workload-type"] == "stateless" {
                    id
                },
            ]
        }
        "k8s.io/api/core/v1.PersistentVolumeClaim": {
            transformer: platformCatalog.providers.kubernetes.transformers["k8s.io/api/core/v1.PersistentVolumeClaim"]
            components: [
                for id, comp in #moduleDefinition.components
                if list.Contains(comp.#primitiveElements, "elements.opm.dev/core/v0.Volume") {
                    id
                },
            ]
        }
    }

    #renderer: platformCatalog.renderers["kubernetes-list"]

    values: {
        frontend: {image: "blog-frontend:v1.2.3"}
        database: {storageSize: "100Gi"}
        environment: "production"
    }

    // output.manifest automatically contains rendered Kubernetes resources
}

// Deploy: cue export . -e productionBlog.output.manifest
```

---

## Output Formats

### Manifest Output (Single File)

Used by: Kubernetes List, Docker Compose

```cue
output: {
    manifest: {
        apiVersion: "v1"
        kind:       "List"
        items: [
            // All rendered resources
        ]
    }
    metadata: {
        format: "yaml"
    }
}
```

### Files Output (Multiple Files)

Used by: Kustomize, Helm, Terraform

```cue
output: {
    files: {
        "kustomization.yaml": {
            apiVersion: "kustomize.config.k8s.io/v1beta1"
            kind:       "Kustomization"
            resources: ["deployments.yaml", "services.yaml"]
        }
        "deployments.yaml": [
            // Deployment resources
        ]
        "services.yaml": [
            // Service resources
        ]
    }
    metadata: {
        format:     "yaml"
        entrypoint: "kustomization.yaml"
    }
}
```

---

## Renderers

### Purpose

Renderers format transformed resources into platform-specific output formats. They are composable and reusable.

### Structure

```cue
#Renderer: {
    #kind:       "Renderer"
    #apiVersion: "core.opm.dev/v0"

    #metadata: {
        name:        string
        description: string
        version:     string
    }

    targetPlatform: string

    // Render function
    render: {
        // Input: list of transformed resources
        resources: _

        // Output: rendered manifest(s)
        output: #RendererOutput
    }
}

#RendererOutput: {
    manifest?: _              // Single manifest
    files?: [string]: _       // Multiple files
    metadata?: {
        format:      string   // "yaml", "json", "toml", "hcl"
        entrypoint?: string
    }
}
```

### Built-in: Kubernetes List Renderer

```cue
#KubernetesListRenderer: #Renderer & {
    #metadata: {
        name:        "kubernetes-list"
        description: "Renders to Kubernetes List format"
        version:     "1.0.0"
    }
    targetPlatform: "kubernetes"

    render: {
        resources: _
        output: {
            manifest: {
                apiVersion: "v1"
                kind:       "List"
                items:      resources
            }
            metadata: {
                format: "yaml"
            }
        }
    }
}
```

### Custom Renderer Example

```cue
#TerraformRenderer: #Renderer & {
    #metadata: {
        name:        "terraform"
        description: "Renders to Terraform HCL"
        version:     "1.0.0"
    }
    targetPlatform: "terraform"

    render: {
        resources: _
        output: {
            files: {
                "main.tf": {/* HCL content */}
                "variables.tf": {/* Variables */}
            }
            metadata: {
                format:     "hcl"
                entrypoint: "main.tf"
            }
        }
    }
}
```

---

## Key Principles

### 1. Separation of Concerns

- **ModuleDefinition**: What to deploy (portable)
- **Module**: How to deploy (platform-specific)
- **No pre-baking**: Transformers/renderers selected at deployment time

### 2. Flexibility at Deployment

Users can:

- Deploy same definition to different platforms
- Mix and match transformers
- Choose different renderers for different use cases
- Override values per environment

### 3. Developer Experience

Developers:

- Create portable definitions
- Test locally with mock transformers
- Submit to platform teams
- No need to know platform details

### 4. Platform Control

Platform teams:

- Provide production-grade transformers
- Offer multiple renderers
- Validate definitions before adding to catalog
- Don't need to "pre-bake" every combination

---

## Comparison with Other Systems

### Helm

| Aspect | OPM | Helm |
|--------|-----|------|
| Definition | ModuleDefinition (CUE) | Chart (templates + values.yaml) |
| Templating | Type-safe CUE | Text-based Go templates |
| Values | Strongly typed schema | Loosely typed YAML |
| Rendering | Pluggable renderers | Built-in Kubernetes YAML |
| Portability | Platform-agnostic | Kubernetes-specific |

### Kustomize

| Aspect | OPM | Kustomize |
|--------|-----|-----------|
| Composition | Components + values | Bases + overlays |
| Validation | CUE type system | YAML schema |
| Transformation | Programmable transformers | Patches |
| Abstraction | High-level elements | Low-level resources |

### Crossplane Compositions

| Aspect | OPM | Crossplane |
|--------|-----|------------|
| Scope | Application deployment | Infrastructure provisioning |
| Runtime | Compile-time (CUE) | Runtime (Kubernetes controllers) |
| Transformers | User-defined CUE | Provider-specific controllers |
| Outputs | Static manifests | Live Kubernetes resources |

---

## Testing

See test files:

- [tests/unit/module.cue](../../tests/unit/module.cue) - Module and ModuleDefinition unit tests
- [tests/integration/application_scenarios.cue](../../tests/integration/application_scenarios.cue) - Complete deployment examples
- [examples/developer/](../../examples/developer/) - Developer workflow examples

---

## Related Documentation

- **Code**: [module.cue](../../module.cue), [renderer.cue](../../renderer.cue)
- **Architecture**: [Component Model](./component.md), [Provider System](./provider.md)
- **Examples**: [Developer Flow](../../examples/developer/README.md)

---

## Changelog

- **2025-10-21**: Complete rewrite to document actual two-concept implementation
  - Removed three-layer architecture documentation (not implemented)
  - Documented transformer/renderer attachment at Module level
  - Added developer testing workflow
  - Updated output structure (manifest/files/metadata)
  - Clarified catalog structure (bare definitions)
- **2025-10-10**: Refactored to CUE constraint refinement (removed `#unifiedValues`)
- **2025-09-15**: Initial three-layer architecture design (superseded)
