# Open Platform Model (OPM) - Architecture Guide for Claude

## Project Overview

Open Platform Model (OPM) is a CUE-based framework for defining platform-agnostic application models that can be rendered to different target platforms (Kubernetes, Docker, etc.) through providers and transformers.

## Date

Year: 2025

## Core Architecture

### Layered Model Structure

```shell
Elements (primitives) → Components (collections) → ModuleDefinitions (blueprints) → Modules (deployments) → Renderers (output)
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
- Workload type is derived from element `"core.opm.dev/workload-type"` label: stateless | stateful | daemon | task | scheduled-task | function
- Element labels are automatically merged into `#metadata.labels`
- Contains `#primitiveElements` (recursively extracted from all elements)
- CUE unification validates that element labels don't conflict

#### Transformers

- Convert OPM components to platform-specific resources
- Key fields:
  - `creates`: what native resource it produces
  - `required`: list of required element names
  - `optional`: list of optional element names
  - `transform`: function that does the conversion
- Providers can filter components based on element annotations (e.g., workload-type)

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

### Module Architecture

#### Two-Concept System

OPM uses a two-concept module system:

1. **#ModuleDefinition** - Application blueprint
   - Created by developers
   - Contains components and value schema (constraints only)
   - Platform-agnostic and portable
   - NO transformers or renderers attached

2. **#Module** - Deployment instance
   - References a `#ModuleDefinition`
   - Attaches `#transformers` (selected from providers)
   - Attaches `#renderer` (selected from catalog)
   - Provides concrete values
   - Embedded rendering logic generates output

#### Key Structure

```cue
#ModuleDefinition: {
    #metadata: {...}
    components: [string]: #Component
    values: {...}  // Constraints only, NO defaults
}

#Module: {
    #metadata: {...}
    #moduleDefinition!: #ModuleDefinition  // Reference to blueprint

    // Explicit transformer-to-component mapping
    #transformersToComponents!: [string]: {
        transformer: #Transformer
        components: [...string]  // Component IDs
    }

    #renderer!: #Renderer  // Selected renderer
    values: #moduleDefinition.values & {...}  // Concrete values

    output: {
        manifest?: _   // Single manifest output
        files?: [string]: _  // Multi-file output
        metadata?: {   // Rendering metadata
            format: string
            entrypoint?: string
        }
    }
}
```

#### Catalog Structure

```cue
#PlatformCatalog: {
    providers!: #ProviderMap          // Available transformers by provider
    renderers!: #RendererMap          // Available renderers
    moduleDefinitions: [string]: #ModuleDefinition  // Bare definitions (no transformers)
}
```

#### Workflow

1. **Developer**: Creates `#ModuleDefinition` with components and value constraints
2. **Platform Team**: Adds definition to catalog's `moduleDefinitions`
3. **End User**: Creates `#Module` instance
   - References definition from catalog
   - Selects transformers from catalog's providers
   - Selects renderer from catalog's renderers
   - Provides concrete values
   - Output automatically generated

#### Developer Testing Flow

Developers can test locally before submitting to platform:

```cue
// 1. Create definition
myAppDef: #ModuleDefinition & {
    components: {
        web: #StatelessWorkload & {...}
    }
    values: {
        image!: string
    }
}

// 2. Test locally with mock transformers
myAppTest: #Module & {
    #moduleDefinition: myAppDef
    #transformersToComponents: {
        "k8s.io/api/apps/v1.Deployment": {
            transformer: mockTransformer
            components: ["web"]  // Component IDs to transform
        }
    }
    #renderer: #KubernetesListRenderer
    values: {
        image: "test:latest"
    }
}
```

See [examples/developer](examples/developer) for complete examples.

## OPM CLI

### Overview

The OPM CLI (`opm`) is a Go-based command-line tool that handles runtime operations for OPM modules. It separates runtime computation (Go) from schema definition and validation (CUE).

### Architecture

