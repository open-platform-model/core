# OPM Core Framework

> **CUE-based type system and architectural foundation for the Open Platform Model**

The core framework defines OPM's fundamental abstractions: elements, components, modules, scopes, and providers. This is where the type system, composition patterns, and architectural contracts live.

## Repository Purpose

This repository contains:

- **Type Definitions**: Core CUE definitions for elements, components, modules, and scopes
- **Element System**: Base element types (primitive, modifier, composite, custom)
- **Component Model**: Component composition and validation logic
- **Module Architecture**: Three-layer model (ModuleDefinition → Module → ModuleRelease)
- **Provider Interface**: Platform provider contract and transformer system
- **Schema Definitions**: Shared spec definitions for workload, data, and connectivity
- **Core Elements**: Official element catalog (workload, data, connectivity)

**Target Audience**: Core contributors, element authors, provider implementers, and anyone extending OPM's capabilities.

## Quick Start

Validate and format the core definitions:

```bash
# Format all CUE files
cue fmt ./...

# Validate all definitions
cue vet ./...

# Export example module to verify it works
cue export ./examples/example_module.cue -e myAppDefinition --out json
```

## Repository Structure

```shell
core/
├── element.cue           # Base element type system (#Element, #Primitive, etc.)
├── component.cue         # Component definition and composition
├── module.cue            # Module, ModuleDefinition, ModuleRelease
├── scope.cue             # Scope definitions (Platform & Module scopes)
├── provider.cue          # Provider interface and transformer system
├── registry.cue          # Element registry interface
├── common.cue            # Shared types (labels, annotations, etc.)
├── elements/             # Core element catalog
│   ├── elements.cue      # Element registry and index (MAIN ENTRY POINT)
│   ├── core/             # OPM core elements (flat structure, co-located schemas)
│   │   ├── workload_primitive_*.cue   # Container primitives with schemas
│   │   ├── workload_modifier_*.cue    # Replicas, HealthCheck, etc.
│   │   ├── workload_composite_*.cue   # StatelessWorkload, StatefulWorkload
│   │   ├── data_primitive_*.cue       # Volume, ConfigMap, Secret with schemas
│   │   ├── data_composite_*.cue       # SimpleDatabase
│   │   ├── connectivity_primitive_*.cue  # NetworkScope with schemas
│   │   └── connectivity_modifier_*.cue   # Expose
│   └── kubernetes/       # Kubernetes native resource primitives
│       ├── kubernetes_schema.cue      # All K8s resource schemas
│       └── primitive_*.cue            # K8s resource elements
├── examples/             # Example modules and usage patterns
├── docs/                 # Architecture documentation
├── proposals/            # Design proposals and experiments
└── cue.mod/              # CUE module definition
```

## Core Concepts

**Quick reference** - See [docs/](docs/) for detailed architecture:

- **[Elements](docs/architecture/element.md)**: Building blocks with kind (primitive/composite/modifier/custom) categorized by labels
- **Components**: Element compositions representing workloads or resources
- **Modules**: Complete application definitions with components and scopes
- **Scopes**: Cross-cutting concerns (PlatformScopes are immutable, ModuleScopes are mutable)
- **Providers**: The Provider Interface
- **Transformer**: Platform-specific transformers that convert OPM to native resources
- **Catalog**: The PlatformCatalog architecture

**Key Innovation**: Everything is an element. Primitives compose into composites, modifiers enhance them, all unified under a common base.

## Development Workflow

### Common CUE Commands

```bash
# Format code (always run before committing)
cue fmt ./...

# Validate all definitions
cue vet ./...

# Show all errors at once
cue vet --all-errors ./...

# Export as JSON (useful for debugging)
cue export ./... --out json

# Export specific definition
cue export -e '#ModuleDefinition' module.cue --out json

# Evaluate specific value
cue eval . -e '#Component'

# Test example module
cue export ./examples/example_module.cue -e myAppDefinition --out json
```

### Working with Elements

```bash
# View all registered elements
cue export ./elements/elements.cue -e '#CoreElementRegistry' --out json

# Test a specific element
cue eval ./elements/core/workload_primitive_container.cue -e '#Container'

# Validate all core elements
cue vet ./elements/core/
```

### Development Loop

