# Developer Flow Examples

This directory demonstrates the **developer workflow** for creating and testing ModuleDefinitions locally before submitting them to a platform team.

## Developer Workflow Overview

```text
Developer Creates         Developer Tests Locally       Platform Team Reviews
ModuleDefinition    →     with Mock Transformers   →    and Adds to Catalog
     ↓                           ↓                              ↓
 Components +           Attach transformers         Pre-bake in catalog
 Value Schema           & renderer for testing      for end-users
```

## Philosophy

Developers should be able to:

1. **Create** `ModuleDefinition` with components and value schemas
2. **Test locally** by attaching mock transformers and renderers
3. **Submit** the definition to platform teams for catalog inclusion

The developer doesn't need to know platform-specific details - they just define the application structure.

## Example: Blog Application

### 1. Developer Creates ModuleDefinition

```cue
blogAppDefinition: opm.#ModuleDefinition & {
    #metadata: {
        name: "blog-app"
        version: "1.0.0"
    }

    components: {
        frontend: {
            elements.#StatelessWorkload
            statelessWorkload: {
                container: {
                    image: values.frontend.image
                    ports: { http: { targetPort: 3000 } }
                }
            }
        }

        database: {
            elements.#SimpleDatabase
            simpleDatabase: {
                engine: "postgres"
                version: "15"
                persistence: {
                    size: values.database.storageSize
                }
            }
        }
    }

    values: {
        frontend: { image!: string }
        database: { storageSize!: string }
        environment!: string
    }
}
```

### 2. Developer Tests Locally

```cue
blogAppLocal: opm.#Module & {
    moduleDefinition: blogAppDefinition & {
        // Attach mock transformers for testing
        transformers: {
            "apps/v1.Deployment": _mockDeploymentTransformer
            "v1.PersistentVolumeClaim": _mockPVCTransformer
        }
        renderer: opm.#KubernetesListRenderer
    }

    // Provide test values
    values: {
        frontend: { image: "blog-frontend:dev" }
        database: { storageSize: "5Gi" }
        environment: "development"
    }
}
```

### 3. Platform Team Adds to Catalog

After review, the platform team adds it to their catalog:

```cue
moduleDefinitions: {
    "blog-app": blogAppDefinition & {
        // Platform team attaches production transformers
        transformers: { ... }
        renderer: renderers["kubernetes-list"]
    }
}
```

## Available Commands

### List Available Modules

```bash
cue cmd list
```

**Output:**

```text
Developer Flow - Local Testing Modules:

Available modules:
  - blog-app: Simple blog application with frontend and database

Usage:
  cue cmd test -t module=<name>     # Test module definition and show output
  cue cmd validate -t module=<name> # Validate module structure
  cue cmd render -t module=<name>   # Render module output
  cue cmd show -t module=<name>     # Show rendered output
```

### Test a Module

```bash
cue cmd test -t module=blog-app
```

Tests the module with mock transformers and shows the generated output structure.

### Validate Module Definition

```bash
cue cmd validate -t module=blog-app
```

Validates the module definition structure, components, and value schema.

### Render Module Output

```bash
cue cmd render -t module=blog-app -t outdir=./output
```

Renders the module using the attached renderer and mock transformers. Shows availability of output formats.

### Show Rendered Output

```bash
cue cmd show -t module=blog-app
```

Shows the complete rendered output in YAML format, including all generated resources.

## File Structure

```text
developer-flow/
├── README.md           # This file
├── blog_app.cue        # Example blog application
└── developer_tool.cue  # Developer testing tool
```

## Key Concepts

### ModuleDefinition (Developer Creates)

- **Purpose**: Application template/blueprint
- **Contains**: Components, value schemas (constraints only)
- **Does NOT contain**: Concrete values, platform-specific transformers
- **Portable**: Can be deployed to any platform with appropriate transformers

### Local Testing (Developer Tests)

- **Purpose**: Validate structure before submitting
- **Uses**: Mock/simplified transformers
- **Provides**: Test values to ensure schema works
- **Output**: Validates component structure and rendering

### Catalog Submission (Platform Team)

- **Review**: Platform team reviews the definition
- **Add Transformers**: Attach production-grade transformers
- **Register**: Add to catalog for end-users
- **Maintain**: Platform team owns transformer updates

## Example: Blog App

The `blog_app.cue` file demonstrates a simple blog application with:

- **Frontend**: Stateless web application
  - Configurable image
  - HTTP port 3000
  - Environment variables

- **Database**: PostgreSQL database
  - Simple database element
  - Configurable storage size
  - Persistence enabled

### Value Schema

```cue
values: {
    frontend: {
        image!: string          // Required: Docker image
    }
    database: {
        storageSize!: string    // Required: Storage size (e.g., "5Gi")
    }
    environment!: string        // Required: Environment name
}
```

## Mock Transformers

The example includes simplified mock transformers for local testing:

- `_mockDeploymentTransformer`: Converts stateless workloads to Kubernetes Deployments
- `_mockPVCTransformer`: Converts volumes to PersistentVolumeClaims

These are **not production-ready** - they're simplified for testing purposes. The platform team will provide production transformers in the catalog.

## Next Steps for Developers

1. **Create your ModuleDefinition** following the blog_app.cue pattern
2. **Add mock transformers** for local testing
3. **Test locally** using `cue cmd test`
4. **Validate** using `cue cmd validate`
5. **Submit** to platform team for catalog inclusion

## Differences from Platform Flow

| Aspect | Developer Flow | Platform Flow |
|--------|----------------|---------------|
| Who | Application developers | Platform teams & end-users |
| Creates | ModuleDefinition | Catalog + Deployments |
| Transformers | Mock/local testing | Production-grade |
| Values | Test values | Environment-specific values |
| Purpose | Development & validation | Production deployment |

## Learn More

- Platform Flow: `../platform-flow/README.md`
- Core Schema: `../../module.cue`
- Elements: `../../elements/core/`