**Division of Responsibilities:**

- **CUE**: Schema definitions, type checking, validation
- **CLI Runtime**: Primitive resolution, transformer matching, execution, rendering

### Installation

```bash
cd opm-cli
go build -o opm ./cmd/opm
```

### Environment Variables

- `OPM_ELEMENT_REGISTRY_PATH` - **Required**. Package path containing element registry (e.g., `/path/to/core/elements/core`)
- `OPM_ELEMENT_REGISTRY_DEFINITION` - **Optional**. Definition name to load (default: `#ElementRegistry`)

### Usage

#### Basic Building

```bash
export OPM_ELEMENT_REGISTRY_PATH=/path/to/core/elements/core
opm module build path/to/module.cue --output ./output
# or using alias
opm mod build path/to/module.cue --output ./output
```

#### With Verbose Output

```bash
opm mod build module.cue --output ./k8s --verbose
```

Output shows each step with inline timing:

- 📦 Loading Module (with module details and ⏱️ timing)
- 📚 Loading Element Registry (shows 💾 Cache or 📁 Package source with ⏱️ timing)
- 🔍 Analyzing Components (with workload types, primitive counts, and ⏱️ timing)
- 🔗 Matching Transformers (shows which transformers match which components with ⏱️ timing)
- ⚙️ Executing Transformers (with individual execution times and total ⏱️ timing)
- 📄 Rendering Output (with resource count, size, and ⏱️ timing)
- ⏱️ Total time at the end

#### With Timing Report

```bash
opm mod build module.cue --output ./k8s --timings
```

Shows detailed performance breakdown table:

- Main steps with durations and percentages
- Individual transformer execution times with percentages
- Total execution time

#### Combined Verbose + Timings

```bash
opm mod build module.cue --output ./k8s --verbose --timings
```

Shows both inline timings during execution and final timing report table

### Module File Format

Modules must declare `opm.#Module` at the package level:

```cue
package myapp

import (
    opm "github.com/open-platform-model/core"
    common "github.com/open-platform-model/core/examples/common"
)

opm.#Module

#metadata: {
    name:      "my-app"
    namespace: "production"
}

#module: opm.#CatalogModule & {
    moduleDefinition: myAppDefinition
    renderer:         common.#KubernetesListRenderer
    provider:         common.#KubernetesProvider
}

values: {
    frontend: {
        image: "myapp:v1.0.0"
    }
}
```

### CLI Workflow

When you run `opm module build` (or `opm mod build`), the CLI:

1. **Loads the Module** from the specified file
2. **Loads the Element Registry** from `$OPM_ELEMENT_REGISTRY_PATH`
3. **Analyzes Components** - Resolves all primitive elements for each component
4. **Matches Transformers** - Automatically selects transformers from the provider based on:
   - Component labels matching **ALL** transformer labels
   - Component primitives matching transformer required primitives
5. **Executes Transformers** - Generates platform resources in parallel
6. **Executes Renderer** - Aggregates resources into final output format
7. **Writes Output** - Saves the rendered manifest

### Transformer Matching Algorithm

Transformers declare their requirements:

```cue
#DeploymentTransformer: opm.#Transformer & {
    #metadata: {
        labels: {
            "core.opm.dev/workload-type": "stateless"
        }
    }
    required: ["elements.opm.dev/core/v0.Container"]
    optional: ["elements.opm.dev/core/v0.Replicas", ...]
}
```

The CLI matches transformers to components when:

1. **ALL** transformer labels match component labels (exact key-value match)
2. **ALL** required primitives are present in the component

### Performance Optimizations

The CLI includes several performance optimizations:

- **Automatic Registry Caching**: Element registries are cached in `~/.opm/cache/` with automatic invalidation
  - Without cache: ~2.4s registry load time
  - With cache: ~0.5ms registry load time (**4,900x faster**)
  - Overall speedup: ~37% faster total execution
  - Cache automatically invalidates when source files change