1. Make changes to `.cue` files
2. Run `cue fmt ./...` to format
3. Run `cue vet ./...` to validate
4. Test with `cue export` on examples
5. Commit when validation passes

## Key Files Explained

| File | Purpose |
|------|---------|
| [element.cue](element.cue) | Base element type system. Defines `#Element`, `#Primitive`, `#Composite`, `#Modifier`, `#Custom` and element kinds. |
| [component.cue](component.cue) | Component definition. Components are element compositions with workloadType derived from element annotations. |
| [module.cue](module.cue) | Three-layer module architecture: `#ModuleDefinition` (developer), `#Module` (platform), `#ModuleRelease` (user). |
| [scope.cue](scope.cue) | Scope system for cross-cutting concerns. `#PlatformScope` (immutable) vs `#ModuleScope` (mutable). |
| [provider.cue](provider.cue) | Provider interface, transformer definitions, and selection logic for platform-specific rendering. |
| [registry.cue](registry.cue) | Element registry interface for element lookup and resolution. |
| [common.cue](common.cue) | Shared types like labels, annotations, and common patterns. |

### Elements Package Structure

Elements are organized in a flat structure with co-located schemas:

- **[elements/core/](elements/core/)**: OPM core elements (flat structure, unified `package core`)
  - File naming: `{category}_{kind}_{name}.cue` (e.g., `workload_primitive_container.cue`)
  - `workload_primitive_*.cue`: Container and workload primitives with schemas
  - `workload_modifier_*.cue`: Replicas, HealthCheck, RestartPolicy, etc. with schemas
  - `workload_composite_*.cue`: StatelessWorkload, StatefulWorkload, etc. with schemas
  - `data_primitive_*.cue`: Volume, ConfigMap, Secret with schemas
  - `data_composite_*.cue`: SimpleDatabase with schemas
  - `connectivity_primitive_*.cue`: NetworkScope with schemas
  - `connectivity_modifier_*.cue`: Expose with schemas

- **[elements/kubernetes/](elements/kubernetes/)**: Kubernetes native resource primitives (separate `package kubernetes`)
  - `kubernetes_schema.cue`: All Kubernetes resource schemas
  - `primitive_*.cue`: Kubernetes resource element definitions

**Pattern**: Each element file contains both the element definition AND its schema definitions. All core elements use `package core` for unified imports.

### Elements Catalog

The `elements/` directory contains the official element catalog:

- **[elements/elements.cue](elements/elements.cue)**: **MAIN ENTRY POINT** - Element registry and index
- **[elements/core/](elements/core/)**: OPM core elements (user-facing abstractions) - all in flat structure
  - `workload_primitive_container.cue`, `workload_modifier_*.cue`, `workload_composite_*.cue`
  - `data_primitive_*.cue`, `data_composite_*.cue`
  - `connectivity_primitive_*.cue`, `connectivity_modifier_*.cue`
- **[elements/kubernetes/](elements/kubernetes/)**: Kubernetes native resources (platform-specific primitives)
  - `kubernetes_schema.cue` - All K8s resource schemas
  - `primitive_*.cue` - K8s resource element definitions

**Import pattern**: `import elements "github.com/open-platform-model/core/elements/core"`

**Critical**: All new elements MUST be added to `elements/elements.cue` registry to be accessible.

## Testing & Validation

### Validate Core Definitions

```bash
# Validate all core files
cue vet ./...

# Validate specific package
cue vet ./elements/...

# Check for type errors
cue vet --all-errors ./...
```

### Test Element Registry

```bash
# Verify all elements are registered
cue export ./elements/elements.cue -e '#CoreElementRegistry' --out json

# Check element count
cue export ./elements/elements.cue -e '#CoreElementRegistry' --out json | jq 'length'
```

### Test Examples

```bash
# Export example module
cue export ./examples/example_module.cue -e myAppDefinition --out json

# Validate example against module schema
cue vet ./examples/example_module.cue ./module.cue

# Test provider example
cue export ./examples/example_provider.cue --out json
```

### Debug Performance Issues

If CUE evaluation is slow:

```bash
# Export to find unresolved values (bottoms)
cue export ./... --out json 2>&1 | grep "cannot"

# Check specific definition for bottoms
cue export -e '#Component' component.cue --out json
```

## Adding New Elements

**Step 1**: Create element file in `elements/core/{category}_{kind}_{name}.cue`

