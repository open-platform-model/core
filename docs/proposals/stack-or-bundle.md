# OPM Design Document: Stack - Multi-Module Composition

2025/01/18

**Status:** Incoherent Rambling  
**Lifecycle:** Ideation  
**Authors:** emil-jacero@  
**Tracking Issue:** open-platform-model/opm#TBD  
**Related Roadmap Items:** Module dependencies, Platform catalog  
**Reviewers:** TBD  
**Discussion:** TBD  

> **Note**: This proposal is in early ideation phase.

## Objective

Enable composition of multiple OPM modules into deployable stacks, providing a way to bundle related modules that work together while maintaining OPM's three-layer separation of concerns.

### Names

- stack - Similar to devX. Maybe more reasonable for developers
- bundle - Similar to Timoni. Fits better with Modules

## Background

### Current State

Currently, OPM handles individual modules well, but there's no mechanism to:

- Bundle multiple related modules together
- Deploy sets of modules as a unit
- Share configuration across module groups
- Define module deployment ordering

### Problem Statement

Organizations need to deploy groups of modules that work together (e.g., application + database + cache + monitoring). Without a composition mechanism, users must manually deploy each module and manage their relationships.

### Goals

- [ ] Enable multi-module composition
- [ ] Maintain three-layer separation (Definition → Curated → Release)
- [ ] Support deployment ordering through list order
- [ ] Allow shared configuration across modules
- [ ] Enable anyone to create stacks (developers, platform teams, end users)

## Proposal

### Stack Lifecycle

Following OPM's proven pattern:

```shell
StackDefinition → Stack → StackRelease
(Developer)       (Platform)  (End User)
```

### Core Types

```cue
// 1. Developer-owned blueprint
#StackDefinition: {
    #apiVersion: "core.opm.dev/v0alpha1"
    #kind: "StackDefinition"
    #metadata: {
        name: string
        version: string
        description?: string
        labels?: {...}
    }
    
    // Modules in this stack (order determines deployment sequence)
    modules: [...#StackModule]
    
    // Shared values for all modules
    globalValues?: {...}
}

#StackModule: {
    name: string  // Instance name
    module: string  // Reference to ModuleDefinition
    version: string
    
    // Module-specific values
    values?: {...}
    
    // Dependencies on other modules in stack
    dependsOn?: [...string]  // Names of other modules
}

// 2. Platform-curated stack
#Stack: {
    #apiVersion: "core.opm.dev/v0alpha1"
    #kind: "Stack"
    #metadata: {
        name: string
        version?: string
        labels?: {...}
    }
    
    // Reference to StackDefinition
    #stackDefinition: #StackDefinition
    
    // Platform can add modules (but not remove)
    modules?: [...#StackModule]
    
    // Platform can add scopes for governance
    scopes?: [Id=string]: #PlatformScope & {
        #metadata: #id: Id
        appliesTo: [...string]  // Module names
    }
    
    // Platform can override defaults
    globalValues?: #stackDefinition.globalValues & {...}
}

// 3. End-user deployment
#StackRelease: {
    #apiVersion: "core.opm.dev/v0alpha1"
    #kind: "StackRelease"
    #metadata: {
        name: string
        namespace?: string | *"default"
        labels?: {...}
    }
    
    // Reference to Stack from catalog
    #stack: #Stack
    
    // User overrides
    globalValues?: {...}
    
    // Module-specific overrides
    moduleValues?: [moduleName=string]: {...}
    
    // Target environment
    targetEnvironment?: string
}
```

## Examples

### Developer Creates Stack

```cue
// E-commerce platform stack
ecommerce: #StackDefinition & {
    #metadata: {
        name: "ecommerce-platform"
        version: "2.0.0"
        description: "Complete e-commerce solution"
    }
    
    // Modules listed in deployment order
    modules: [
        {
            name: "database"
            module: "postgresql"
            version: "15.0.0"
        },
        {
            name: "cache"
            module: "redis"
            version: "7.0.0"
        },
        {
            name: "api"
            module: "ecommerce/api"
            version: "2.0.0"
            dependsOn: ["database", "cache"]
        },
        {
            name: "frontend"
            module: "ecommerce/frontend"
            version: "2.0.0"
            dependsOn: ["api"]
        }
    ]
    
    globalValues: {
        environment: "production"
        domain: "shop.example.com"
    }
}
```

### Platform Team Curates