- **Parallel Transformer Execution**: Independent transformers run concurrently (36% speedup)
- **CUE Context Reuse**: Single CUE context shared across operations
- **Efficient Component Analysis**: Fast primitive resolution (<100µs)

Typical performance (with cache):

- Load Module: ~1.9s (35%)
- Load Registry: ~0.5ms (0%) - **cached**
- Analyze Components: <1ms (0%)
- Match Transformers: <1ms (0%)
- Execute Transformers: ~3.6s (65%) - runs in parallel
- Execute Renderer: ~1ms (0%)
- **Total: ~5.6 seconds** for typical modules (vs ~8.9s without cache)

To clear the cache: `opm elements cache clear`

### Flags

- `-o, --output <dir>` - Output directory (default: `./output`)
- `-f, --format <format>` - Output format: `yaml` or `json` (default: `yaml`)
- `-v, --verbose` - Show detailed matching information with inline timing for each step
- `-t, --timings` - Show detailed timing report table at the end
- Combine `-v` and `-t` for both inline timings and final report

### Troubleshooting

**Error: OPM_ELEMENT_REGISTRY_PATH environment variable is not set**

Set the environment variable to point to the package directory:

```bash
export OPM_ELEMENT_REGISTRY_PATH=/path/to/core/elements/core
```

**Error: file must declare 'opm.#Module' at package level**

Your module file must have `opm.#Module` declared at the top level (not inside a named field).

**Error: no matching transformer found for component**

The component's labels or primitives don't match any transformer requirements. Use `--verbose` to see detailed matching information.

### Architecture Details

**Key Packages:**

- `cmd/opm` - CLI commands (render)
- `pkg/loader` - CUE file loading (modules, providers, registries)
- `pkg/registry` - Element registry management and primitive resolution
- `pkg/component` - Component analysis
- `pkg/transformer` - Transformer matching, selection, and execution
- `pkg/renderer` - Renderer execution

**Design Decisions:**

- No embedded registry - loads from `$OPM_ELEMENT_REGISTRY_PATH`
- Package-level Module declaration (not named fields)
- Automatic transformer matching (no manual `transformersToComponents`)
- Parallel execution for performance
- Clean separation between CUE (schema) and Go (runtime)

## Recent Changes

### 2025-10-25

1. **OPM CLI Implementation**: Complete Go-based CLI for rendering OPM modules
   - Removed `transformersToComponents` from CUE schemas - now computed at runtime
   - Changed to single `--module` parameter (removed `--catalog` and `--definition`)
   - Automatic transformer matching based on labels and primitives
   - Parallel transformer execution (36% performance improvement)
   - `--verbose` flag for clean, structured output with emojis and inline timings
   - `--timings` flag for detailed performance analysis table
   - Environment variable: `OPM_ELEMENT_REGISTRY_PATH` points to package directory
   - Module files must declare `opm.#Module` at package level
   - Provider contains transformers, CLI automatically matches to components
   - Updated all examples to new architecture

2. **Element Registry Caching**: Automatic file-based caching for performance
   - Caches parsed element registries in `~/.opm/cache/`
   - 4,900x faster registry loading (2.4s → 0.5ms)
   - 37% faster overall execution time (8.9s → 5.6s)
   - Automatic cache invalidation based on file modification time and size
   - New command: `opm elements cache clear` to manually clear cache
   - Verbose output shows cache status (💾 Cache vs 📁 Package)

3. **CLI Command Restructuring**: Timoni-style command organization
   - Moved `render` to `module build` (alias: `mod build`) - renamed to match industry standard
   - Moved `cache` to `elements cache`
   - Removed `validate` and `analyze` commands (not yet implemented)
   - Removed all catalog-related CLI operations (catalog is a CUE concept, not CLI)
   - Implemented `elements list` and `elements resolve` commands
   - Commands: `opm module`, `opm elements`
   - Example: `opm mod build module.cue --output ./k8s --verbose`