```cue
package core

import (
    opm "github.com/open-platform-model/core"
)

// Define schema in same file
#MyFeatureSpec: {
    enabled?: bool | *true
    config?: string
}

// Define element
#MyFeatureElement: opm.#Primitive & {
    name: "MyFeature"
    schema: #MyFeatureSpec
    target: ["component"]
    labels: {"core.opm.dev/category": "workload"}
    annotations?: {
        // Optional behavior hints for providers
        ...
    }
}

// Usage pattern
#MyFeature: opm.#ElementBase & {
    #elements: MyFeature: #MyFeatureElement
    myFeature: #MyFeatureSpec
}
```

**Step 2**: Register in `elements/elements.cue`

```cue
import core "github.com/open-platform-model/core/elements/core"

#MyFeature: opm.#MyFeature
#MyFeatureElement: opm.#MyFeatureElement

#CoreElementRegistry: {
    (#MyFeatureElement.#fullyQualifiedName): #MyFeatureElement
}
```

**Step 3**: Validate

```bash
cue vet ./...
cue export ./elements/elements.cue -e '#CoreElementRegistry' --out json | jq 'keys'
```

See [docs/element-development.md](docs/element-development.md) for detailed guide.

## Contributing

Contributions are welcome! Before contributing:

1. Read the [Architecture Documentation](docs/)
2. Check [TODO.md](TODO.md) for planned work
3. Review [proposals/](proposals/) for design discussions
4. Follow CUE formatting: `cue fmt ./...`
5. Ensure validation passes: `cue vet ./...`

See the [OPM Contributing Guide](https://github.com/open-platform-model/opm/blob/main/CONTRIBUTING.md) for details.

## Documentation

**In this repository**:

- [Architecture Documentation](docs/architecture/) - Deep technical architecture
  - [Element System Architecture](docs/architecture/element-system.md) - Element type system, #ElementBase pattern, validation
  - [Component Model](docs/architecture/component-model.md) - *(future)* Component architecture
  - [Module Lifecycle](docs/architecture/module-lifecycle.md) - *(future)* Three-layer model
- [Element Documentation](docs/elements.md) - Navigation hub pointing to element docs
- [TODO](TODO.md) - Planned features and research areas
- [CLAUDE.md](CLAUDE.md) - AI assistant context (useful for understanding the codebase)

**Element documentation** (in [elements repository](https://github.com/open-platform-model/elements)):

- [Element Catalog](https://github.com/open-platform-model/elements/docs/element-catalog.md) - Complete element reference
- [Element Patterns](https://github.com/open-platform-model/elements/docs/element-patterns.md) - Usage patterns and best practices
- [Creating Elements](https://github.com/open-platform-model/elements/docs/creating-elements.md) - Guide for adding new elements

**Project-wide documentation**:

- [OPM Main Documentation](https://github.com/open-platform-model/opm/docs) - User-facing docs
- [Architecture Overview](https://github.com/open-platform-model/opm/docs/architecture.md) - High-level architecture
- [Getting Started Guide](https://github.com/open-platform-model/opm/docs/quickstart/) - Tutorials

## CUE Module Information

- **Module**: `github.com/open-platform-model/core@v1`
- **CUE Version**: v0.14.0
- **Source Kind**: self (no external dependencies)

## Known Issues & Gotchas

### CUE Performance

**Issue**: When CUE evaluates large datasets with unresolved values (bottoms `_|_`), evaluation slows significantly.

**Solution**: Run `cue export` to find and fix unresolved values.

```bash
# Find bottoms
cue export ./... --out json 2>&1 | grep "cannot"
```

### Element Registration

**Issue**: Elements not registered in `elements/elements.cue` won't be accessible.

**Solution**: Always add new elements to the `#CoreElementRegistry` in `elements/elements.cue`.

### Validation Warnings

**Issue**: Some transformers in proposals reference undefined types (expected for proposal stage).

**Solution**: Ignore warnings from `proposals/` directory. They're experimental.

## License

Apache License 2.0 - See [LICENSE](../LICENSE) for details.

---

**Need Help?**

- 💬 [GitHub Discussions](https://github.com/open-platform-model/opm/discussions)
- 🐛 [Issue Tracker](https://github.com/open-platform-model/core/issues)
- 📖 [Full Documentation](https://github.com/open-platform-model/opm/docs)