```cue
// Platform adds governance
ecommercePlatform: #Stack & {
    #metadata: {
        name: "ecommerce-platform"
        version: "2.0.0-platform.1"
    }
    
    #stackDefinition: ecommerce
    
    // Platform adds monitoring at the end (deployed last)
    modules: #stackDefinition.modules + [
        {
            name: "monitoring"
            module: "platform/monitoring"
            version: "1.0.0"
        }
    ]
    
    // Add platform policies
    scopes: {
        "security": #PlatformScope & {
            #PodSecurity
            appliesTo: ["*"]  // All modules
            podSecurity: {
                runAsNonRoot: true
            }
        }
        
        "resource-limits": #PlatformScope & {
            #ResourceLimit
            appliesTo: ["frontend", "api"]
            resourceLimit: {
                maxCPU: "2"
                maxMemory: "4Gi"
            }
        }
    }
    
    globalValues: ecommerce.globalValues & {
        platform: {
            monitoring: true
            backup: true
        }
    }
}
```

### End User Deploys

```cue
// User deploys stack instance
myShop: #StackRelease & {
    #metadata: {
        name: "my-shop"
        namespace: "production"
    }
    
    #stack: ecommercePlatform
    
    globalValues: {
        domain: "myshop.com"
        environment: "production"
    }
    
    moduleValues: {
        database: {
            size: "100Gi"
            replicas: 3
        }
        frontend: {
            replicas: 5
        }
    }
    
    targetEnvironment: "aws-production"
}
```

## Stack Composition Patterns

### Application Stack

```cue
webApp: #StackDefinition & {
    modules: [
        {name: "app", module: "myapp", version: "1.0.0"},
        {name: "db", module: "postgresql", version: "15.0.0"},
        {name: "cache", module: "redis", version: "7.0.0"}
    ]
}
```

### Platform Stack (OPM Bootstrap)

```cue
opmPlatform: #StackDefinition & {
    modules: [
        // Deploy in order: CNPG first, then operator, then catalog
        {name: "cnpg", module: "cnpg/operator", version: "1.22.0"},
        {name: "opm-operator", module: "opm/operator", version: "1.0.0"},
        {name: "catalog", module: "opm/catalog", version: "1.0.0"}
    ]
}
```

### Microservices Stack

```cue
microservices: #StackDefinition & {
    modules: [
        {name: "gateway", module: "api-gateway", version: "1.0.0"},
        {name: "auth", module: "auth-service", version: "1.0.0"},
        {name: "users", module: "user-service", version: "1.0.0"},
        {name: "orders", module: "order-service", version: "1.0.0"},
        {name: "messagebus", module: "rabbitmq", version: "3.12.0"}
    ]
}
```

## Deployment Ordering

Module deployment order is determined by:

1. **List Order**: Modules are deployed in the order they appear in the `modules` list
2. **Dependencies**: The `dependsOn` field ensures prerequisites are met
3. **Platform Validation**: Platform providers validate dependency order before deployment

## Value Resolution

Values cascade through the stack hierarchy:

```shell
StackDefinition.globalValues 
  → Stack.globalValues 
    → StackRelease.globalValues 
      → StackRelease.moduleValues[module]
        → Module receives final values
```

## Implementation Approach

### Phase 1: StackDefinition

- Define core types
- Support module composition
- Implement dependency ordering

### Phase 2: Stack Curation

- Platform policy application
- Module addition capability
- Value override mechanism

### Phase 3: StackRelease

- Deployment orchestration
- Value resolution
- Environment targeting

### Phase 4: Advanced Features

- Cross-module references
- Conditional modules
- Stack nesting

## Trade-offs

### Advantages

- Simplified multi-module deployment
- Reusable solution bundles
- Clear dependency management
- Consistent with OPM patterns
- Flexible ownership (anyone can create)

### Disadvantages

- Additional abstraction layer
- Complex value cascading
- Testing multi-module interactions
- Version coordination challenges

## Future Enhancements

- Stack marketplace/registry
- Nested stacks (stacks of stacks)
- Dynamic module inclusion
- Stack templates
- GitOps integration

## Conclusion

Stacks provide the missing piece for multi-module composition in OPM. By following the proven three-layer pattern (StackDefinition → Stack → StackRelease), we enable developers to bundle solutions, platform teams to apply governance, and end users to deploy complete systems with a single action.

This proposal maintains OPM's core principles while solving real-world needs for deploying groups of related modules together.