### 2025-10-23

1. **#transformersToComponents Architecture**: Replaced `#transformers` with explicit transformer-to-component mapping
   - Module now uses `#transformersToComponents` with explicit `{transformer, components}` structure
   - Enables expression-based component selection using component labels and primitives
   - Users can reference `#moduleDefinition.components` and `transformer.#metadata.labels` in expressions
   - Simplified Module rendering logic from ~60 lines to ~20 lines
   - Transformer-first iteration pattern for better performance
   - Documented CUE iteration limitation workaround (see BUG_CUE_ITERATION.md)

2. **Removed #metadata.workloadType computed field**: Workload type now accessed via labels only
   - Changed from `comp.#metadata.workloadType` to `comp.#metadata.labels["core.opm.dev/workload-type"]`
   - Element labels automatically merged into component `#metadata.labels`
   - Updated all element references (RestartPolicy, UpdateStrategy, developer tools, unit tests)
   - Automatic conflict detection via CUE unification when element labels conflict
   - Cleaner separation: labels for categorization, annotations for hints

### 2025-10-21

1. **Documentation Update**: Updated CLAUDE.md to accurately reflect current implementation
   - Documented two-concept system (#ModuleDefinition + #Module)
   - Clarified that transformers/renderers attach at Module instantiation, not pre-baked in catalog
   - Added developer testing workflow
   - Updated output structure (manifest/files/metadata)

### 2025-10-01

1. **Element File Reorganization**: Changed from type-aggregated to kind-prefixed file naming
   - Replaced `primitive_traits.cue`, `modifier_traits.cue`, `composite_traits.cue` with individual files
   - New naming: `{kind}_{element_name}.cue` (e.g., `primitive_container.cue`, `modifier_replicas.cue`)
   - Removed re-exports from `elements/elements.cue` - now registry only
   - Elements accessed through category packages (workload, data, connectivity)
   - Makes element kind immediately visible in file listings

### 2025-09-30

1. **Major Reorganization**: Restructured elements into category-based hierarchy
   - Created `schema/` package for all spec definitions
   - Organized elements into `workload/`, `data/`, and `connectivity/` subdirectories
   - Resolved circular import dependencies between element categories
   - All schema types now in separate package to enable cross-category references

### 2025-10-02

1. **Replaced workloadType with annotations**: Elements now use `annotations?: [string]: string` map (like Kubernetes annotations) instead of `workloadType` field
   - Workload type is now specified via `"core.opm.dev/workload-type"` annotation
   - Components derive workloadType from element annotations
   - Validation ensures only one workload-type annotation value per component
   - Providers can interpret annotations for decision-making (e.g., transformer selection)
   - Separation: `labels` for categorization/filtering (OPM-level), `annotations` for behavior hints (provider-level)

### 2025-09-29

1. Added #status inheritance in #Module from moduleDefinition
2. Exploring OSCAL-inspired assessment patterns for transformer selection

## Development Guidelines

### Testing Transformers

- Always verify required elements are satisfied
- Test with mixed workload/resource components
- Validate optional element handling

### Adding New Elements

**IMPORTANT:** All new elements MUST be added to the `elements/elements.cue` index file to be accessible when importing the elements package.

#### Element Organization

Elements are organized in a flat directory structure with schemas co-located:

- **Categories**: `workload` | `data` | `connectivity` | (future: `security` | `observability` | `governance`)
- **File Naming**: `{category}_{kind}_{element_name}.cue`
  - `workload_primitive_*.cue` - Workload primitives with schemas
  - `workload_modifier_*.cue` - Workload modifiers with schemas
  - `workload_composite_*.cue` - Workload composites with schemas
  - `data_primitive_*.cue`, `data_composite_*.cue` - Data elements with schemas
  - `connectivity_primitive_*.cue`, `connectivity_modifier_*.cue` - Connectivity elements with schemas
- **Schema Location**: All `*Spec` definitions are in the same file as the element (no separate schema package)
- **Package**: All core elements are in `package core`

#### Steps to Add a New Element

1. **Create the element file** in `elements/core/{category}_{kind}_{name}.cue`:

   ```cue
   // In elements/core/security_primitive_pod_security.cue
   package core

   import (
       opm "github.com/open-platform-model/core"
   )

   /////////////////////////////////////////////////////////////////
   //// Pod Security Schema
   /////////////////////////////////////////////////////////////////

   #PodSecuritySpec: {
       runAsNonRoot?: bool | *true
       readOnlyRootFilesystem?: bool | *false
   }

   /////////////////////////////////////////////////////////////////
   //// Pod Security Element
   /////////////////////////////////////////////////////////////////

   #PodSecurityElement: opm.#Primitive & {
       name: "PodSecurity"
       #apiVersion: "elements.opm.dev/core/v0"
       target: ["component"]
       schema: #PodSecuritySpec
       labels: {"core.opm.dev/category": "security"}
   }

   #PodSecurity: close(opm.#Component & {
       #elements: (#PodSecurityElement.#fullyQualifiedName): #PodSecurityElement
       podSecurity: #PodSecuritySpec
   })
   ```

2. **Add to `elements/elements.cue` registry**:

   ```cue
   // In elements/elements.cue
   import (
       core "github.com/open-platform-model/core/elements/core"
   )

   #CoreElementRegistry: {
       // ... existing elements

       // Security elements
       (opm.#PodSecurityElement.#fullyQualifiedName): opm.#PodSecurityElement
   }
   ```

3. **Update transformer requirements** if creating a new primitive element that platforms need to support

#### Why Co-located Schemas?

Schemas are defined in the same file as elements for simplicity:

- No separate package imports needed - elements and schemas share the same `package core`
- Elements can directly reference their schemas (e.g., `schema: #PodSecuritySpec`)
- All elements can reference each other's schemas since they're in the same package
- Simpler file structure - one file contains everything related to an element

### Lint and Type Checking

Run these commands after changes:

```bash
cue fmt ./...
cue vet ./...
```

## Git Workflow (Core Repository)

**Note**: See root [CLAUDE.md](../CLAUDE.md#git-workflow) for general git guidelines.

**Core-specific workflow**:

```bash
# Always work from core directory
cd ./open-platform-model/core

# Common commit scopes for core:
git commit -m "feat(elements): ..."      # Element definitions
git commit -m "refactor(schema): ..."    # Schema changes
git commit -m "feat(provider): ..."      # Provider/transformer work
git commit -m "feat(component): ..."     # Component model changes
git commit -m "feat(module): ..."        # Module definitions
git commit -m "docs(claude): ..."        # CLAUDE.md updates
git commit -m "test(examples): ..."      # Example modules
```

## Versioning

**Core follows [Semantic Versioning v2.0.0](https://semver.org).**

See the root [CLAUDE.md](../CLAUDE.md#versioning) for complete Semver v2 specification.

### Core-Specific Version Guidelines

**Element `#apiVersion` Field:**
- Currently using `v0alpha1` format in elements
- Migrating to `v0` format for initial development phase
- Will move to `v1` when element schemas are stable

**When to Bump Core Version:**

**MAJOR (x.0.0):**
- Breaking changes to `#Element`, `#Component`, or `#Module` base types
- Incompatible changes to element composition patterns
- Provider interface breaking changes

**MINOR (0.x.0):**
- New core element types added
- New optional fields in base types
- New element categories or kinds
- Deprecation notices (but not removals)

**PATCH (0.0.x):**
- Bug fixes in element validation
- Documentation improvements
- Schema clarifications without behavioral changes

### Module Versioning Best Practices

When creating `#ModuleDefinition` instances:

```cue
#ModuleDefinition: {
    #metadata: {
        name:    "my-app"
        version: "1.2.3"  // Follow Semver v2
    }
    // ...
}
```

**Module version bumping:**
- MAJOR: Breaking changes to component interfaces or required values
- MINOR: New components added, new optional configuration
- PATCH: Bug fixes, documentation updates

### Git Tags

Tag releases following Semver v2 with `v` prefix:

```bash
# Create version tag
git tag -a v0.5.0 -m "Release v0.5.0"
git push origin v0.5.0

# Pre-release tags
git tag -a v1.0.0-beta.1 -m "Beta release v1.0.0-beta.1"
git push origin v1.0.0-beta.1
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
  #Element: {...}
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
  #apiVersion: "core.opm.dev/v0"
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
    #apiVersion: "core.opm.dev/v0"   // Aligned

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
├── elements/                                # Element catalog (flattened structure)
│   ├── elements.cue                         # Main registry (imports from core and kubernetes)
│   ├── core/                                # OPM core elements (all in flat structure)
│   │   ├── workload_primitive_container.cue       # Container + schemas
│   │   ├── workload_modifier_sidecars.cue         # Sidecar/Init/Ephemeral containers
│   │   ├── workload_modifier_replicas.cue         # Replicas + schema
│   │   ├── workload_modifier_restart_policy.cue   # RestartPolicy + schema
│   │   ├── workload_modifier_update_strategy.cue  # UpdateStrategy + schema
│   │   ├── workload_modifier_health_check.cue     # HealthCheck + schemas
│   │   ├── workload_composite_stateless.cue       # StatelessWorkload + schema
│   │   ├── workload_composite_stateful.cue        # StatefulWorkload + schema
│   │   ├── workload_composite_daemonset.cue       # DaemonWorkload + schema
│   │   ├── workload_composite_task.cue            # TaskWorkload + schema
│   │   ├── workload_composite_scheduled_task.cue  # ScheduledTask + schema
│   │   ├── data_primitive_volume.cue              # Volume + schemas
│   │   ├── data_primitive_configmap.cue           # ConfigMap + schema
│   │   ├── data_primitive_secret.cue              # Secret + schema
│   │   ├── data_composite_simple_database.cue     # SimpleDatabase + schema
│   │   ├── connectivity_primitive_network_scope.cue  # NetworkScope + schema
│   │   └── connectivity_modifier_expose.cue       # Expose + schemas
│   └── kubernetes/                          # Kubernetes native resources
│       ├── kubernetes_schema.cue            # All K8s resource schemas
│       ├── primitive_core.cue               # Core API resources
│       ├── primitive_apps.cue               # Apps API resources
│       ├── primitive_batch.cue              # Batch API resources
│       ├── primitive_networking.cue         # Networking API resources
│       ├── primitive_storage.cue            # Storage API resources
│       ├── primitive_rbac.cue               # RBAC API resources
│       └── primitive_other.cue              # Other API groups
└── examples/                                # Usage examples
    ├── example_module.cue
    └── example_provider.cue
```

**File Naming Convention**: `{category}_{kind}_{element_name}.cue`

- `workload_primitive_*.cue` - Workload primitives with schemas
- `workload_modifier_*.cue` - Workload modifiers with schemas
- `workload_composite_*.cue` - Workload composites with schemas
- `data_primitive_*.cue` - Data primitives with schemas
- `data_composite_*.cue` - Data composites with schemas
- `connectivity_primitive_*.cue` - Connectivity primitives with schemas
- `connectivity_modifier_*.cue` - Connectivity modifiers with schemas

**Key Design**: Schemas are co-located with element definitions in the same file and package.

**Important Imports:**

```cue
// For using elements - import core elements package
import elements "github.com/open-platform-model/core/elements/core"

// For element development
import (
    opm "github.com/open-platform-model/core"
)
```

Elements and their schemas are accessed through the core elements package.
No separate schema package - all schemas are defined alongside their elements.

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
