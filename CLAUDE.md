# Open Platform Model (OPM) - Architecture Guide for Claude

## Project Overview

Open Platform Model (OPM) is a CUE-based framework for defining platform-agnostic application models that can be rendered to different target platforms (Kubernetes, Docker, etc.) through providers and transformers.

## Date

Year: 2025

## Core Architecture

### Layered Model Structure

```shell
Elements (primitives) → Components (collections) → Modules (applications) → Providers (renderers)
```

### Key Concepts

#### Elements

- **Primitive Elements**: Basic building blocks (Container, Volume, ConfigMap, etc.)
- **Composite Elements**: Combinations of primitives
- Elements have:
  - `type`: trait | resource | policy
  - `kind`: primitive | composite | modifier | custom
  - `target`: where they can be applied (component/scope)

#### Components

- Collections of elements that define a logical unit
- Can have `workloadType`: stateless | stateful | daemon | task | scheduled-task | function
- Contains `#primitiveElements` (recursively extracted from all elements)

#### Transformers

- Convert OPM components to platform-specific resources
- Key fields:
  - `creates`: what native resource it produces
  - `workloadTypes`: optional list of supported workload types
  - `required`: list of required element names
  - `optional`: list of optional element names
  - `transform`: function that does the conversion

#### Providers

- Registry of transformers for a specific platform
- Contains render logic to process modules

### Implementation Pattern

```cue
#SelectTransformer: {
    component: #Component
    availableTransformers: [string]: {...}

    // Assess each transformer
    assessments: {
        for tName, transformer in availableTransformers {
            // Calculate compatibility score
        }
    }

    // Select best match
    selectedTransformer: {
        // Sort by score and pick highest
    }
}
```

## Recent Changes

### 2025-09-30

1. **Major Reorganization**: Restructured elements into category-based hierarchy
   - Created `schema/` package for all spec definitions
   - Organized elements into `workload/`, `data/`, and `connectivity/` subdirectories
   - Resolved circular import dependencies between element categories
   - All schema types now in separate package to enable cross-category references

### 2025-09-29

1. Changed `workloadType` to `workloadTypes` (array) in #Transformer to support multiple types
2. Added #status inheritance in #Module from moduleDefinition
3. Exploring OSCAL-inspired assessment patterns for transformer selection

## Development Guidelines

### Testing Transformers

- Always verify required elements are satisfied
- Test with mixed workload/resource components
- Validate optional element handling

### Adding New Elements

**IMPORTANT:** All new elements MUST be added to the `elements/elements.cue` index file to be accessible when importing the elements package.

#### Element Organization

Elements are organized into category-based directories with separate schema definitions:

- **Categories**: `workload/` | `data/` | `connectivity/` | (future: `security/` | `observability/` | `governance/`)
- **Element Types**:
  - `primitive_traits.cue` - Basic building blocks
  - `modifier_traits.cue` - Modifiers that extend primitives
  - `composite_traits.cue` - Combinations of primitives/modifiers
  - `primitive_resources.cue` - Resource definitions
  - `composite_traits.cue` - Complex data compositions
- **Schema Package**: All `*Spec` definitions live in `schema/` package

#### Steps to Add a New Element

1. **Define the schema** in appropriate `schema/{category}.cue` file:

   ```cue
   // In schema/security.cue
   package schema

   #PodSecuritySpec: {
       runAsNonRoot?: bool | *true
       readOnlyRootFilesystem?: bool | *false
   }
   ```

2. **Create the element** in `elements/{category}/{type}.cue`:

   ```cue
   // In elements/security/primitive_traits.cue
   package security

   import (
       core "github.com/open-platform-model/core"
       schema "github.com/open-platform-model/core/schema"
   )

   #PodSecurityElement: core.#PrimitiveTrait & {
       name: "PodSecurity"
       #apiVersion: "elements.opm.dev/core/v1alpha1"
       target: ["component"]
       schema: schema.#PodSecuritySpec
       labels: {"core.opm.dev/category": "security"}
   }

   #PodSecurity: close(core.#ElementBase & {
       #elements: (#PodSecurityElement.#fullyQualifiedName): #PodSecurityElement
       podSecurity: schema.#PodSecuritySpec
   })

   // Re-export schema
   #PodSecuritySpec: schema.#PodSecuritySpec
   ```

3. **Add to `elements/elements.cue` registry**:

   ```cue
   import (
       security "github.com/open-platform-model/core/elements/security"
   )

   // Re-export element
   #PodSecurityElement: security.#PodSecurityElement
   #PodSecurity: security.#PodSecurity
   #PodSecuritySpec: security.#PodSecuritySpec

   // Add to registry
   #CoreElementRegistry: {
       (#PodSecurityElement.#fullyQualifiedName): #PodSecurityElement
   }
   ```

4. **Update transformer requirements** if creating a new primitive element that platforms need to support

#### Why Schema Package?

The separate `schema/` package prevents circular import dependencies:

- Element packages can safely import `schema` for type definitions
- Elements in different categories (e.g., `workload` and `data`) can reference each other's specs through the shared `schema` package
- No circular dependencies between element packages

### Lint and Type Checking

Run these commands after changes:

```bash
cue fmt ./...
cue vet ./...
```

## Available Commands (CUE CLI)

### Essential Commands

#### Formatting

```bash
# Format all CUE files in current directory and subdirectories
cue fmt ./...

# Format specific file
cue fmt provider.cue

# Check formatting without modifying files
cue fmt --check ./...

# Show diff of formatting changes
cue fmt --diff ./...
```

#### Validation

```bash
# Validate CUE files for syntax and type errors
cue vet ./...

# Validate specific file
cue vet module.cue

# Validate with specific value
cue vet -c '#Component' component.cue
```

#### Evaluation

```bash
# Evaluate and display CUE configuration
cue eval ./...

# Evaluate specific expression
cue eval -e '#Module' module.cue

# Output as JSON
cue export ./... --out json

# Output as YAML
cue export ./... --out yaml

# Pretty-print with syntax highlighting
cue export --out cue ./...
```

### Development Commands

#### Module Management

```bash
# Initialize a new CUE module
cue mod init opm.dev/core

# Download and sync dependencies
cue mod tidy

# Get a specific dependency
cue mod get github.com/example/package@v1.0.0
```

#### Code Generation

```bash
# Generate Go code from CUE definitions
cue gen ./...

# Generate OpenAPI from CUE schemas
cue export --out openapi ./...

# Generate JSON Schema
cue export --out jsonschema -e '#Component' ./...
```

#### Debugging

```bash
# Show computation trace for debugging
cue eval --trace ./...

# Show all available errors
cue vet --all-errors ./...

# Ignore errors and continue processing
cue eval --ignore ./...

# Verbose output
cue eval --verbose ./...
```

### Working with Definitions

#### Listing Definitions

```bash
# List all definitions in a package
cue def ./...

# Show specific definition
cue def '#Component' ./...

# Show definition with documentation
cue def --docs '#Provider' ./...
```

#### Trimming and Simplifying

```bash
# Remove redundant fields
cue trim ./...

# Simplify expressions
cue eval --simplify ./...

# Trim and format in one go
cue trim ./... && cue fmt ./...
```

### Import/Export Operations

#### Import from Other Formats

```bash
# Import JSON data
cue import data.json

# Import YAML with package name
cue import --package core data.yaml

# Import with specific path
cue import --path '#Component' component.json

# Import Proto definitions
cue import proto schema.proto
```

#### Export to Other Formats

```bash
# Export to JSON (compact)
cue export --out json ./...

# Export to YAML
cue export --out yaml ./...

# Export to Text
cue export --out text ./...

# Export specific value
cue export -e 'myApp' example.cue
```

### Useful Command Combinations

```bash
# Validate and format all files
cue vet ./... && cue fmt ./...

# Export module as JSON for external tools
cue export -e '#Module' --out json module.cue > module.json

# Check for issues and show detailed errors
cue vet --all-errors --verbose ./...

# Generate documentation
cue def --docs ./... > API.md

# Validate against schema
cue vet schema.cue data.yaml

# Merge multiple configurations
cue eval base.cue overlay.cue -o result.cue
```

### Project-Specific Commands

```bash
# Validate OPM module definition
cue vet . -e '#ModuleDefinition'

# Check component compatibility
cue eval . -e '#ComponentCapabilityProfile'

# Export rendered provider output
cue export . -e 'provider.render' --out yaml

# Validate all transformers
cue vet . -e 'transformers'

# Test transformer selection logic
cue eval . -e '#SelectTransformer'
```

## Code Style Guide (CUE Conventions)

### Naming Conventions

#### Definitions

- **Public Definitions**: Start with `#` and use PascalCase

  ```cue
  #Component: {...}
  #ElementBase: {...}
  ```

- **Private Definitions**: Start with `_#` and use PascalCase

  ```cue
  _#InternalHelper: {...}
  ```

#### Fields

- **Regular Fields**: Use camelCase for field names

  ```cue
  containerPort: 8080
  ```

- **Hidden Fields**: Start with `_` for package-private fields

  ```cue
  _registry: #ElementRegistry
  _component: #Component
  ```

- **Metadata Fields**: Start with `#` for structural metadata. Also for fields that are not supposed to be populated by users.

  ```cue
  #kind: "Provider"
  #apiVersion: "core.opm.dev/v1alpha1"
  ```

#### Constants and Types

- **Type Definitions**: Use PascalCase with `#` prefix

  ```cue
  #WorkloadTypes: "stateless" | "stateful" | "daemon"
  #ElementMap: [string]: #Elements
  ```

- **Constant Values**: Use SCREAMING_SNAKE_CASE with `#` prefix

  ```cue
  #IANA_SVC_NAME: string & =~"^[a-z]([-a-z0-9]{0,13}[a-z0-9])?$"
  ```

### File Organization

#### File Structure

```cue
package core

// File header comment block
/////////////////////////////////////////////////////////////////
//// Section Title
/////////////////////////////////////////////////////////////////

import (
    "list"
    "strings"
)

// Type definitions
#TypeName: {...}

// Constants
#CONSTANT_NAME: "value"

// Main definitions
#MainDefinition: {
    // Fields grouped by purpose
    // Metadata fields first
    #kind: string
    #apiVersion: string

    // Required fields
    name!: string

    // Optional fields
    description?: string

    // Computed fields
    computed: len(items)

    // Nested structures last
    nested: {
        ...
    }
}

// Helper definitions
#Helper: {...}

// Examples and instances at the end
exampleInstance: #MainDefinition & {
    ...
}
```

#### Import Organization

1. Standard library imports first
2. External package imports
3. Internal package imports
4. Blank line between groups

```cue
import (
    "list"
    "strings"

    "example.com/external"

    "opm.dev/internal"
)
```

### Formatting Rules

#### Indentation

- Use tabs for indentation (CUE standard)
- Align field values when it improves readability

```cue
#Component: {
    #kind:       "Component"        // Aligned
    #apiVersion: "core.opm.dev/v1"   // Aligned

    name:        string
    description: string
}
```

#### Comments

- **Section Headers**: Use comment blocks with forward slashes

  ```cue
  /////////////////////////////////////////////////////////////////
  //// Major Section
  /////////////////////////////////////////////////////////////////
  ```

- **Inline Documentation**: Use `//` above the definition

  ```cue
  // Provider interface for rendering modules
  #Provider: {...}
  ```

- **Field Comments**: Place after the field on the same line

  ```cue
  workloadTypes?: [...#WorkloadTypes] // e.g. ["stateless", "stateful"]
  ```

#### Constraints and Validation

- Place constraints on the same line when simple

  ```cue
  port: uint & >=1 & <=65535
  ```

- Use multiline for complex constraints

  ```cue
  name: string
  name: strings.MinRunes(1)
  name: strings.MaxRunes(63)
  name: =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
  ```

### Best Practices

#### Use of close()

- Use `close()` to prevent field additions in definitions

  ```cue
  #Element: close({
    type: #ElementTypes
    #kind: #ElementKinds
  })
  ```

#### Required vs Optional

- Use `!` for required fields in definitions

  ```cue
  name!: string
  ```

- Use `?` for optional fields

  ```cue
  description?: string
  ```

#### Default Values

- Use `*` for defaults in disjunctions

  ```cue
  replicas: uint | *1
  protocol: "TCP" | "UDP" | *"TCP"
  ```

#### Comprehensions

- Use comprehensions for transformations

  ```cue
  unifiedLabels: {
    for k, v in labels {
      "\(k)": "\(v)"  // String interpolation
    }
  }
  ```

#### Guard Clauses

- Use if statements for conditional fields

  ```cue
  if type == "workload" {
    workloadType!: #WorkloadTypes
  }
  ```

### Testing Conventions

- Test files should be named `*_test.cue`
- Use descriptive test names

  ```cue
  test_component_with_container: #Component & {
    #metadata: name: "test"
    #Container
  }
  ```

### Module Organization

```shell
core/
├── element.cue                              # Base element definitions
├── component.cue                            # Component definitions
├── module.cue                               # Module definitions
├── provider.cue                             # Provider interface
├── registry.cue                             # Element registry
├── schema/                                  # Schema definitions (shared specs)
│   ├── workload.cue                         # Workload specs (ContainerSpec, ReplicasSpec, etc.)
│   ├── data.cue                             # Data specs (VolumeSpec, ConfigMapSpec, etc.)
│   └── connectivity.cue                     # Connectivity specs (ExposeSpec, NetworkScopeSpec)
├── elements/                                # Element catalog (organized by category)
│   ├── elements.cue                         # Index & registry (main entry point)
│   ├── workload/                            # Workload elements
│   │   ├── primitive_traits.cue             # Container
│   │   ├── modifier_traits.cue              # Replicas, RestartPolicy, UpdateStrategy, HealthCheck
│   │   └── composite_traits.cue             # StatelessWorkload, StatefulWorkload, etc.
│   ├── data/                                # Data elements
│   │   ├── primitive_resources.cue          # Volume, ConfigMap, Secret
│   │   └── composite_traits.cue             # SimpleDatabase
│   └── connectivity/                        # Connectivity elements
│       ├── primitive_traits.cue             # NetworkScope
│       └── modifier_traits.cue              # Expose
└── examples/                                # Usage examples
    └── example_module.cue
```

**Important Imports:**

```cue
// For using elements
import elements "github.com/open-platform-model/core/elements"

// For using schema types directly
import schema "github.com/open-platform-model/core/schema"

// For element development (imports both schema and core)
import (
    core "github.com/open-platform-model/core"
    schema "github.com/open-platform-model/core/schema"
)
```

The elements package provides access to all element definitions through a single import.

## OSCAL Integration Insights

### Overview

OSCAL (Open Security Controls Assessment Language) is a NIST framework for security compliance that uses a layered architecture similar to OPM. Understanding OSCAL helps inform OPM's design, particularly for assessment and selection patterns.

### OSCAL Architecture

#### Three-Layer Stack

1. **Control Layer** (Base)
   - Catalog Model: Machine-readable security controls
   - Profile Model: Selects and tailors controls from catalogs

2. **Implementation Layer** (Middle)
   - Component Definition: Describes how components satisfy controls
   - System Security Plan (SSP): Documents system implementation

3. **Assessment Layer** (Top)
   - Assessment Plan: Defines assessment methodology
   - Assessment Results: Captures findings and evidence
   - Plan of Action & Milestones (POA&M): Tracks remediation

### Relevance to OPM

#### Parallel Architecture

- OSCAL: Control → Implementation → Assessment
- OPM: Elements → Components → Modules → Providers
- Both use progressive refinement and layered composition

#### Component Model Similarities

- **OSCAL Component Definition**:
  - Declares which controls a component satisfies
  - Provides configuration options
  - Documents compliance capabilities
- **OPM Components**:
  - Collections of elements
  - Declare workload types and capabilities
  - Could adopt similar capability declaration patterns

#### Assessment Pattern Application

The OPM `#SelectTransformer` pattern aligns with OSCAL's assessment approach:

- OSCAL evaluates control compliance with scoring
- OPM evaluates transformer compatibility with scoring
- Both use structured assessment to select best matches

#### Key Patterns to Adopt

1. **Capability Declaration**
   - Components explicitly declare what they provide/satisfy
   - Enables automated matching and selection

2. **Profile/Baseline Concept**
   - OSCAL profiles select and tailor from catalogs
   - OPM transformers could use similar selection patterns

3. **Structured Assessment**
   - Scoring mechanisms for compatibility
   - Evidence-based selection
   - Clear traceability of decisions

4. **Identifier Management**
   - UUIDs for global uniqueness
   - Scoped identifiers for local references
   - Consistent cross-model referencing

### Implementation Considerations

- Use assessment patterns for transformer selection scoring
- Consider capability-based component declarations
- Implement structured evidence for transformer selection
- Maintain clear traceability from elements to rendered output

## Open Questions/TODOs

- How to handle transformer resolution. Resolving which transformer to use for each
- Validation and error reporting for missing transformers
- Implement OSCAL-inspired capability declarations for components
- Design assessment scoring algorithm for transformer selection
